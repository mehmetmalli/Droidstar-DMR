#!/bin/bash
# Re-sign the existing DroidStar build with a valid provisioning profile and install it
# on the connected iPhone - no recompile.
#
# Use this when the provisioning profile is about to expire or has expired but the code
# has not changed. It reuses Droidstar-build-ios/Debug-iphoneos/DroidStar.app.
#
# Usage:
#   ./renew_and_install.sh                                    # reuse newest local profile; renew via Xcode if none is valid
#   ./renew_and_install.sh ~/Downloads/app.mobileprovision    # use a specific app profile (extension detected automatically)
#   ./renew_and_install.sh app.mobileprovision appex.mobileprovision
set -e
cd "$(dirname "$0")"
REPO="$PWD"
BUILD_DIR="$REPO/../Droidstar-build-ios"
DEVICE=00008150-001C6D111EF0401C
TEAM=9U8Z3687WL
BUNDLE_ID=com.mehmetmalli.droidstar
APP="$BUILD_DIR/Debug-iphoneos/DroidStar.app"
APPEX="$APP/PlugIns/DroidStarLiveActivity.appex"
APP_ID="$TEAM.$BUNDLE_ID"
APPEX_ID="$TEAM.$BUNDLE_ID.LiveActivity"
PROFILE_DIRS=("$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" "$HOME/Library/MobileDevice/Provisioning Profiles")
MIN_REMAINING_DAYS=3

[ -d "$APP" ] || { echo "error: no build at $APP - run build_and_install.sh first"; exit 1; }
[ -d "$APPEX" ] || { echo "error: Live Activity extension missing at $APPEX - run build_and_install.sh first"; exit 1; }

profile_expiry() {  # $1 = profile path, prints RFC3339 date
  security cms -D -i "$1" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null
}
profile_expiry_epoch() {
  local d
  d=$(profile_expiry "$1") || return 1
  date -j -f "%Y-%m-%dT%H:%M:%SZ" "$d" +%s 2>/dev/null
}
profile_app_id() {
  security cms -D -i "$1" 2>/dev/null | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null
}
find_profile() {  # $1 = application-identifier, $2 = min expiry epoch -> newest matching profile
  local best="" best_exp=0 p appid exp dir
  shopt -s nullglob
  for dir in "${PROFILE_DIRS[@]}"; do
    for p in "$dir"/*.mobileprovision; do
      appid=$(profile_app_id "$p") || continue
      [ "$appid" = "$1" ] || continue
      exp=$(profile_expiry_epoch "$p") || continue
      [ "$exp" -ge "$2" ] || continue
      if [ "$exp" -gt "$best_exp" ]; then best="$p"; best_exp=$exp; fi
    done
  done
  echo "$best"
}
renew_via_xcode() {
  echo "No valid local profile found - asking Xcode to renew (incremental build, may take a minute)..."
  ( cd "$BUILD_DIR" && xcodebuild -project DroidStar.xcodeproj -scheme DroidStar -configuration Debug \
      -destination "id=$DEVICE" -allowProvisioningUpdates \
      DEVELOPMENT_TEAM=$TEAM CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" \
      IPHONEOS_DEPLOYMENT_TARGET=17.0 SWIFT_VERSION=5.0 \
      'OTHER_CPLUSPLUSFLAGS=$(inherited) -include arm_acle.h' \
      build > renew-build.log 2>&1 ) || { grep -E "error" "$BUILD_DIR/renew-build.log" | head -20; exit 1; }
  ( cd "$BUILD_DIR" && xcodebuild -project "$REPO/ios/LiveActivityExtension/DroidStarLiveActivity.xcodeproj" \
      -target DroidStarLiveActivity -configuration Debug -sdk iphoneos -allowProvisioningUpdates \
      DEVELOPMENT_TEAM=$TEAM PRODUCT_BUNDLE_IDENTIFIER=$APPEX_ID \
      SYMROOT="$PWD/liveactivity-build" build > renew-build-ext.log 2>&1 ) || { grep -E "error" "$BUILD_DIR/renew-build-ext.log" | head -20; exit 1; }
}

MIN_EXP=$(( $(date +%s) + MIN_REMAINING_DAYS * 86400 ))
APP_PROFILE="$1"
APPEX_PROFILE="$2"

if [ -z "$APP_PROFILE" ] || [ -z "$APPEX_PROFILE" ]; then
  [ -z "$APP_PROFILE" ] && APP_PROFILE=$(find_profile "$APP_ID" "$MIN_EXP")
  [ -z "$APPEX_PROFILE" ] && APPEX_PROFILE=$(find_profile "$APPEX_ID" "$MIN_EXP")
  if [ -z "$APP_PROFILE" ] || [ -z "$APPEX_PROFILE" ]; then
    renew_via_xcode
    [ -z "$APP_PROFILE" ] && APP_PROFILE=$(find_profile "$APP_ID" "$MIN_EXP")
    [ -z "$APPEX_PROFILE" ] && APPEX_PROFILE=$(find_profile "$APPEX_ID" "$MIN_EXP")
  fi
fi

[ -n "$APP_PROFILE" ] && [ -f "$APP_PROFILE" ] || { echo "error: no valid app profile. Download one from developer.apple.com and pass it as an argument."; exit 1; }
[ -n "$APPEX_PROFILE" ] && [ -f "$APPEX_PROFILE" ] || { echo "error: no valid Live Activity profile. Pass it as the second argument."; exit 1; }

echo "App profile:    $APP_PROFILE (expires $(profile_expiry "$APP_PROFILE"))"
echo "Appex profile:  $APPEX_PROFILE (expires $(profile_expiry "$APPEX_PROFILE"))"

IDENTITY=$(codesign -dvv "$APP" 2>&1 | sed -n 's/^Authority=\(Apple Development: .*\)$/\1/p' | head -1)
[ -n "$IDENTITY" ] || { echo "error: no Apple Development identity found:"; security find-identity -v -p codesigning; exit 1; }
echo "Identity:       $IDENTITY"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
security cms -D -i "$APP_PROFILE" | plutil -extract Entitlements xml1 -o "$WORK/app.entitlements" -
security cms -D -i "$APPEX_PROFILE" | plutil -extract Entitlements xml1 -o "$WORK/appex.entitlements" -

# Sign the extension first (keeping its own bundle id entitlements), then the app, so both
# resource seals stay valid. Always embed the profile before signing it.
cp "$APPEX_PROFILE" "$APPEX/embedded.mobileprovision"
codesign --force --sign "$IDENTITY" --entitlements "$WORK/appex.entitlements" --generate-entitlement-der "$APPEX"
cp "$APP_PROFILE" "$APP/embedded.mobileprovision"
codesign --force --sign "$IDENTITY" --entitlements "$WORK/app.entitlements" --generate-entitlement-der "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

xcrun devicectl device install app --device "$DEVICE" "$APP"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" || {
  # A locked device refuses to launch apps; the install itself already succeeded.
  echo "App installed, but launch was refused (the iPhone is probably locked). Unlock it and open DroidStar manually."
}

#!/bin/bash
# Rebuild DroidStar (with the Live Activity widget extension) and install it on the connected iPhone.
# Backup of the pre-Live-Activity script and app: ./backup-working-audio/
set -e
cd "$(dirname "$0")"
REPO="$PWD"
BUILD_DIR="$REPO/../Droidstar-build-ios"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
DEVICE=00008150-001C6D111EF0401C
TEAM=9U8Z3687WL
APP=Debug-iphoneos/DroidStar.app

# 1. Generate the Xcode project and fix it up (Swift version, Swift files into Compile Sources)
~/Qt/6.11.3/ios/bin/qmake $REPO/DroidStar.pro -after "QMAKE_TARGET_BUNDLE_PREFIX=com.mehmetmalli" "QTPLUGIN.multimedia=darwinmediaplugin" "QMAKE_IOS_DEPLOYMENT_TARGET=17.0" CONFIG+=sdk_no_version_check
$REPO/fix_swift_version.sh DroidStar.xcodeproj
python3 $REPO/scripts/ios_add_swift_sources.py DroidStar.xcodeproj

# 2. Build the app
xcodebuild -project DroidStar.xcodeproj -scheme DroidStar -configuration Debug \
  -destination "id=$DEVICE" -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=$TEAM CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" \
  IPHONEOS_DEPLOYMENT_TARGET=17.0 SWIFT_VERSION=5.0 'OTHER_CPLUSPLUSFLAGS=$(inherited) -include arm_acle.h' \
  build > build.log 2>&1 || { grep -E "error|Undefined" build.log | head -20; exit 1; }

# 3. Build the Live Activity widget extension (separate project, untouched by qmake)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" $APP/Info.plist)
xcodebuild -project $REPO/ios/LiveActivityExtension/DroidStarLiveActivity.xcodeproj \
  -target DroidStarLiveActivity -configuration Debug -sdk iphoneos -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=$TEAM PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE_ID.LiveActivity \
  MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" $APP/Info.plist) \
  CURRENT_PROJECT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" $APP/Info.plist) \
  SYMROOT="$PWD/liveactivity-build" build > build-ext.log 2>&1 || { grep -E "error" build-ext.log | head -20; exit 1; }

# 4. Embed the extension and re-sign the app with its original identity and entitlements
mkdir -p $APP/PlugIns
rm -rf $APP/PlugIns/DroidStarLiveActivity.appex
cp -R liveactivity-build/Debug-iphoneos/DroidStarLiveActivity.appex $APP/PlugIns/
IDENTITY=$(codesign -dvv $APP 2>&1 | sed -n 's/^Authority=\(Apple Development: .*\)$/\1/p' | head -1)
# xcodebuild can embed the appex provisioning profile after sealing it, which breaks
# the appex signature and makes iOS refuse to launch the app. Re-sign it (keeping its
# own entitlements) before signing the parent app.
codesign --force --sign "$IDENTITY" --preserve-metadata=entitlements,flags $APP/PlugIns/DroidStarLiveActivity.appex
codesign -d --entitlements entitlements.plist --xml $APP
codesign --force --sign "$IDENTITY" --entitlements entitlements.plist --generate-entitlement-der $APP

# 5. Install and launch
xcrun devicectl device install app --device "$DEVICE" $APP
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"

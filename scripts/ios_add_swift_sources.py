#!/usr/bin/env python3
"""Add the .swift files of a qmake-generated Xcode project to its Compile Sources phase.

qmake (Qt 6.11) creates PBXBuildFile entries for SOURCES ending in .swift but never puts
them in the target's PBXSourcesBuildPhase, so the Swift code (LiveActivityManager) is not
compiled into the app. Run this after every qmake run. It is idempotent.

Usage: ios_add_swift_sources.py path/to/DroidStar.xcodeproj
"""
import re
import sys

pbxproj = sys.argv[1].rstrip("/") + "/project.pbxproj"
text = open(pbxproj).read()

# PBXFileReference ids of .swift files
swift_refs = re.findall(
    r'(\w{24}) = \{\s*isa = PBXFileReference;\s*path = "[^"]+\.swift";', text)
# PBXBuildFile ids pointing at those references
build_files = []
for ref in swift_refs:
    m = re.search(r'(\w{24}) = \{\s*fileRef = "%s";\s*isa = PBXBuildFile;' % ref, text)
    if m:
        build_files.append(m.group(1))

phase = re.search(r'files = \(([^)]*)\);\s*isa = PBXSourcesBuildPhase;', text)
if not phase:
    sys.exit("error: no PBXSourcesBuildPhase found in " + pbxproj)

missing = [b for b in build_files if b not in phase.group(1)]
if missing:
    files = phase.group(1).rstrip()
    files += "".join(',\n\t\t\t\t"%s"' % b for b in missing)
    text = text[:phase.start(1)] + files + text[phase.end(1):]
    open(pbxproj, "w").write(text)

print("Swift sources in Compile Sources: %d added, %d total" % (len(missing), len(build_files)))

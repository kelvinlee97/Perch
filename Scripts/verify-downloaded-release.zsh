#!/bin/zsh
set -euo pipefail

dmg_path=${1:?Usage: zsh Scripts/verify-downloaded-release.zsh /path/to/Perch.dmg}
dmg_path=${dmg_path:A}
expected_bundle_id=${PERCH_BUNDLE_ID:?Set PERCH_BUNDLE_ID to the expected bundle identifier.}
expected_version=${PERCH_VERSION:?Set PERCH_VERSION to the expected release version.}
expected_build_number=${PERCH_BUILD_NUMBER:?Set PERCH_BUILD_NUMBER to the expected build number.}
expected_team_id=${PERCH_TEAM_ID:?Set PERCH_TEAM_ID to the expected Apple Developer Team ID.}

if [[ ! -f "$dmg_path" ]]; then
    print -u2 "Downloaded DMG not found: $dmg_path"
    exit 1
fi

quarantine_value=$(xattr -p com.apple.quarantine "$dmg_path" 2>/dev/null || true)
if [[ -z "$quarantine_value" ]]; then
    print -u2 "The DMG has no quarantine metadata. Download it with a web browser before running this check."
    exit 1
fi

codesign --verify --verbose=2 "$dmg_path"
xcrun stapler validate "$dmg_path"

verification_dir=$(mktemp -d /tmp/perch-download-verification.XXXXXX)
mount_dir="$verification_dir/mount"
is_mounted=false

cleanup() {
    if [[ "$is_mounted" == true ]]; then
        hdiutil detach "$mount_dir" -quiet || true
    fi
    rm -rf "$verification_dir"
}
trap cleanup EXIT

install -d "$mount_dir"
hdiutil attach \
    "$dmg_path" \
    -nobrowse \
    -readonly \
    -mountpoint "$mount_dir" \
    -quiet
is_mounted=true

app_path="$mount_dir/Perch.app"
if [[ ! -d "$app_path" || ! -L "$mount_dir/Applications" ]]; then
    print -u2 "The DMG must contain Perch.app and an Applications shortcut."
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$app_path"
signature_details=$(codesign -dv --verbose=4 "$app_path" 2>&1)
if [[ "$signature_details" != *"Authority=Developer ID Application:"* ]]; then
    print -u2 "Perch.app is not signed with a Developer ID Application certificate."
    exit 1
fi
if [[ "$signature_details" != *"runtime"* || "$signature_details" != *"Timestamp="* ]]; then
    print -u2 "Perch.app is missing hardened runtime or a secure timestamp."
    exit 1
fi
if ! print -r -- "$signature_details" | grep -Fqx "TeamIdentifier=$expected_team_id"; then
    print -u2 "Perch.app is not signed by the expected Apple Developer team."
    exit 1
fi

spctl --assess --type execute --verbose=4 "$app_path"

bundle_id=$(plutil -extract CFBundleIdentifier raw -o - "$app_path/Contents/Info.plist")
version=$(plutil -extract CFBundleShortVersionString raw -o - "$app_path/Contents/Info.plist")
build_number=$(plutil -extract CFBundleVersion raw -o - "$app_path/Contents/Info.plist")
if [[ "$bundle_id" != "$expected_bundle_id" ]]; then
    print -u2 "Unexpected bundle ID: $bundle_id"
    exit 1
fi
if [[ "$version" != "$expected_version" || "$build_number" != "$expected_build_number" ]]; then
    print -u2 "Unexpected version: $version ($build_number)"
    exit 1
fi
architectures=$(lipo -archs "$app_path/Contents/MacOS/Perch")
if [[ " $architectures " != *" arm64 "* || " $architectures " != *" x86_64 "* ]]; then
    print -u2 "The downloaded release must contain both arm64 and x86_64."
    exit 1
fi

hdiutil detach "$mount_dir" -quiet
is_mounted=false

print "Verified browser-downloaded Perch release"
print "Bundle ID: $bundle_id"
print "Version: $version ($build_number)"
print "Architectures: $architectures"

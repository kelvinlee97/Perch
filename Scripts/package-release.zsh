#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
bundle_id=${PERCH_BUNDLE_ID:?Set PERCH_BUNDLE_ID to an identifier you control.}
version=${PERCH_VERSION:-0.1.0}
build_number=${PERCH_BUILD_NUMBER:-1}
code_sign_identity=${CODE_SIGN_IDENTITY:?Set CODE_SIGN_IDENTITY to your Developer ID Application identity.}
notary_profile=${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile.}
output_dir=${OUTPUT_DIR:-"$root_dir/release"}
app_path="$output_dir/Perch.app"
release_path="$output_dir/Perch.dmg"

if [[ "$code_sign_identity" == "-" ]]; then
    print -u2 "CODE_SIGN_IDENTITY must be a Developer ID Application identity."
    exit 1
fi

developer_dir=$(xcode-select -p)
if [[ "$developer_dir" == */CommandLineTools ]]; then
    print -u2 "Select full Xcode before creating a public release."
    exit 1
fi

available_identities=$(security find-identity -v -p codesigning)
if [[ "$available_identities" != *"$code_sign_identity"* ]]; then
    print -u2 "The requested Developer ID Application identity is not available."
    exit 1
fi

PERCH_BUNDLE_ID="$bundle_id" \
PERCH_VERSION="$version" \
PERCH_BUILD_NUMBER="$build_number" \
PERCH_ARCHITECTURES=arm64,x86_64 \
CODE_SIGN_IDENTITY="$code_sign_identity" \
OUTPUT_DIR="$output_dir" \
"$root_dir/Scripts/package-app.zsh"

codesign --verify --deep --strict --verbose=2 "$app_path"
architectures=$(lipo -archs "$app_path/Contents/MacOS/Perch")
if [[ " $architectures " != *" arm64 "* || " $architectures " != *" x86_64 "* ]]; then
    print -u2 "The public release must contain both arm64 and x86_64."
    exit 1
fi
signature_details=$(codesign -dv --verbose=4 "$app_path" 2>&1)
if [[ "$signature_details" != *"Authority=Developer ID Application:"* ]]; then
    print -u2 "The app is not signed with a Developer ID Application certificate."
    exit 1
fi
if [[ "$signature_details" != *"runtime"* || "$signature_details" != *"Timestamp="* ]]; then
    print -u2 "The Developer ID signature is missing hardened runtime or a secure timestamp."
    exit 1
fi

install -d "$output_dir"
staging_dir=$(mktemp -d "$output_dir/.PerchRelease.XXXXXX")
source_dir="$staging_dir/source"
staging_dmg="$staging_dir/Perch.dmg"
backup_dmg="$staging_dir/previous.dmg"
mount_dir="$staging_dir/mount"
notary_result="$staging_dir/notary-result.plist"
is_mounted=false

cleanup() {
    if [[ "$is_mounted" == true ]]; then
        hdiutil detach "$mount_dir" -quiet || true
    fi
    if [[ -e "$backup_dmg" && ! -e "$release_path" ]]; then
        mv "$backup_dmg" "$release_path"
    fi
    rm -rf "$staging_dir"
}
trap cleanup EXIT

install -d "$source_dir" "$mount_dir"
ditto "$app_path" "$source_dir/Perch.app"
ln -s /Applications "$source_dir/Applications"

hdiutil create \
    -volname "Perch" \
    -srcfolder "$source_dir" \
    -format UDZO \
    -ov \
    "$staging_dmg"

codesign \
    --force \
    --timestamp \
    --identifier "$bundle_id.dmg" \
    --sign "$code_sign_identity" \
    "$staging_dmg"
codesign --verify --verbose=2 "$staging_dmg"

set +e
xcrun notarytool submit \
    "$staging_dmg" \
    --keychain-profile "$notary_profile" \
    --wait \
    --output-format plist \
    > "$notary_result"
notary_exit_status=$?
set -e

submission_id=$(plutil -extract id raw -o - "$notary_result" 2>/dev/null || true)
notary_status=$(plutil -extract status raw -o - "$notary_result" 2>/dev/null || true)
if [[ -n "$submission_id" ]]; then
    xcrun notarytool log "$submission_id" --keychain-profile "$notary_profile" || true
fi
if (( notary_exit_status != 0 )) || [[ "$notary_status" != "Accepted" ]]; then
    print -u2 "Notarization did not finish with Accepted status."
    exit 1
fi

xcrun stapler staple "$staging_dmg"
xcrun stapler validate "$staging_dmg"

hdiutil attach \
    "$staging_dmg" \
    -nobrowse \
    -readonly \
    -mountpoint "$mount_dir" \
    -quiet
is_mounted=true
codesign --verify --deep --strict --verbose=2 "$mount_dir/Perch.app"
spctl --assess --type execute --verbose=4 "$mount_dir/Perch.app"
hdiutil detach "$mount_dir" -quiet
is_mounted=false

if [[ -e "$release_path" ]]; then
    mv "$release_path" "$backup_dmg"
fi
if ! mv "$staging_dmg" "$release_path"; then
    [[ -e "$backup_dmg" ]] && mv "$backup_dmg" "$release_path"
    exit 1
fi

print "Created notarized release $release_path"

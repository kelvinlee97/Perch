#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
bundle_id=${PERCH_BUNDLE_ID:?Set PERCH_BUNDLE_ID to an identifier you control.}
version=${PERCH_VERSION:-0.1.0}
build_number=${PERCH_BUILD_NUMBER:-1}
build_dir=${BUILD_DIR:-"$root_dir/.build"}
output_dir=${OUTPUT_DIR:-"$root_dir/release"}
app_path="$output_dir/Perch.app"
code_sign_identity=${CODE_SIGN_IDENTITY:--}

swift build -c release --build-path "$build_dir"

install -d "$output_dir"
staging_dir=$(mktemp -d "$output_dir/.Perch.XXXXXX")
staging_app="$staging_dir/Perch.app"
backup_app="$staging_dir/previous.app"
cleanup() {
    if [[ -e "$backup_app" && ! -e "$app_path" ]]; then
        mv "$backup_app" "$app_path"
    fi
    rm -rf "$staging_dir"
}
trap cleanup EXIT

install -d "$staging_app/Contents/MacOS" "$staging_app/Contents/Resources"
install -m 755 "$build_dir/release/Perch" "$staging_app/Contents/MacOS/Perch"
install -m 644 "$root_dir/Sources/Perch/Assets/bird-companion.png" "$staging_app/Contents/Resources/bird-companion.png"
install -m 644 "$root_dir/App/Perch.icns" "$staging_app/Contents/Resources/Perch.icns"
cp "$root_dir/App/Info.plist" "$staging_app/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$bundle_id" "$staging_app/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$version" "$staging_app/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$build_number" "$staging_app/Contents/Info.plist"
plutil -lint "$staging_app/Contents/Info.plist" >/dev/null
codesign --force --sign "$code_sign_identity" "$staging_app"

if [[ -e "$app_path" ]]; then
    mv "$app_path" "$backup_app"
fi
if ! mv "$staging_app" "$app_path"; then
    [[ -e "$backup_app" ]] && mv "$backup_app" "$app_path"
    exit 1
fi

print "Created $app_path"

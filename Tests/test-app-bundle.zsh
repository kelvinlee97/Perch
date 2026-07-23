#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

PERCH_BUNDLE_ID="com.example.perch" \
BUILD_DIR="$temp_dir/build" \
OUTPUT_DIR="$temp_dir/release" \
"$root_dir/Scripts/package-app.zsh"

app_path="$temp_dir/release/Perch.app"

[[ -x "$app_path/Contents/MacOS/Perch" ]]
[[ "$(plutil -extract CFBundleIdentifier raw "$app_path/Contents/Info.plist")" == "com.example.perch" ]]
[[ "$(plutil -extract CFBundlePackageType raw "$app_path/Contents/Info.plist")" == "APPL" ]]
[[ "$(plutil -extract LSMultipleInstancesProhibited raw "$app_path/Contents/Info.plist")" == "true" ]]
plutil -lint "$app_path/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict "$app_path"

print "App bundle test passed."

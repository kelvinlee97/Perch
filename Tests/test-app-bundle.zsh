#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

BIRD_TODO_BUNDLE_ID="com.example.birdtodo" \
BUILD_DIR="$temp_dir/build" \
OUTPUT_DIR="$temp_dir/release" \
"$root_dir/Scripts/package-app.zsh"

app_path="$temp_dir/release/BirdTodo.app"

[[ -x "$app_path/Contents/MacOS/BirdTodo" ]]
[[ "$(plutil -extract CFBundleIdentifier raw "$app_path/Contents/Info.plist")" == "com.example.birdtodo" ]]
[[ "$(plutil -extract CFBundlePackageType raw "$app_path/Contents/Info.plist")" == "APPL" ]]
[[ "$(plutil -extract LSMultipleInstancesProhibited raw "$app_path/Contents/Info.plist")" == "true" ]]
plutil -lint "$app_path/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict "$app_path"

print "App bundle test passed."

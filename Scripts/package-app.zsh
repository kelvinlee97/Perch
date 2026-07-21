#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
bundle_id=${BIRD_TODO_BUNDLE_ID:?Set BIRD_TODO_BUNDLE_ID to an identifier you control.}
version=${BIRD_TODO_VERSION:-0.1.0}
build_number=${BIRD_TODO_BUILD_NUMBER:-1}
build_dir=${BUILD_DIR:-"$root_dir/.build"}
output_dir=${OUTPUT_DIR:-"$root_dir/release"}
app_path="$output_dir/BirdTodo.app"
code_sign_identity=${CODE_SIGN_IDENTITY:--}

if [[ -e "$app_path" ]]; then
    print -u2 "Refusing to overwrite $app_path"
    exit 1
fi

swift build -c release --build-path "$build_dir"

install -d "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
install -m 755 "$build_dir/release/BirdTodo" "$app_path/Contents/MacOS/BirdTodo"
install -m 644 "$root_dir/Sources/BirdTodo/Assets/bird-companion.png" "$app_path/Contents/Resources/bird-companion.png"
cp "$root_dir/App/Info.plist" "$app_path/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$bundle_id" "$app_path/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$version" "$app_path/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$build_number" "$app_path/Contents/Info.plist"
plutil -lint "$app_path/Contents/Info.plist" >/dev/null
codesign --force --sign "$code_sign_identity" "$app_path"

print "Created $app_path"

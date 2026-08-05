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
architecture_setting=${PERCH_ARCHITECTURES:-native}
typeset -a built_executables

if [[ "$architecture_setting" == "native" ]]; then
    swift build -c release --build-path "$build_dir"
    built_executables=("$build_dir/release/Perch")
else
    architectures=("${(@s:,:)architecture_setting}")
    for architecture in "${architectures[@]}"; do
        case "$architecture" in
            arm64|x86_64) ;;
            *)
                print -u2 "Unsupported architecture: $architecture"
                exit 1
                ;;
        esac
        architecture_build_dir="$build_dir/$architecture"
        target="$architecture-apple-macosx14.0"
        binary_dir=$(swift build \
            -c release \
            --triple "$target" \
            --build-path "$architecture_build_dir" \
            --show-bin-path)
        swift build \
            -c release \
            --triple "$target" \
            --build-path "$architecture_build_dir"
        built_executables+=("$binary_dir/Perch")
    done
fi

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
if (( ${#built_executables[@]} == 1 )); then
    install -m 755 "$built_executables[1]" "$staging_app/Contents/MacOS/Perch"
else
    lipo -create "${built_executables[@]}" -output "$staging_app/Contents/MacOS/Perch"
    chmod 755 "$staging_app/Contents/MacOS/Perch"
fi
install -m 644 "$root_dir/Sources/Perch/Assets/bird-companion.png" "$staging_app/Contents/Resources/bird-companion.png"
install -m 644 "$root_dir/App/Perch.icns" "$staging_app/Contents/Resources/Perch.icns"
cp "$root_dir/App/Info.plist" "$staging_app/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$bundle_id" "$staging_app/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$version" "$staging_app/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$build_number" "$staging_app/Contents/Info.plist"
plutil -lint "$staging_app/Contents/Info.plist" >/dev/null
if [[ "$code_sign_identity" == "-" ]]; then
    codesign --force --sign "$code_sign_identity" "$staging_app"
else
    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$code_sign_identity" \
        "$staging_app"
fi

if [[ -e "$app_path" ]]; then
    mv "$app_path" "$backup_app"
fi
if ! mv "$staging_app" "$app_path"; then
    [[ -e "$backup_app" ]] && mv "$backup_app" "$app_path"
    exit 1
fi

print "Created $app_path"

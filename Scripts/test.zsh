#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
developer_dir=$(xcode-select -p)
testing_framework="$developer_dir/Library/Developer/Frameworks/Testing.framework"
testing_interop="$developer_dir/Library/Developer/usr/lib/lib_TestingInterop.dylib"

cd "$root_dir"

if [[ "$developer_dir" == */CommandLineTools && -d "$testing_framework" && -f "$testing_interop" ]]; then
    test_bin_dir=$(swift build --show-bin-path)
    framework_link="$test_bin_dir/Testing.framework"
    interop_link="$test_bin_dir/lib_TestingInterop.dylib"

    cleanup() {
        [[ -L "$framework_link" ]] && rm "$framework_link"
        [[ -L "$interop_link" ]] && rm "$interop_link"
    }
    trap cleanup EXIT

    [[ -e "$framework_link" ]] || ln -s "$testing_framework" "$framework_link"
    [[ -e "$interop_link" ]] || ln -s "$testing_interop" "$interop_link"

    swift test \
        --disable-xctest \
        --enable-swift-testing \
        -Xswiftc -F \
        -Xswiftc "$developer_dir/Library/Developer/Frameworks" \
        -Xlinker "-F$developer_dir/Library/Developer/Frameworks"
else
    swift test
fi

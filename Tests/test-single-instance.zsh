#!/bin/zsh
set -euo pipefail

root_dir=${0:A:h:h}
temp_dir=$(mktemp -d)
first_pid=""
second_pid=""

cleanup() {
    [[ -n "$first_pid" ]] && kill "$first_pid" 2>/dev/null || true
    [[ -n "$second_pid" ]] && kill "$second_pid" 2>/dev/null || true
    rm -rf "$temp_dir"
}
trap cleanup EXIT

swift build --build-path "$temp_dir/build"
binary="$temp_dir/build/debug/Perch"

"$binary" &
first_pid=$!
sleep 1
kill -0 "$first_pid"

"$binary" &
second_pid=$!
sleep 1

if kill -0 "$second_pid" 2>/dev/null; then
    print -u2 "A second Perch instance is still running."
    exit 1
fi

wait "$second_pid"
print "Single-instance test passed."

#!/bin/bash
set -euo pipefail

source_dir="$(cd "$(dirname "$0")" && pwd)"
app_path="${1:-"$source_dir/dist/BarFold.app"}"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
staged_app="$build_dir/BarFold.app"

mkdir -p "$staged_app/Contents/MacOS"
cp "$source_dir/Info.plist" "$staged_app/Contents/Info.plist"
for arch in arm64 x86_64; do
    xcrun swiftc -O -warnings-as-errors -sdk "$sdk_path" -module-cache-path "$build_dir/module-cache" \
        -target "$arch-apple-macosx13.0" "$source_dir/main.swift" -o "$build_dir/BarFold-$arch"
done
xcrun lipo -create "$build_dir/BarFold-arm64" "$build_dir/BarFold-x86_64" \
    -output "$staged_app/Contents/MacOS/BarFold"
/usr/bin/codesign --force --sign - "$staged_app"
/usr/bin/ditto "$staged_app" "$app_path"
printf '%s\n' "$app_path"

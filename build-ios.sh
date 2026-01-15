#!/bin/bash

set -ex

rm -rf ./build
rm -rf ./out

cargo build
cargo run --bin uniffi-bindgen generate --library ./target/debug/libqueuefile.dylib --language swift --out-dir ./out

mv ./out/queuefileFFI.modulemap ./out/module.modulemap

cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target aarch64-apple-darwin

rm -rf ./build
mkdir -p ./build/Headers
cp ./out/queuefileFFI.h ./build/Headers/
cp ./out/module.modulemap ./build/Headers/

cp ./out/queuefile.swift ./Sources/QueueFileFFI/

xcodebuild -create-xcframework \
-library ./target/aarch64-apple-ios/release/libqueuefile.a -headers ./build/Headers \
-library ./target/aarch64-apple-ios-sim/release/libqueuefile.a -headers ./build/Headers \
-library ./target/aarch64-apple-darwin/release/libqueuefile.a -headers ./build/Headers \
-output ./build/libqueuefile-rs.xcframework

ditto -c -k --sequesterRsrc --keepParent ./build/libqueuefile-rs.xcframework ./build/libqueuefile-rs.xcframework.zip
checksum=$(swift package compute-checksum ./build/libqueuefile-rs.xcframework.zip)
version=$(cargo metadata --format-version 1 | jq -r --arg pkg_name "queue-file-swift" '.packages[] | select(.name==$pkg_name) .version')
sed -i "" -E "s/(let releaseTag = \")[^\"]*(\")/\1$version\2/g" ./Package.swift
sed -i "" -E "s/(let releaseChecksum = \")[^\"]*(\")/\1$checksum\2/g" ./Package.swift

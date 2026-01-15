// swift-tools-version: 6.0

import PackageDescription

let useLocalFramework = true
let binaryTarget: Target

if useLocalFramework {
    binaryTarget = .binaryTarget(
        name: "QueueFileRS",
        path: "./build/libqueuefile-rs.xcframework"
    )
} else {
    let releaseTag = "0.1.0"
    let releaseChecksum = "2b23d725d9fed0199293928129b2cf7b4a218dce29dd403d2bd321a097529f34"
    binaryTarget = .binaryTarget(
        name: "QueueFileRS",
        url:
        "https://github.com/example/QueueFile.swift/releases/download/\(releaseTag)/libqueuefile-rs.xcframework.zip",
        checksum: releaseChecksum
    )
}

let package = Package(
    name: "QueueFileSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "QueueFileSwift",
            targets: ["QueueFileSwift"]
        ),
    ],
    targets: [
        binaryTarget,
        .target(
            name: "QueueFileSwift",
            dependencies: ["QueueFileFFI"]
        ),
        .target(
            name: "QueueFileFFI",
            dependencies: ["QueueFileRS"]
        ),
        .testTarget(
            name: "QueueFileSwiftTests",
            dependencies: ["QueueFileSwift"]
        ),
    ]
)

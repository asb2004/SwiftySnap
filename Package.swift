// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftySnap",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SwiftySnap",
            targets: ["SwiftySnap"]),
    ],
    targets: [
        .target(
            name: "SwiftySnap",
            resources: [
                .process("Camera View/View/SwiftySnapViewController.xib"),
                .process("Assets/Media.xcassets")
            ]
        ),
    ]
)

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KLSubjectVision",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KLSubjectVision", targets: ["KLSubjectVision"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.4.0"
        ),
    ],
    targets: [
        .target(name: "KLSubjectVision"),
        .testTarget(name: "KLSubjectVisionTests", dependencies: ["KLSubjectVision"]),
    ]
)

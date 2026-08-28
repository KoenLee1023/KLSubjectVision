// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ThumbnailMatrix",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "ThumbnailMatrix",
            dependencies: [.product(name: "KLSubjectVision", package: "KLSubjectVision")]
        ),
    ]
)

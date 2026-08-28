// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SubjectStudio",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "SubjectStudio",
            dependencies: [.product(name: "KLSubjectVision", package: "KLSubjectVision")]
        ),
    ]
)

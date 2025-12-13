// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WordiestCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "WordiestCore", targets: ["WordiestCore"]),
    ],
    targets: [
        .target(
            name: "WordiestCore"
        ),
        .testTarget(
            name: "WordiestCoreTests",
            dependencies: ["WordiestCore"]
        ),
    ]
)


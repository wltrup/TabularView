// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "TabularView",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "TabularView",
            targets: ["TabularView"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TabularView",
            dependencies: []
        ),
    ]
)

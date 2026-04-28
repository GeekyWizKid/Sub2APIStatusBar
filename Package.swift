// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Sub2APIStatusBar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Sub2APIStatusBar", targets: ["Sub2APIStatusBar"]),
        .library(name: "Sub2APIStatusCore", targets: ["Sub2APIStatusCore"]),
    ],
    targets: [
        .target(name: "Sub2APIStatusCore"),
        .executableTarget(
            name: "Sub2APIStatusBar",
            dependencies: ["Sub2APIStatusCore"]
        ),
        .testTarget(
            name: "Sub2APIStatusCoreTests",
            dependencies: ["Sub2APIStatusCore"]
        ),
    ]
)

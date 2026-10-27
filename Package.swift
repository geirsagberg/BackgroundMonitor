// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "BackgroundMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BackgroundMonitorCore",
            targets: ["BackgroundMonitorCore"]
        ),
        .executable(
            name: "BackgroundMonitor",
            targets: ["BackgroundMonitor"]
        )
    ],
    targets: [
        .target(name: "BackgroundMonitorCore"),
        .executableTarget(
            name: "BackgroundMonitor",
            dependencies: ["BackgroundMonitorCore"]
        ),
        .testTarget(
            name: "BackgroundMonitorCoreTests",
            dependencies: ["BackgroundMonitorCore"]
        ),
        .testTarget(
            name: "BackgroundMonitorTests",
            dependencies: ["BackgroundMonitor"]
        )
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RosettaBB",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "RosettaBBCore"),
        .executableTarget(
            name: "RosettaBB",
            dependencies: ["RosettaBBCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RosettaBBCoreTests",
            dependencies: ["RosettaBBCore"]
        ),
    ]
)

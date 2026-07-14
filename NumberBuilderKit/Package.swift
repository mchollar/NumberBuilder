// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NumberBuilderKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "NumberBuilderKit", targets: ["NumberBuilderKit"])
    ],
    targets: [
        .target(name: "NumberBuilderKit"),
        .testTarget(name: "NumberBuilderKitTests", dependencies: ["NumberBuilderKit"])
    ]
)

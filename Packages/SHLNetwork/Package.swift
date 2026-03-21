// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SHLNetwork",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SHLNetwork", targets: ["SHLNetwork"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "SHLNetwork",
            dependencies: [.product(name: "Logging", package: "swift-log")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

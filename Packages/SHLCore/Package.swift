// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SHLCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SHLCore", targets: ["SHLCore"]),
    ],
    dependencies: [
        .package(path: "../SHLNetwork"),
        .package(path: "../SHLWidgetShared"),
    ],
    targets: [
        .target(
            name: "SHLCore",
            dependencies: ["SHLNetwork", "SHLWidgetShared"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

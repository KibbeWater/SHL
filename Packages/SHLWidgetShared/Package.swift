// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SHLWidgetShared",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SHLWidgetShared", targets: ["SHLWidgetShared"]),
    ],
    targets: [
        .target(
            name: "SHLWidgetShared",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

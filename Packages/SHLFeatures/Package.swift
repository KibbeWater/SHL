// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SHLFeatures",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SHLFeatures", targets: ["SHLFeatures"]),
    ],
    dependencies: [
        .package(path: "../SHLNetwork"),
        .package(path: "../SHLCore"),
        .package(path: "../SHLWidgetShared"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.17.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
        .package(url: "https://github.com/SVGKit/SVGKit.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "SHLFeatures",
            dependencies: [
                "SHLNetwork",
                "SHLCore",
                "SHLWidgetShared",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "Kingfisher",
                "SVGKit",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

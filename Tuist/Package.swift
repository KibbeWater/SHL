// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "Kingfisher": .framework,
        "PostHog": .framework,
        "SVGKit": .framework,
    ]
)
#endif

let package = Package(
    name: "SHLDependencies",
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
        .package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.0.0"),
        .package(url: "https://github.com/SVGKit/SVGKit.git", from: "3.0.0"),
    ]
)

import ProjectDescription

let project = Project(
    name: "SHL",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "89625ZHN6X",
            "SWIFT_VERSION": "5.0",
        ],
        configurations: [
            .debug(name: "Debug", settings: [
                "IPHONEOS_DEPLOYMENT_TARGET": "17.2",
            ]),
            .release(name: "Release", settings: [
                "IPHONEOS_DEPLOYMENT_TARGET": "17.2",
            ]),
        ]
    ),
    targets: [
        // MARK: - Shared Frameworks (Tuist targets, not SPM packages)

        .target(
            name: "SHLNetwork",
            destinations: [.iPhone, .iPad],
            product: .staticFramework,
            bundleId: "com.kibbewater.shl.network",
            sources: ["Packages/SHLNetwork/Sources/SHLNetwork/**/*.swift"],
            dependencies: []
        ),

        .target(
            name: "SHLWidgetShared",
            destinations: [.iPhone, .iPad],
            product: .staticFramework,
            bundleId: "com.kibbewater.shl.widgetshared",
            sources: ["Packages/SHLWidgetShared/Sources/SHLWidgetShared/**/*.swift"],
            dependencies: []
        ),

        .target(
            name: "SHLCore",
            destinations: [.iPhone, .iPad],
            product: .staticFramework,
            bundleId: "com.kibbewater.shl.core",
            sources: ["Packages/SHLCore/Sources/SHLCore/**/*.swift"],
            dependencies: [
                .target(name: "SHLNetwork"),
                .target(name: "SHLWidgetShared"),
            ]
        ),

        // MARK: - Main App
        .target(
            name: "SHL",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.kibbewater.shl",
            deploymentTargets: .iOS("18.6"),
            infoPlist: .extendingDefault(with: [
                "CFBundleURLTypes": .array([
                    .dictionary([
                        "CFBundleTypeRole": .string("Viewer"),
                        "CFBundleURLName": .string("com.kibbewater.shl"),
                        "CFBundleURLSchemes": .array([.string("shltracker")]),
                    ]),
                ]),
                "NSUserActivityTypes": .array([.string("IntentIntent")]),
                "UIBackgroundModes": .array([.string("remote-notification")]),
                "NSSupportsLiveActivitiesFrequentUpdates": .boolean(true),
            ]),
            sources: ["SHL/**/*.swift"],
            resources: [
                "SHL/Assets.xcassets",
                "SHL/Preview Content/**",
                "SHL/Launch Screen.storyboard",
                "SHL/Components/Pulse Shader/Pulse.metal",
            ],
            entitlements: .file(path: "SHL/SHL.entitlements"),
            dependencies: [
                .target(name: "SHLNetwork"),
                .target(name: "SHLCore"),
                .target(name: "SHLWidgetShared"),
                .external(name: "Kingfisher"),
                .external(name: "PostHog"),
                .external(name: "SVGKit"),
                .target(name: "SHLWidget"),
            ],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": "1.4.2",
                    "CURRENT_PROJECT_VERSION": "1",
                    "TARGETED_DEVICE_FAMILY": "1,2",
                ]
            )
        ),

        // MARK: - Widget Extension
        .target(
            name: "SHLWidget",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "com.kibbewater.shl.SHLWidget",
            deploymentTargets: .iOS("17.2"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension"),
                ]),
            ]),
            sources: ["SHLWidget/**/*.swift"],
            resources: [
                "SHLWidget/Assets.xcassets",
            ],
            entitlements: .file(path: "SHLWidgetExtension.entitlements"),
            dependencies: [
                .target(name: "SHLNetwork"),
                .external(name: "Kingfisher"),
            ],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": "1.4.2",
                    "CURRENT_PROJECT_VERSION": "1",
                    "TARGETED_DEVICE_FAMILY": "1,2",
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                ]
            )
        ),
    ],
    schemes: [
        .scheme(
            name: "SHL",
            shared: true,
            buildAction: .buildAction(targets: ["SHL"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
    ]
)

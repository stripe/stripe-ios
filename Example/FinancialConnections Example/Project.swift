import ProjectDescription

let project = Project(
    name: "FinancialConnections Example",
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: "//BuildConfigurations/Project-Debug.xcconfig"
            ),
            .release(
                name: "Release",
                xcconfig: "//BuildConfigurations/Project-Release.xcconfig"
            ),
        ],
        defaultSettings: .none
    ),
    targets: [
        Target(
            name: "FinancialConnections Example",
            platform: .iOS,
            product: .app,
            productName: "FinancialConnectionsExample",
            bundleId: "com.stripe.example.Connections-Example",
            infoPlist: "FinancialConnections Example/Info.plist",
            sources: "FinancialConnections Example/*.swift",
            resources: [
                "FinancialConnections Example/Assets.xcassets",
                "FinancialConnections Example/Base.lproj/**",
            ],
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(
                    target: "StripeFinancialConnections",
                    path: "//StripeFinancialConnections"
                ),
            ],
            settings: .settings(base: [
                "TARGETED_DEVICE_FAMILY": "1,2",
                "CURRENT_PROJECT_VERSION": "1.1",
                "VERSIONING_SYSTEM": "apple-generic",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": true,
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            ])
        )
    ],
    schemes: [
        Scheme(
            name: "FinancialConnections Example",
            buildAction: .buildAction(targets: ["FinancialConnections Example"]),
            runAction: .runAction(executable: "FinancialConnections Example")
        )
    ]
)

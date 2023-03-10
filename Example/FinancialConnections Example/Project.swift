import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "FinancialConnections Example",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
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
            sources: "FinancialConnections Example/**/*.swift",
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
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/FinancialConnections-Example"
            )
        ),
        Target(
            name: "FinancialConnectionsUITests",
            platform: .iOS,
            product: .uiTests,
            productName: "FinancialConnectionsUITests",
            bundleId: "com.stripe.FinancialConnectionsUITests",
            infoPlist: "FinancialConnectionsUITests/Info.plist",
            sources: "FinancialConnectionsUITests/*.swift",
            dependencies: [
                .target(name: "FinancialConnections Example"),
                .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/FinancialConnectionsUITests"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "FinancialConnections Example",
            buildAction: .buildAction(
                targets: [
                    "FinancialConnections Example",
                    "FinancialConnectionsUITests",
                ]
            ),
            testAction: .targets(
                [
                    "FinancialConnectionsUITests"
                ],
                expandVariableFromTarget: "FinancialConnections Example"
            ),
            runAction: .runAction(executable: "FinancialConnections Example")
        ),
    ]
)

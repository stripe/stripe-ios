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
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "BuildConfigurations/FinancialConnections-Example-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "BuildConfigurations/FinancialConnections-Example-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
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

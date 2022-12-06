import ProjectDescription

let project = Project(
    name: "Basic Integration",
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
            name: "Basic Integration",
            platform: .iOS,
            product: .app,
            productName: "BasicIntegration",
            bundleId: "com.stripe.SimpleSDKExample",
            infoPlist: "Basic Integration/Info.plist",
            sources: "Basic Integration/*.swift",
            resources: "Basic Integration/Resources/**",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
                .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
                .project(target: "StripeiOS", path: "//Stripe"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "BuildConfigurations/BasicIntegration-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "BuildConfigurations/BasicIntegration-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
        ),
        Target(
            name: "BasicIntegrationUITests",
            platform: .iOS,
            product: .uiTests,
            productName: "BasicIntegrationUITests",
            bundleId: "com.stripe.BasicIntegrationUITests",
            infoPlist: "BasicIntegrationUITests/Info.plist",
            sources: "BasicIntegrationUITests/*.swift",
            dependencies: [
                .target(name: "Basic Integration"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "BuildConfigurations/BasicIntegrationUITests-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "BuildConfigurations/BasicIntegrationUITests-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "Basic Integration",
            buildAction: .buildAction(targets: [
                "Basic Integration",
                "BasicIntegrationUITests",
            ]),
            testAction: .targets(["BasicIntegrationUITests"]),
            runAction: .runAction(executable: "Basic Integration")
        )
    ]
)

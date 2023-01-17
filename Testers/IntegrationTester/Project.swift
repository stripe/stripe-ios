import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "IntegrationTester",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .settings(
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: "BuildConfigurations/Project-Debug.xcconfig"
            ),
            .release(
                name: "Release",
                xcconfig: "BuildConfigurations/Project-Release.xcconfig"
            ),
        ],
        defaultSettings: .none
    ),
    targets: [
        Target(
            name: "Common",
            platform: .iOS,
            product: .staticLibrary,
            productName: "IntegrationTesterCommon",
            bundleId: "com.stripe.IntegrationTesterCommon",
            sources: "Common/**/*.swift",
            dependencies: [
                .project(target: "StripeiOS", path: "//Stripe"),
            ],
            settings: .stripeTargetSettings(
                base: [
                    "SKIP_INSTALL": true,
                ],
                baseXcconfigFilePath: "BuildConfigurations/IntegrationTester"
            )
        ),
        Target(
            name: "IntegrationTester",
            platform: .iOS,
            product: .app,
            bundleId: "com.stripe.IntegrationTester",
            infoPlist: "IntegrationTester/Info.plist",
            sources: "IntegrationTester/Source/**/*.swift",
            resources: "IntegrationTester/Resources/**",
            entitlements: "IntegrationTester/IntegrationTester.entitlements",
            dependencies: [
                .target(name: "Common"),
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
                .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
                .project(target: "StripeiOS", path: "//Stripe"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/IntegrationTester"
            )
        ),
        Target(
            name: "IntegrationTesterUITests",
            platform: .iOS,
            product: .uiTests,
            bundleId: "com.stripe.IntegrationTesterUITests",
            infoPlist: "IntegrationTesterUITests/Info.plist",
            sources: "IntegrationTesterUITests/*.swift",
            dependencies: [
                .target(name: "Common"),
                .target(name: "IntegrationTester"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/IntegrationTesterUITests"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "IntegrationTester",
            buildAction: .buildAction(targets: ["IntegrationTester"]),
            testAction: .targets(["IntegrationTesterUITests"])
        ),
    ]
)

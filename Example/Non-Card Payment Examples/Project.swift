import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Non-Card Payment Examples",
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
            name: "Non-Card Payment Examples",
            platform: .iOS,
            product: .app,
            productName: "NonCardPaymentExamples",
            bundleId: "com.stripe.CustomSDKExample",
            infoPlist: "Non-Card Payment Examples/Info.plist",
            sources: [
                "Non-Card Payment Examples/*.swift",
                "Non-Card Payment Examples/*.m",
            ],
            resources: "Non-Card Payment Examples/Resources/**",
            headers: .headers(project: "Non-Card Payment Example/*.h"),
            entitlements: "Non-Card Payment Examples/Non-Card Payment Examples.entitlements",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
                .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
                .project(target: "StripePaymentSheet", path: "//StripePaymentSheet"),
                .project(target: "StripeiOS", path: "//Stripe"),
                .project(
                    target: "StripeFinancialConnections",
                    path: "//StripeFinancialConnections"
                ),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Non-Card-Payment-Examples"
            ),
            additionalFiles: [
                "Non-Card Payment Examples/*.h",
            ]
        ),
    ],
    schemes: [
        Scheme(
            name: "Non-Card Payment Examples",
            buildAction: .buildAction(targets: ["Non-Card Payment Examples"]),
            runAction: .runAction(executable: "Non-Card Payment Examples")
        ),
    ],
    additionalFiles: "README.md"
)

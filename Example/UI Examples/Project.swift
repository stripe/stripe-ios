import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "UI Examples",
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
            name: "UI Examples",
            platform: .iOS,
            product: .app,
            productName: "UIExamples",
            bundleId: "com.stripe.uiexamples",
            infoPlist: "UI Examples/Info.plist",
            sources: "UI Examples/Source/**/*.swift",
            resources: "UI Examples/Resources/**",
            dependencies: [
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
                .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
                .project(target: "StripeiOS", path: "//Stripe"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/UI-Examples"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "UI Examples",
            buildAction: .buildAction(targets: ["UI Examples"]),
            runAction: .runAction(executable: "UI Examples")
        ),
    ],
    additionalFiles: "README.md"
)

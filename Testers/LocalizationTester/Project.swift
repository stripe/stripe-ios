import ProjectDescription

let project = Project(
    name: "LocalizationTester",
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
            name: "LocalizationTester",
            platform: .iOS,
            product: .app,
            bundleId: "com.stripe.LocalizationTester",
            infoPlist: "LocalizationTester/Info.plist",
            sources: "LocalizationTester/Source/**/*.m",
            resources: "LocalizationTester/Resources/**",
            headers: .headers(
                project: "LocalizationTester/Source/**/*.h"
            ),
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
                        xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
        ),
        Target(
            name: "LocalizationTesterUITests",
            platform: .iOS,
            product: .uiTests,
            bundleId: "com.stripe.LocalizationTesterUITests",
            infoPlist: "LocalizationTesterUITests/Info.plist",
            sources: "LocalizationTesterUITests/*.m",
            dependencies: [
                .target(name: "LocalizationTester"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        xcconfig: "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
                    ),
                ],
                defaultSettings: .none
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "LocalizationTester",
            buildAction: .buildAction(targets: ["LocalizationTester"]),
            testAction: .targets(["LocalizationTesterUITests"])
        )
    ],
    resourceSynthesizers: []
)

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeApplePay",
    packages: [
        .remote(
            url: "https://github.com/eurias-stripe/OHHTTPStubs",
            requirement: .branch("master")
        ),
    ],
    additionalTargets: [
        Target(
            name: "StripeApplePayTestUtils",
            platform: .iOS,
            product: .framework,
            bundleId: "com.stripe.StripeApplePayTestUtils",
            infoPlist: "StripeApplePayTestUtils/Info.plist",
            sources: "StripeApplePayTestUtils/**/*.swift",
            headers: .headers(
                public: "StripeApplePayTestUtils/StripeApplePayTestUtils.h"
            ),
            dependencies: [
                .xctest,
                .target(name: "StripeApplePay"),
            ],
            settings: .settings(configurations: [
                .debug(
                    name: "Debug",
                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Debug.xcconfig"
                ),
                .release(
                    name: "Release",
                    xcconfig: "//BuildConfigurations/StripeiOS Tests-Release.xcconfig"
                ),
            ])
        ),
    ],
    additionalSchemes: [
        Scheme(
            name: "StripeApplePayTestUtils",
            buildAction: .buildAction(targets: ["StripeApplePayTestUtils"])
        ),
    ],
    unitTestOptions: .testOptions(
        dependencies: [
            .target(name: "StripeApplePayTestUtils"),
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
            .package(product: "OHHTTPStubs"),
            .package(product: "OHHTTPStubsSwift"),
        ]
    )
)

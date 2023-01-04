import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Stripe",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [
        .remote(
            url: "https://github.com/uber/ios-snapshot-test-case",
            requirement: .upToNextMajor(from: "8.0.0")
        ),
        .remote(
            url: "https://github.com/eurias-stripe/OHHTTPStubs",
            requirement: .branch("master")
        ),
        .remote(url: "https://github.com/erikdoe/ocmock", requirement: .branch("master")),
    ],
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
            name: "StripeiOS",
            platform: .iOS,
            product: .framework,
            productName: "Stripe",
            bundleId: "com.stripe.stripe-ios",
            infoPlist: "StripeiOS/Info.plist",
            sources: [
                "StripeiOS/Source/**/*.swift",
                "StripeiOS/*.docc",
            ],
            resources: "StripeiOS/Resources/**",
            headers: .headers(
                public: "StripeiOS/Stripe-umbrella.h"
            ),
            dependencies: [
                .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
                .project(target: "StripeCore", path: "//StripeCore"),
                .project(target: "StripeUICore", path: "//StripeUICore"),
                .project(target: "StripeApplePay", path: "//StripeApplePay"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Stripe"
            )
        ),
        Target(
            name: "StripeiOSTests",
            platform: .iOS,
            product: .unitTests,
            productName: "StripeiOS_Tests",
            bundleId: "com.stripe.StripeiOSTests",
            infoPlist: "StripeiOSTests/Info.plist",
            sources: [
                "StripeiOSTests/**/*.swift",
                "StripeiOSTests/**/*.m",
            ],
            resources: .init(resources: [
                "StripeiOSTests/Resources/*.*",
                "StripeiOSTests/Resources/Images.xcassets",
                .folderReference(path: "StripeiOSTests/Resources/recorded_network_traffic"),
                .folderReference(path: "StripeiOSTests/Resources/MockFiles"),
            ]),
            headers: .headers(
                project: "StripeiOSTests/*.h"
            ),
            dependencies: [
                .xctest,
                .target(name: "StripeiOS"),
                .package(product: "OHHTTPStubs"),
                .package(product: "OHHTTPStubsSwift"),
                .package(product: "OCMock"),
                .package(product: "iOSSnapshotTestCase"),
                .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
                .project(target: "StripePayments", path: "//StripePayments"),
                .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
                .project(target: "StripePaymentSheet", path: "//StripePaymentSheet"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "BuildConfigurations/Stripe Tests"
            ),
            additionalFiles: [
                "StripeiOSTests.xctestplan"
            ]
        ),
        Target(
            name: "StripeiOSTestHostApp",
            platform: .iOS,
            product: .app,
            bundleId: "com.stripe.StripeiOSTestHostApp",
            infoPlist: "StripeiOSTestHostApp/Info.plist",
            sources: "StripeiOSTestHostApp/*.swift",
            resources: "StripeiOSTestHostApp/Resources/**",
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "//BuildConfigurations/StripeiOS Tests"
            )
        ),
        Target(
            name: "StripeiOSAppHostedTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "com.stripe.StripeiOSAppHostedTests",
            infoPlist: "StripeiOSAppHostedTests/Info.plist",
            sources: "StripeiOSAppHostedTests/*.swift",
            dependencies: [
                .xctest,
                .target(name: "StripeiOS"),
                .target(name: "StripeiOSTestHostApp"),
                .project(target: "StripePaymentSheet", path: "//StripePaymentSheet"),
            ],
            settings: .stripeTargetSettings(
                baseXcconfigFilePath: "//BuildConfigurations/StripeiOS Tests"
            )
        ),
    ],
    schemes: [
        Scheme(
            name: "StripeiOS",
            buildAction: .buildAction(targets: ["StripeiOS"]),
            testAction: .testPlans(["StripeiOSTests.xctestplan"])
        ),
        Scheme(
            name: "StripeiOSTestHostApp",
            buildAction: .buildAction(targets: ["StripeiOS"]),
            testAction: .targets(["StripeiOSAppHostedTests"]),
            runAction: .runAction(executable: "StripeiOSTestHostApp")
        ),
    ]
)

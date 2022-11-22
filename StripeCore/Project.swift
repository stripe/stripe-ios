import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCore",
    packages: [
        .remote(url: "https://github.com/erikdoe/ocmock", requirement: .branch("master")),
        .remote(
            url: "https://github.com/uber/ios-snapshot-test-case",
            requirement: .upToNextMajor(from: "8.0.0")
        ),
        .remote(
            url: "https://github.com/eurias-stripe/OHHTTPStubs",
            requirement: .branch("master")
        ),
    ],
    resources: "StripeCore/Resources/**",
    additionalTargets: [
        Target(
            name: "StripeCoreTestUtils",
            platform: .iOS,
            product: .framework,
            bundleId: "com.stripe.StripeCoreTestUtils",
            infoPlist: "StripeCoreTestUtils/Info.plist",
            sources: "StripeCoreTestUtils/**/*.swift",
            resources: "StripeCoreTestUtils/Mock Files/**",
            headers: .headers(
                public: "StripeCoreTestUtils/StripeCoreTestUtils.h"
            ),
            dependencies: [
                .xctest,
                .target(name: "StripeCore"),
                .package(product: "OHHTTPStubs"),
                .package(product: "OHHTTPStubsSwift"),
                .package(product: "iOSSnapshotTestCase"),
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
                ]
            )
        ),
    ],
    additionalSchemes: [
        Scheme(
            name: "StripeCoreTestUtils",
            buildAction: .buildAction(targets: ["StripeCoreTestUtils"])
        ),
    ],
    unitTestOptions: .testOptions(
        resources: "StripeCoreTests/Mock Files/**",
        dependencies: [
            .target(name: "StripeCoreTestUtils"),
        ]
    )
)

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCardScan",
    targetSettingsOverride: .settings(configurations: [
        .debug(
            name: "Debug",
            xcconfig: "BuildConfigurations/StripeCardScan-Debug.xcconfig"
        ),
        .release(
            name: "Release",
            xcconfig: "BuildConfigurations/StripeCardScan-Release.xcconfig"
        )
    ]),
    resources: "StripeCardScan/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
    ],
    unitTestOptions: .testOptions(
        resources: [
            "StripeCardScanTests/Mock Data/**",
            "StripeCardScanTests/Resources/**",
        ],
        dependencies: [
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
        ]
    )
)

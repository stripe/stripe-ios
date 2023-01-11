import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCardScan",
    targetSettings: .settings(
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: "BuildConfigurations/StripeCardScan-Debug.xcconfig"
            ),
            .release(
                name: "Release",
                xcconfig: "BuildConfigurations/StripeCardScan-Release.xcconfig"
            ),
        ],
        defaultSettings: .none
    ),
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

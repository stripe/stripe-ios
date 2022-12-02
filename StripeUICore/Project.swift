import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeUICore",
    resources: "StripeUICore/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
    ],
    unitTestOptions: .testOptions(
        dependencies: [
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
        ],
        includesSnapshots: true
    )
)

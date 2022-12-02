import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeApplePay",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
    ],
    unitTestOptions: .testOptions(
        dependencies: [
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
        ],
        usesStubs: true
    )
)

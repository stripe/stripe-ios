import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeFinancialConnections",
    resources: "StripeFinancialConnections/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
        .project(target: "StripeUICore", path: "//StripeUICore"),
    ],
    unitTestOptions: .testOptions(
        resources: "StripeFinancialConnectionsTests/MockData/**",
        dependencies: [
            .project(target: "StripeCore", path: "//StripeCore"),
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
            .project(target: "StripeUICore", path: "//StripeUICore"),
        ]
    )
)

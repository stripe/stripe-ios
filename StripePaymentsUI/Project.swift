import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripePaymentsUI",
    resources: "StripePaymentsUI/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
        .project(target: "StripeUICore", path: "//StripeUICore"),
        .project(target: "StripePayments", path: "//StripePayments"),
        .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
    ],
    unitTestOptions: .testOptions(
        dependencies: [
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
            .project(target: "StripePaymentsObjcTestUtils", path: "//StripePayments"),
            .project(target: "StripePaymentsTestUtils", path: "//StripePayments"),
        ],
        includesSnapshots: true
    )
)

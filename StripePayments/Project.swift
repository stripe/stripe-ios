import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripePayments",
    resources: "StripePayments/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
        .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
        .project(target: "StripeUICore", path: "//StripeUICore"),
    ],
    testUtilsOptions: .testOptions(
        includesSnapshots: true,
        usesStubs: true
    ),
    objcTestUtilsOptions: .testOptions(
        includesSnapshots: false,
        usesStubs: false
    ),
    unitTestOptions: .testOptions()
)

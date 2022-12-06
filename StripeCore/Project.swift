import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCore",
    resources: "StripeCore/Resources/**",
    testUtilsOptions: .testOptions(
        resources: "StripeCoreTestUtils/Mock Files/**",
        includesSnapshots: true,
        usesStubs: true
    ),
    unitTestOptions: .testOptions(resources: "StripeCoreTests/Mock Files/**")
)

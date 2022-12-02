import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeCameraCore",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
    ],
    testUtilsOptions: .testOptions(),
    unitTestOptions: .testOptions()
)

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeIdentity",
    resources: "StripeIdentity/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
        .project(target: "StripeUICore", path: "//StripeUICore"),
        .project(target: "StripeCameraCore", path: "//StripeCameraCore"),
    ],
    unitTestOptions: .testOptions(
        resources: "StripeIdentityTests/Mock Files/**",
        dependencies: [
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
            .project(target: "StripeCameraCoreTestUtils", path: "//StripeCameraCore"),
        ],
        includesSnapshots: true
    )
)

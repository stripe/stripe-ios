import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripeUICore",
    packages: [
        .remote(
            url: "https://github.com/uber/ios-snapshot-test-case",
            requirement: .upToNextMajor(from: "8.0.0")
        )
    ],
    resources: "StripeUICore/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
    ],
    unitTestOptions: .testOptions(
        dependencies: [
            .project(target: "StripeCoreTestUtils", path: "//StripeCore"),
            .package(product: "iOSSnapshotTestCase"),
        ],
        includesSnapshots: true
    )
)

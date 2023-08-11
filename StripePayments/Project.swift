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
        resources: .init(resources: [
            .folderReference(path: "StripePaymentsTestUtils/Resources/recorded_network_traffic")
        ]),
        includesSnapshots: true,
        usesStubs: true
    ),
    objcTestUtilsOptions: .testOptions(
        resources: .init(resources: [
            .folderReference(path: "StripePaymentsObjcTestUtils/Resources/Mock Files"),
        ]),
        includesSnapshots: false,
        usesStubs: false
    ),
    unitTestOptions: .testOptions()
)

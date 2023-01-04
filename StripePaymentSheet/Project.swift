import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.stripeFramework(
    name: "StripePaymentSheet",
    resources: "StripePaymentSheet/Resources/**",
    dependencies: [
        .project(target: "StripeCore", path: "//StripeCore"),
        .project(target: "StripeUICore", path: "//StripeUICore"),
        .project(target: "Stripe3DS2", path: "//Stripe3DS2"),
        .project(target: "StripeApplePay", path: "//StripeApplePay"),
        .project(target: "StripePayments", path: "//StripePayments"),
        .project(target: "StripePaymentsUI", path: "//StripePaymentsUI"),
    ],
    unitTestOptions: .testOptions()
)

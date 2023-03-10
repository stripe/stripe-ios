// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Stripe",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Stripe",
            targets: ["Stripe"]
        ),
        .library(
            name: "StripePayments",
            targets: ["StripePayments"]
        ),
        .library(
            name: "StripePaymentsUI",
            targets: ["StripePaymentsUI"]
        ),
        .library(
            name: "StripePaymentSheet",
            targets: ["StripePaymentSheet"]
        ),
        .library(
            name: "StripeApplePay",
            targets: ["StripeApplePay"]
        ),
        .library(
            name: "StripeIdentity",
            targets: ["StripeIdentity"]
        ),
        .library(
            name: "StripeCardScan",
            targets: ["StripeCardScan"]
        ),
        .library(
            name: "StripeFinancialConnections",
            targets: ["StripeFinancialConnections"]
        )
    ],
    targets: [
        .target(
            name: "Stripe",
            dependencies: ["Stripe3DS2", "StripeCore", "StripeApplePay", "StripeUICore", "StripePayments", "StripePaymentsUI"],
            path: "Stripe/StripeiOS",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images")
            ]
        ),
        .target(
            name: "Stripe3DS2",
            path: "Stripe3DS2/Stripe3DS2",
            exclude: ["Info.plist", "Resources/CertificateFiles", "include/Stripe3DS2-Prefix.pch"],
            resources: [
                .process("Resources")
            ],
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
        .target(
            name: "StripeCameraCore",
            dependencies: ["StripeCore"],
            path: "StripeCameraCore/StripeCameraCore",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "StripeCore",
            path: "StripeCore/StripeCore",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "StripeApplePay",
            dependencies: ["StripeCore"],
            path: "StripeApplePay/StripeApplePay",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "StripeIdentity",
            dependencies: ["StripeCore", "StripeUICore", "StripeCameraCore"],
            path: "StripeIdentity/StripeIdentity",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images")
            ]
        ),
        .target(
            name: "StripeCardScan",
            dependencies: ["StripeCore"],
            path: "StripeCardScan/StripeCardScan",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/CompiledModels")
            ]
        ),
        .target(
            name: "StripeUICore",
            dependencies: ["StripeCore"],
            path: "StripeUICore/StripeUICore",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "StripePayments",
            dependencies: ["StripeCore", "Stripe3DS2"],
            path: "StripePayments/StripePayments",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "StripePaymentsUI",
            dependencies: ["StripeCore", "Stripe3DS2", "StripePayments", "StripeUICore"],
            path: "StripePaymentsUI/StripePaymentsUI",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "StripePaymentSheet",
            dependencies: ["StripePaymentsUI", "StripeApplePay", "StripePayments", "StripeCore", "StripeUICore"],
            path: "StripePaymentSheet/StripePaymentSheet",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "StripeFinancialConnections",
            dependencies: ["StripeCore", "StripeUICore"],
            path: "StripeFinancialConnections/StripeFinancialConnections",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images"),
            ]
        ),
        .target(
            name: "StripeLinkCore",
            //dependencies: ["StripeCore"],
            path: "StripeLinkCore/StripeLinkCore",
            exclude: ["Info.plist"]
        )
    ]
)

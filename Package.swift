// swift-tools-version:5.3
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
            path: "Stripe",
            resources: [
                .process("Resources/Images")
            ]
        ),
        .target(
            name: "Stripe3DS2",
            path: "Stripe3DS2/Stripe3DS2",
            exclude: ["Resources/CertificateFiles", "include/Stripe3DS2-Prefix.pch"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "StripeCameraCore",
            dependencies: ["StripeCore"],
            path: "StripeCameraCore/StripeCameraCore"
        ),
        .target(
            name: "StripeCore",
            path: "StripeCore/StripeCore"
        ),
        .target(
            name: "StripeApplePay",
            dependencies: ["StripeCore"],
            path: "StripeApplePay/StripeApplePay"
        ),
        .target(
            name: "StripeIdentity",
            dependencies: ["StripeCore", "StripeUICore", "StripeCameraCore"],
            path: "StripeIdentity/StripeIdentity",
            resources: [
                .process("Resources/Images")
            ]
        ),
        .target(
            name: "StripeCardScan",
            dependencies: ["StripeCore"],
            path: "StripeCardScan/StripeCardScan",
            resources: [
                .process("Resources/CompiledModels")
            ]
        ),
        .target(
            name: "StripeUICore",
            dependencies: ["StripeCore"],
            path: "StripeUICore/StripeUICore",
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
                .process("Info.plist"),
                .process("Resources")
            ]
        ),
        .target(
            name: "StripePaymentsUI",
            dependencies: ["StripeCore", "Stripe3DS2", "StripePayments", "StripeUICore"],
            path: "StripePaymentsUI/StripePaymentsUI",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
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
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "StripeFinancialConnections",
            dependencies: ["StripeCore", "StripeUICore"],
            path: "StripeFinancialConnections/StripeFinancialConnections",
            resources: [
                .process("Resources/Images"),
            ]
        )
    ]
)

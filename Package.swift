// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Stripe",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Stripe",
            targets: ["Stripe"]
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
            dependencies: ["Stripe3DS2", "StripeCore", "StripeApplePay", "StripeUICore"],
            path: "Stripe",
            exclude: ["PanModal/LICENSE"],
            resources: [
                .process("Resources/Images"),
                .process("Resources/au_becs_bsb.json"),
                .process("Resources/form_specs.json")
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
            name: "StripeFinancialConnections",
            dependencies: ["StripeCore", "StripeUICore"],
            path: "StripeFinancialConnections/StripeFinancialConnections",
            resources: [
                .process("Resources/Images"),
            ]
        )
    ]
)

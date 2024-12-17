// swift-tools-version:5.7
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
        ),
        .library(
            name: "StripeConnect",
            targets: ["StripeConnect"]
        )
    ],
    targets: [
        .target(
            name: "Stripe",
            dependencies: ["Stripe3DS2", "StripeCore", "StripeApplePay", "StripeUICore", "StripePayments", "StripePaymentsUI"],
            path: "Stripe/StripeiOS",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/StripeiOS.xcassets"),
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "Stripe3DS2",
            path: "Stripe3DS2/Stripe3DS2",
            exclude: ["Info.plist", "Resources/CertificateFiles", "include/Stripe3DS2-Prefix.pch"],
            resources: [
                .process("Resources"),
                .process("PrivacyInfo.xcprivacy")
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
            exclude: ["Info.plist"],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
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
                .copy("Resources/CompiledModels/UxModel.mlmodelc"),
                .copy("Resources/CompiledModels/SSDOcr.mlmodelc")
            ]
        ),
        .target(
            name: "StripeUICore",
            dependencies: ["StripeCore"],
            path: "StripeUICore/StripeUICore",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/StripeUICore.xcassets"),
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
                .process("Resources/StripePaymentsUI.xcassets"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "StripePaymentSheet",
            dependencies: ["StripePaymentsUI", "StripeApplePay", "StripePayments", "StripeCore", "StripeUICore"],
            path: "StripePaymentSheet/StripePaymentSheet",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/StripePaymentSheet.xcassets"),
                .process("Resources/JSON"),
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "StripeFinancialConnections",
            dependencies: ["StripeCore", "StripeUICore"],
            path: "StripeFinancialConnections/StripeFinancialConnections",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Images"),
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "StripeConnect",
            dependencies: ["StripeCore", "StripeUICore", "StripeFinancialConnections"],
            path: "StripeConnect/StripeConnect"
        )
    ]
)

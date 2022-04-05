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
            name: "StripeConnections",
            targets: ["StripeConnections"]
        )
    ],
    targets: [
        .target(
            name: "Stripe",
            dependencies: ["Stripe3DS2", "StripeCore", "StripeApplePay", "StripeUICore"],
            path: "Stripe",
            exclude: ["Info.plist", "PanModal/LICENSE"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/au_becs_bsb.json"),
                .process("Resources/form_specs.json")
            ]
        ),
        .target(
            name: "Stripe3DS2",
            path: "Stripe3DS2/Stripe3DS2",
            exclude: ["Info.plist", "Resources/CertificateFiles", "include/Stripe3DS2-Prefix.pch"],
            resources: [
                .process("Info.plist"),
                .process("Resources")
            ]
        ),
        .target(
            name: "StripeCameraCore",
            dependencies: ["StripeCore"],
            path: "StripeCameraCore/StripeCameraCore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "StripeCore",
            path: "StripeCore/StripeCore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "StripeApplePay",
            dependencies: ["StripeCore"],
            path: "StripeApplePay/StripeApplePay",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "StripeIdentity",
            dependencies: ["StripeCore", "StripeUICore", "StripeCameraCore"],
            path: "StripeIdentity/StripeIdentity",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images")
            ]
        ),
        .target(
            name: "StripeCardScan",
            dependencies: ["StripeCore"],
            path: "StripeCardScan/StripeCardScan",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/CompiledModels")
            ]
        ),
        .target(
            name: "StripeUICore",
            dependencies: ["StripeCore"],
            path: "StripeUICore/StripeUICore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "StripeConnections",
            dependencies: ["StripeCore", "StripeUICore"],
            path: "StripeConnections/StripeConnections",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
            ]
        )
    ]
)

// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Stripe",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "Stripe",
            targets: ["Stripe"]
        ),
        .library(
            name: "StripeIdentity",
            targets: ["StripeIdentity"]
        ),
        .library(
            name: "StripeScan",
            targets: ["StripeScan"]
        ),
        .library(
            name: "StripeConnections",
            targets: ["StripeConnections"]
        )
    ],
    targets: [
        .target(
            name: "Stripe",
            dependencies: ["Stripe3DS2", "StripeCore", "StripeUICore"],
            path: "Stripe",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/au_becs_bsb.json")
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
            name: "StripeCore",
            path: "StripeCore/StripeCore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "StripeIdentity",
            dependencies: ["StripeCore", "StripeUICore"],
            path: "StripeIdentity/StripeIdentity",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "StripeScan",
            path: "StripeScan/StripeScan",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
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
            path: "StripeConnections/StripeConnections",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)

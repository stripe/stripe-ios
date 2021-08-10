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
        )
    ],
    targets: [
        .target(
            name: "Stripe",
            dependencies: ["Stripe3DS2", "StripeCore"],
            path: "Stripe",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/au_becs_bsb.json"),
                .process("Resources/localized_address_data.json")
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
            dependencies: ["StripeCore"],
            path: "StripeIdentity/StripeIdentity",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)

// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Carded",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Carded",
            targets: ["Carded"]
        ),
        .library(
            name: "CardedApplePay",
            targets: ["CardedApplePay"]
        ),
        .library(
            name: "CardedIdentity",
            targets: ["CardedIdentity"]
        ),
        .library(
            name: "CardedCardScan",
            targets: ["CardedCardScan"]
        ),
        .library(
            name: "CardedFinancialConnections",
            targets: ["CardedFinancialConnections"]
        )
    ],
    targets: [
        .target(
            name: "Carded",
            dependencies: ["Carded3DS2", "CardedCore", "CardedApplePay", "CardedUICore"],
            path: "Carded",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/au_becs_bsb.json"),
                .process("Resources/form_specs.json")
            ]
        ),
        .target(
            name: "Carded3DS2",
            path: "Carded3DS2/Carded3DS2",
            exclude: ["Info.plist", "Resources/CertificateFiles", "include/Carded3DS2-Prefix.pch"],
            resources: [
                .process("Info.plist"),
                .process("Resources")
            ]
        ),
        .target(
            name: "CardedCameraCore",
            dependencies: ["CardedCore"],
            path: "CardedCameraCore/CardedCameraCore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "CardedCore",
            path: "CardedCore/CardedCore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "CardedApplePay",
            dependencies: ["CardedCore"],
            path: "CardedApplePay/CardedApplePay",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist")
            ]
        ),
        .target(
            name: "CardedIdentity",
            dependencies: ["CardedCore", "CardedUICore", "CardedCameraCore"],
            path: "CardedIdentity/CardedIdentity",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images")
            ]
        ),
        .target(
            name: "CardedCardScan",
            dependencies: ["CardedCore"],
            path: "CardedCardScan/CardedCardScan",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/CompiledModels")
            ]
        ),
        .target(
            name: "CardedUICore",
            dependencies: ["CardedCore"],
            path: "CardedUICore/CardedUICore",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
                .process("Resources/JSON")
            ]
        ),
        .target(
            name: "CardedFinancialConnections",
            dependencies: ["CardedCore", "CardedUICore"],
            path: "CardedFinancialConnections/CardedFinancialConnections",
            exclude: ["Info.plist"],
            resources: [
                .process("Info.plist"),
                .process("Resources/Images"),
            ]
        )
    ]
)

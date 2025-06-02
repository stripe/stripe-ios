// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "StripeAppKitExample",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "StripeAppKitExample",
            targets: ["StripeAppKitExample"]
        ),
    ],
    dependencies: [
        .package(path: "../..") // Reference to the main Stripe SDK
    ],
    targets: [
        .executableTarget(
            name: "StripeAppKitExample",
            dependencies: [
                .product(name: "StripePaymentSheet", package: "stripe-ios-mac"),
                .product(name: "StripeUICore", package: "stripe-ios-mac"),
            ],
            path: ".",
            sources: ["AppKitExampleApp.swift"]
        ),
    ]
)

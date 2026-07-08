// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacNativeExample",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(
            name: "MacNativeExample",
            targets: ["MacNativeExample"]
        ),
    ],
    dependencies: [
        .package(name: "Stripe", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "MacNativeExample",
            dependencies: [
                .product(name: "Stripe", package: "Stripe"),
                .product(name: "StripePaymentSheet", package: "Stripe"),
            ]
        ),
    ]
)

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
      type: .dynamic,
      targets: ["Stripe"]
    ),
  ],
  targets: [
    .target(
      name: "Stripe",
      dependencies: ["Stripe3DS2"],
      path: "Stripe",
        resources: [
          .process("Resources/Images"),
          .process("ExternalResources/Stripe3DS2.bundle"),
        ],
        publicHeadersPath: "PublicHeaders",
        cSettings: [
          .headerSearchPath("."),
          .headerSearchPath("PublicHeaders/Stripe"),
        ]
    ),
    .binaryTarget(
      name: "Stripe3DS2",
      url: "https://github.com/davidme-stripe/stripe-3ds2-ios-releases/releases/download/0.0.89/Stripe3DS2.xcframework.zip",
      checksum: "e7c69c260d6d417406c3e5bfb77d1180c71ca8a99bd9b654d5c8f80b05173532"),
  ]
)

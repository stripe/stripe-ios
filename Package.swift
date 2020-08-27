// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Stripe",
    defaultLocalization: "en",
    platforms: [
      .iOS(.v10)
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
      url: "https://github.com/davidme-stripe/stripe-3ds2-ios-releases/releases/download/0.0.222/Stripe3DS2.xcframework.zip",
      checksum: "adab590c5427c4c0c1adc224811730e7a8c15485d92772f45d7fc503c410154f"),
  ]
)

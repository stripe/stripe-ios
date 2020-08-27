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
      dependencies: ["Stripe3DS2", "ssl", "crypto"],
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
      name: "ssl",
      url: "https://github.com/davidme-stripe/stripe-3ds2-ios-releases/releases/download/0.0.9/ssl.xcframework.zip",
      checksum: "cb01ea8fe3f53c5c3311608490d67c8ad15cf13f5447d537b6fb5420769bce54"),
    .binaryTarget(
      name: "crypto",
      url: "https://github.com/davidme-stripe/stripe-3ds2-ios-releases/releases/download/0.0.9/crypto.xcframework.zip",
      checksum: "60ca6e56c6b1768749ae5f877499adc3c11847dc7bc4626f6533850d362413ed"),
    .binaryTarget(
      name: "Stripe3DS2",
      url: "https://github.com/davidme-stripe/stripe-3ds2-ios-releases/releases/download/0.0.9/Stripe3DS2.xcframework.zip",
      checksum: "15be05a4fc05b22eea351eb90aa135fec54059b174d4c0869713fcc04ad5b4af"),
  ]
)

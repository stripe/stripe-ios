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
        exclude: ["BuildConfigurations", "Info.plist", "PublicHeaders/Stripe/Stripe3DS2-Prefix.pch"],
        resources: [
          .process("Info.plist"),
          .process("Resources/Images"),
          .process("Resources/au_becs_bsb.json"),
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
      url: "https://github.com/stripe-ios/stripe-3ds2-ios-releases/releases/download/v19.9.9/Stripe3DS2.xcframework.zip",
      checksum: "2efb524df2480cb9d23dafe4b5e9cb0f91440e7d5d8b94fc1ea4c0a6c969f579"),
  ]
)

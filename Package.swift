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
    )
  ],
  targets: [
    .target(
      name: "Stripe",
      dependencies: ["Stripe3DS2"],
      path: "Stripe",
        exclude: ["BuildConfigurations", "Info.plist"],
        resources: [
          .process("Info.plist"),
          .process("Resources/Images"),
          .process("Resources/au_becs_bsb.json")
          .process("Resources/stripe_bundle.json")
        ]
    ),
    .target(
      name: "Stripe3DS2",
      path: "Stripe3DS2/Stripe3DS2",
      exclude: ["BuildConfigurations", "Info.plist", "Resources/CertificateFiles", "include/Stripe3DS2-Prefix.pch"],
      resources: [
          .process("Info.plist"),
          .process("Resources")
        ]
    )
  ]
)

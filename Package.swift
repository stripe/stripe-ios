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
        ]
    ),
    .binaryTarget(
      name: "Stripe3DS2",
      path: "InternalFrameworks/Stripe3DS2.xcframework"
    )
  ]
)

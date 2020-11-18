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
    .binaryTarget(
      name: "Stripe",
      url: "https://d37ugbyn3rpeym.cloudfront.net/terminal/payments-ios-releases/20.9.9-test4/Stripe.xcframework.zip",
      checksum: "579b045f8d20ce6f2b7d88d7791367ffa691fa4d4827df70541b33d6de48a870"
    )
  ]
)

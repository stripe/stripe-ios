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
      url: "https://d37ugbyn3rpeym.cloudfront.net/terminal/payments-ios-releases/21.1.0/Stripe.xcframework.zip",
      checksum: "336ef51f9f36a614badca4a33024ec001d8cdcedb2a290558b1a22e271567b73"
    )
  ]
)

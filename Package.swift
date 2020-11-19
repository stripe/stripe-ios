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
      url: "https://d37ugbyn3rpeym.cloudfront.net/terminal/payments-ios-releases/21.0.0/Stripe.xcframework.zip",
      checksum: "48e61e4b097323293c5c8688e17752e494936ec0a7e475faa1c9612f895a5912"
    )
  ]
)

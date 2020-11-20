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
      url: "https://d37ugbyn3rpeym.cloudfront.net/terminal/payments-ios-releases/21.0.1/Stripe.xcframework.zip",
      checksum: "d42ac188d64ae2106402f96e78eeebd00e3f9a0b037bb9f7ae8d9d69f95f5027"
    )
  ]
)

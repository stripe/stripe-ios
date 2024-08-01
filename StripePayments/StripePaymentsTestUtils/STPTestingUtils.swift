//
//  STPTestingUtils.swift
//  StripePaymentsTestUtils
//
//  Created by Eric Geniesse on 7/31/24.
//

import Foundation

func resolveResourcesDirectoryPath(
    relativePath: String
) -> String {
    // The goal is for `basePath` to be e.g. `~/stripe-ios/Stripe/StripeiOSTests`
    // A little gross/hardcoded (but it works fine); feel free to improve this...
    let testDirectoryName = "stripe-ios/StripePayments/StripePaymentsTestUtils"
    var basePath = "\(#file)"
    while !basePath.hasSuffix(testDirectoryName) {
        assert(
            basePath.contains(testDirectoryName),
            "Not in a subdirectory of \(testDirectoryName): \(#file)"
        )
        basePath = URL(fileURLWithPath: basePath).deletingLastPathComponent().path
    }
    return URL(fileURLWithPath: basePath)
        .appendingPathComponent("Resources")
        .appendingPathComponent(relativePath)
        .path
}

func networkMocksAreDisabled() -> Bool {
    return ProcessInfo.processInfo.environment["STP_NO_NETWORK_MOCKS"] != nil
}

//
//  STPFixtures.swift
//  StripeIssuing
//
//  Created by Shubham Agarwal on 12/17/25.
//

import Foundation

@testable import StripeIssuing
@_exported @testable import StripePaymentsObjcTestUtils

extension STPFixtures {
    /// A customer-scoped ephemeral key that expires in 100 seconds.
    class func ephemeralKey() -> STPEphemeralKey {
        var response = STPTestUtils.jsonNamed("EphemeralKey")
        let interval: TimeInterval = 100
        response!["expires"] = NSNumber(value: Date(timeIntervalSinceNow: interval).timeIntervalSince1970)
        return .decodedObject(fromAPIResponse: response)!
    }

    /// A customer-scoped ephemeral key that expires in 10 seconds.
    class func expiringEphemeralKey() -> STPEphemeralKey {
        var response = STPTestUtils.jsonNamed("EphemeralKey")
        let interval: TimeInterval = 10
        response!["expires"] = NSNumber(value: Date(timeIntervalSinceNow: interval).timeIntervalSince1970)
        return .decodedObject(fromAPIResponse: response)!
    }
}

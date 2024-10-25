//
//  STPSwiftFixtures.swift
//  StripeiOS Tests
//
//  Created by David Estes on 10/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

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

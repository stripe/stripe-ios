//
//  STPSwiftFixtures.swift
//  StripeiOS Tests
//
//  Created by David Estes on 10/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeIssuing
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

@_exported @testable import StripePaymentsTestUtils

extension STPFixtures {
    /// A customer-scoped ephemeral key that expires in 100 seconds.
    class func ephemeralKey() -> STPEphemeralKey {
        var response = STPTestUtils.jsonNamed("EphemeralKey")
        let interval: TimeInterval = 100
        response!["expires"] = NSNumber(value: Date(timeIntervalSinceNow: interval).timeIntervalSince1970)
        return .decodedObject(fromAPIResponse: response)!
    }
}

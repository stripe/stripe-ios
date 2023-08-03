//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodOXXOTests.swift
//  StripeiOS Tests
//
//  Created by Polo Li on 6/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils

//allResponseFields
var expectation = expectation(description: "Retrieve payment intent")
var oxxo = STPPaymentMethodOXXO.decodedObject(fromAPIResponse: json)

class STPPaymentMethodOXXOTests: XCTestCase {
    private(set) var oxxoJSON: [AnyHashable : Any]?

    func _retrieveOXXOJSON(_ completion: @escaping ([AnyHashable : Any]?) -> Void) {
        if let oxxoJSON {
            completion(oxxoJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingMEXPublishableKey)
            paymentIntent
            _unused
            //
            //
        }
    }
}

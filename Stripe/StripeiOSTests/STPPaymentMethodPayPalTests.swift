//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodPayPalTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils

//allResponseFields
var expectation = expectation(description: "Retrieve payment intent")
var payPal = STPPaymentMethodPayPal.decodedObject(fromAPIResponse: json)

class STPPaymentMethodPayPalTests: XCTestCase {
    var payPalJSON: [AnyHashable : Any]?

    func _retrievePayPalJSON(_ completion: @escaping ([AnyHashable : Any]?) -> Void) {
        if let payPalJSON {
            completion(payPalJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
            paymentIntent
            _unused
            //
            //
        }
    }
}
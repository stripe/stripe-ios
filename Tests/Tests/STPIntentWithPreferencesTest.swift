//
//  STPIntentWithPreferencesTest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPIntentWithPreferencesTest: XCTestCase {
    private let paymentIntentClientSecret =
        "pi_1H5J4RFY0qyl6XeWFTpgue7g_secret_1SS59M0x65qWMaX2wEB03iwVE"
    private let setupIntentClientSecret =
        "seti_1GGCuIFY0qyl6XeWVfbQK6b3_secret_GnoX2tzX2JpvxsrcykRSVna2lrYLKew"
    
    func testPaymentIntentWithPreferences() {
        let expectation = XCTestExpectation(description: "Retrieve Payment Intent With Preferences")
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        
        client.retrievePaymentIntentWithPreferences(withClientSecret: paymentIntentClientSecret) { result in
            switch result {
            case .success(let paymentIntentWithPreferences):
                expectation.fulfill()
                // Check for required PI fields
                XCTAssertEqual(paymentIntentWithPreferences.stripeId, "pi_1H5J4RFY0qyl6XeWFTpgue7g")
                XCTAssertEqual(paymentIntentWithPreferences.clientSecret, self.paymentIntentClientSecret)
                XCTAssertEqual(paymentIntentWithPreferences.amount, 2000)
                XCTAssertEqual(paymentIntentWithPreferences.currency, "usd")
                XCTAssertEqual(paymentIntentWithPreferences.status, STPPaymentIntentStatus.succeeded)
                XCTAssertEqual(paymentIntentWithPreferences.livemode, false)
                XCTAssertEqual(paymentIntentWithPreferences.paymentMethodTypes, STPPaymentMethod.types(from: ["card"]))
                // Check for ordered payment method types
                XCTAssertNotNil(paymentIntentWithPreferences.orderedPaymentMethodTypes)
                XCTAssertEqual(paymentIntentWithPreferences.orderedPaymentMethodTypes, [STPPaymentMethodType.card])
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testSetupIntentWithPreferences() {
        let expectation = XCTestExpectation(description: "Retrieve Setup Intent With Preferences")
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        
        client.retrieveSetupIntentWithPreferences(withClientSecret: setupIntentClientSecret) { result in
            switch result {
            case .success(let setupIntentWithPreferences):
                expectation.fulfill()
                // Check required SI fields
                XCTAssertEqual(setupIntentWithPreferences.stripeID, "seti_1GGCuIFY0qyl6XeWVfbQK6b3")
                XCTAssertEqual(setupIntentWithPreferences.clientSecret, self.setupIntentClientSecret)
                XCTAssertEqual(setupIntentWithPreferences.status, .requiresPaymentMethod)
                XCTAssertEqual(setupIntentWithPreferences.paymentMethodTypes, STPPaymentMethod.types(from: ["card"]))
                // Check for ordered payment method types
                XCTAssertNotNil(setupIntentWithPreferences.orderedPaymentMethodTypes)
                XCTAssertEqual(setupIntentWithPreferences.orderedPaymentMethodTypes, [STPPaymentMethodType.card])
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }
}

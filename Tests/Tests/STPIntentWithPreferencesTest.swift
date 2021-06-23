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
                XCTAssertNotNil(paymentIntentWithPreferences.paymentIntent)
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
                XCTAssertNotNil(setupIntentWithPreferences.setupIntent)
                XCTAssertNotNil(setupIntentWithPreferences.orderedPaymentMethodTypes)
                XCTAssertEqual(setupIntentWithPreferences.orderedPaymentMethodTypes, [STPPaymentMethodType.card])
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }
}

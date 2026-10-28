//
//  STPPaymentMethodEPSTests.swift
//  StripeiOS Tests
//
//  Created by Shengwei Wu on 5/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
import StripeCoreTestUtils

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPPaymentMethodEPSTests: STPNetworkStubbingTestCase {
    private(set) var epsJSON: [AnyHashable: Any]?

    func _retrieveEPSJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let epsJSON = epsJSON {
            completion(epsJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
            client.retrievePaymentIntent(
                withClientSecret: "pi_1Gj0rqFY0qyl6XeWrug30CPz_secret_tKyf8QOKtiIrE3NSEkWCkBbyy",
                expand: ["payment_method"]
            ) { [self] paymentIntent, _ in
                epsJSON = paymentIntent?.paymentMethod?.eps?.allResponseFields
                completion(epsJSON ?? [:])
            }
        }
    }

    func testCorrectParsing() {
        let jsonExpectation = XCTestExpectation(description: "Fetch EPS JSON")
        _retrieveEPSJSON({ json in
            let eps = STPPaymentMethodEPS.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(eps, "Failed to decode JSON")
            jsonExpectation.fulfill()
        })
        wait(for: [jsonExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
}

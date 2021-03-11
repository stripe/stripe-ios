//
//  STPPaymentHandlerTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class STPPaymentHandlerTests: XCTestCase {
    
    func testCanPresentErrorsAreReported() {
        let createPaymentIntentExpectation = expectation(
            description: "createPaymentIntentExpectation")
        var retrievedClientSecret: String? = nil
        STPTestingAPIClient.shared().createPaymentIntent(withParams: nil) {
            (createdPIClientSecret, error) in
            if let createdPIClientSecret = createdPIClientSecret {
                retrievedClientSecret = createdPIClientSecret
                createPaymentIntentExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        wait(for: [createPaymentIntentExpectation], timeout: 8)  // STPTestingNetworkRequestTimeout
        guard let clientSecret = retrievedClientSecret,
              let currentYear = Calendar.current.dateComponents([.year], from: Date()).year
        else {
            XCTFail()
            return
        }

        let expiryYear = NSNumber(value: currentYear + 2)
        let expiryMonth = NSNumber(1)

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4000000000003220"
        cardParams.expYear = expiryYear
        cardParams.expMonth = expiryMonth
        cardParams.cvc = "123"

        let address = STPPaymentMethodAddress()
        address.postalCode = "12345"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams.paramsWith(
            card: cardParams, billingDetails: billingDetails, metadata: nil)

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPAPIClient.shared.publishableKey = "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6" // STPTestingDefaultPublishableKey

        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        STPPaymentHandler.shared().checkCanPresentInTest = true
        STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            XCTAssertTrue(status == .failed)
            XCTAssertNotNil(paymentIntent)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.userInfo[STPError.errorMessageKey] as? String, "authenticationPresentingViewController is not in the window hierarchy. You should probably return the top-most view controller instead.")
            paymentHandlerExpectation.fulfill()
        }
        // 2*STPTestingNetworkRequestTimeout payment handler needs to make an ares for this
        // test in addition to fetching the payment intent
        wait(for: [paymentHandlerExpectation], timeout: 2*8)
    }

}

extension STPPaymentHandlerTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
    
    
}

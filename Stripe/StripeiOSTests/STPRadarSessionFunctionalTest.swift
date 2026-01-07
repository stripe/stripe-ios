//
//  STPRadarSessionFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPRadarSessionFunctionalTest: XCTestCase {
    func testCreateWithoutInitialFraudDetection() {
        // When fraudDetectionData is empty...
        FraudDetectionData.shared.reset()

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let exp1 = expectation(description: "Create RadarSession")
        client.createRadarSession { session, error in
            // ...creates a Radar Session
            XCTAssertNil(error)
            guard let session = session else {
                XCTFail()
                return
            }
            XCTAssertTrue(session.id.count > 0)
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        // Now that fraudDetectionData is populated...
        XCTAssertNotNil(FraudDetectionData.shared.sid)
        XCTAssertNotNil(FraudDetectionData.shared.muid)
        XCTAssertNotNil(FraudDetectionData.shared.guid)

        let exp2 = expectation(description: "Create RadarSession again")
        client.createRadarSession { session, error in
            // ...still creates a Radar Session
            XCTAssertNil(error)
            guard let session = session else {
                XCTFail()
                return
            }
            XCTAssertTrue(session.id.count > 0)
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCreateSavedPaymentMethodRadarSession() {
        // Create a payment method first
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2035
        cardParams.cvc = "123"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "test@example.com"

        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)

        let exp1 = expectation(description: "Create PaymentMethod")
        var paymentMethodId: String?
        client.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
            XCTAssertNil(error)
            guard let paymentMethod = paymentMethod else {
                XCTFail()
                return
            }
            paymentMethodId = paymentMethod.stripeId
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        // Now create a saved payment method radar session
        guard let pmId = paymentMethodId else {
            XCTFail("Payment method ID is nil")
            return
        }

        let exp2 = expectation(description: "Create Saved PaymentMethod RadarSession")
        client.createSavedPaymentMethodRadarSession(paymentMethodId: pmId) { session, error in
            XCTAssertNil(error)
            guard let session = session else {
                XCTFail()
                return
            }
            XCTAssertTrue(session.id.count > 0)
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}

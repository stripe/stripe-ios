//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodNetBankingParamsTest.swift
//  StripeiOS
//
//  Created by Anirudh Bhargava on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils

class STPPaymentMethodNetBankingParamsTests: XCTestCase {
    func testCreateNetBankingPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingINPublishableKey)
        let netbankingParams = STPPaymentMethodNetBankingParams()
        netbankingParams.bank = "icici"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            netBanking: netbankingParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method NetBanking create")
        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()
            XCTAssertNil(error)
            XCTAssertNotNil(Int(paymentMethod ?? 0))
            XCTAssertNotNil(paymentMethod?.stripeId ?? 0)
            XCTAssertNotNil(paymentMethod?.created ?? 0)
            XCTAssertFalse(paymentMethod?.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type ?? 0, Int(STPPaymentMethodTypeNetBanking))
            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails.name, "Jenny Rosen")
            // UPI Details
            XCTAssertNotNil(paymentMethod?.netBanking ?? 0)
            XCTAssertEqual(paymentMethod?.netBanking.bank, "icici")
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}

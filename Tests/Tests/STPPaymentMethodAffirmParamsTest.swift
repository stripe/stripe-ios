//
//  STPPaymentMethodAffirmParamsTest.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCoreTestUtils
@testable import Stripe

class STPPaymentMethodAffirmParamsTests: XCTestCase {

    func testCreateAffirmPaymentMethod() throws {
        let affirmParams = STPPaymentMethodAffirmParams()

        let params = STPPaymentMethodParams(
            affirm: affirmParams,
            metadata: nil)

        let exp = expectation(description: "Payment Method Affirm create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .affirm, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.affirm, "The `affirm` property must be populated");
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}

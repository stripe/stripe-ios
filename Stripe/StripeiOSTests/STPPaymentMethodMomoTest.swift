//
//  STPPaymentMethodMomoTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodMomoTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            momo: STPPaymentMethodMomoParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "momo")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_momo",
            "created": 1_725_000_000,
            "type": "momo",
            "momo": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .momo)
        XCTAssertNotNil(paymentMethod?.momo)
    }

    func testTypeInitializerCreatesMomoParams() {
        let params = STPPaymentMethodParams(type: .momo)

        XCTAssertNotNil(params.momo)
    }

    func testProcessingCompletesAuthorizedPaymentFlow() {
        // MoMo's web spec finishes the customer flow when authorization returns processing.
        XCTAssertTrue(STPPaymentHandler._isProcessingIntentSuccess(for: .momo))
    }
}

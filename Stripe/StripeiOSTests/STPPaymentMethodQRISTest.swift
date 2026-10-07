//
//  STPPaymentMethodQRISTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodQRISTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            qris: STPPaymentMethodQRISParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "qris")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_qris",
            "created": 1_725_000_000,
            "type": "qris",
            "qris": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .qris)
        XCTAssertNotNil(paymentMethod?.qris)
    }

    func testTypeInitializerCreatesQRISParams() {
        let params = STPPaymentMethodParams(type: .qris)

        XCTAssertNotNil(params.qris)
    }
}

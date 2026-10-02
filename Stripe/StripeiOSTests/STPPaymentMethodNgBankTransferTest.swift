//
//  STPPaymentMethodNgBankTransferTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodNgBankTransferTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            ngBankTransfer: STPPaymentMethodNgBankTransferParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "ng_bank_transfer")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_ng_bank_transfer",
            "created": 1_725_000_000,
            "type": "ng_bank_transfer",
            "ng_bank_transfer": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .ngBankTransfer)
        XCTAssertNotNil(paymentMethod?.ngBankTransfer)
    }

    func testTypeInitializerCreatesNgBankTransferParams() {
        let params = STPPaymentMethodParams(type: .ngBankTransfer)

        XCTAssertNotNil(params.ngBankTransfer)
    }
}

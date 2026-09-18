//
//  STPPaymentMethodNgWalletTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodNgWalletTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            ngWallet: STPPaymentMethodNgWalletParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "ng_wallet")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_ng_wallet",
            "created": 1_725_000_000,
            "type": "ng_wallet",
            "ng_wallet": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .ngWallet)
        XCTAssertNotNil(paymentMethod?.ngWallet)
    }

    func testTypeInitializerCreatesNgWalletParams() {
        let params = STPPaymentMethodParams(type: .ngWallet)

        XCTAssertNotNil(params.ngWallet)
    }
}

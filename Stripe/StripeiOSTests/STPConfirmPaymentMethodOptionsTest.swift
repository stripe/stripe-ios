//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConfirmPaymentMethodOptionsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable@_spi(InternalOnlyAPI) @_spi(KlarnaSDKPrivatePreview) import StripePayments
import XCTest

class STPConfirmPaymentMethodOptionsTest: XCTestCase {
    func testCardOptions() {
        let paymentMethodOptions = STPConfirmPaymentMethodOptions()

        XCTAssertNil(paymentMethodOptions.cardOptions, "Default card value should be nil.")

        let cardOptions = STPConfirmCardOptions()
        paymentMethodOptions.cardOptions = cardOptions
        XCTAssertEqual(paymentMethodOptions.cardOptions, cardOptions, "Should hold reference to set cardOptions.")
    }

    func testKlarnaOptions() {
        let klarnaOptions = STPConfirmKlarnaOptions(
            interoperabilityToken: "interoperability_token",
            partnerConfirmationToken: "partner_confirmation_token"
        )

        let paymentMethodOptions = STPConfirmPaymentMethodOptions(klarnaOptions: klarnaOptions)

        XCTAssertEqual(paymentMethodOptions.klarnaOptions, klarnaOptions)
    }

    func testKlarnaOptionsFormEncoding() {
        let klarnaOptions = STPConfirmKlarnaOptions(
            interoperabilityToken: "interoperability_token",
            partnerConfirmationToken: "partner_confirmation_token"
        )
        let paymentMethodOptions = STPConfirmPaymentMethodOptions(klarnaOptions: klarnaOptions)

        let encoded = STPFormEncoder.dictionary(forObject: paymentMethodOptions)
        let expected = [
            "payment_method_options": [
                "klarna": [
                    "interoperability_token": "interoperability_token",
                    "partner_confirmation_token": "partner_confirmation_token",
                ],
            ],
        ]

        XCTAssertEqual(encoded as NSDictionary, expected as NSDictionary)
    }

    func testFormEncoding() {
        let propertyToFieldMap = STPConfirmPaymentMethodOptions.propertyNamesToFormFieldNamesMapping()
        let expected: [AnyKeyPath: String] = [
            \STPConfirmPaymentMethodOptions.cardOptions: "card",
            \STPConfirmPaymentMethodOptions.alipayOptions: "alipay",
            \STPConfirmPaymentMethodOptions.blikOptions: "blik",
            \STPConfirmPaymentMethodOptions.weChatPayOptions: "wechat_pay",
            \STPConfirmPaymentMethodOptions.usBankAccountOptions: "us_bank_account",
            \STPConfirmPaymentMethodOptions.konbiniOptions: "konbini",
            \STPConfirmPaymentMethodOptions.klarnaOptions: "klarna",
            \STPConfirmPaymentMethodOptions.linkOptions: "link",
        ]

        XCTAssertEqual(propertyToFieldMap, expected)
    }

    func testAlipayOptionsFormEncoding() {
        let propertyToFieldMap = STPConfirmAlipayOptions.propertyNamesToFormFieldNamesMapping()
        let expected: [AnyKeyPath: String] = [
            \STPConfirmAlipayOptions.currency: "currency",
            \STPConfirmAlipayOptions.appBundleID: "app_bundle_id",
            \STPConfirmAlipayOptions.appVersionKey: "app_version_key",
            \STPConfirmAlipayOptions.setupFutureUsageRawString: "setup_future_usage",
        ]

        XCTAssertEqual(propertyToFieldMap, expected)
    }
}

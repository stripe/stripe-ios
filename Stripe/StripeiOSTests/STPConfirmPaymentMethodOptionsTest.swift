//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConfirmPaymentMethodOptionsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) @_spi(KlarnaSDKPrivatePreview) import StripePayments

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
        let expected = [
            "cardOptions": "card",
            "alipayOptions": "alipay",
            "blikOptions": "blik",
            "weChatPayOptions": "wechat_pay",
            "usBankAccountOptions": "us_bank_account",
            "konbiniOptions": "konbini",
            "klarnaOptions": "klarna",
            "linkOptions": "link",
        ]

        XCTAssertEqual(propertyToFieldMap, expected)
    }
}

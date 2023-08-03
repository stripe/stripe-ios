//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConfirmPaymentMethodOptionsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

class STPConfirmPaymentMethodOptionsTest: XCTestCase {
    func testCardOptions() {
        let paymentMethodOptions = STPConfirmPaymentMethodOptions()

        XCTAssertNil(paymentMethodOptions.cardOptions)

        let cardOptions = STPConfirmCardOptions()
        paymentMethodOptions.cardOptions = cardOptions
        XCTAssertEqual(paymentMethodOptions.cardOptions, cardOptions.rawValue)
    }

    func testFormEncoding() {
        let propertyToFieldMap = STPConfirmPaymentMethodOptions.propertyNamesToFormFieldNamesMapping()
        let expected = [
            "cardOptions": "card",
            "alipayOptions": "alipay",
            "blikOptions": "blik",
            "weChatPayOptions": "wechat_pay",
            "usBankAccountOptions": "us_bank_account",
        ]

        XCTAssertEqual(propertyToFieldMap, expected)
    }
}
//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPApplePayPaymentOptionTest.m
//  Stripe
//
//  Created by Joey Dong on 7/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

class STPApplePayPaymentOptionTest: XCTestCase {
    // MARK: - STPPaymentOption Tests

    func testImage() {
        let applePay = STPApplePayPaymentOption()
        XCTAssertNotNil(applePay.image)
    }

    func testTemplateImage() {
        let applePay = STPApplePayPaymentOption()
        XCTAssertNotNil(applePay.templateImage)
    }

    func testLabel() {
        let applePay = STPApplePayPaymentOption()
        XCTAssertEqual(applePay.label, "Apple Pay")
    }

    // MARK: - Equality Tests

    func testApplePayEquals() {
        let applePay1 = STPApplePayPaymentOption()
        let applePay2 = STPApplePayPaymentOption()

        XCTAssertEqual(applePay1, applePay1)
        XCTAssertEqual(applePay1, applePay2)

        XCTAssertEqual(applePay1.hash, applePay1.hash)
        XCTAssertEqual(applePay1.hash, applePay2.hash)
    }
}

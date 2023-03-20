//
//  STPPaymentMethodCardParamsTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 2/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPPaymentMethodCardParamsTest: XCTestCase {
    func testEqualityCheck() {
        let params1 = STPPaymentMethodCardParams()
        params1.number = "4242424242424242"
        params1.cvc = "123"
        params1.expYear = 22
        params1.expMonth = 12
        let params2 = STPPaymentMethodCardParams()
        params2.number = "4242424242424242"
        params2.cvc = "123"
        params2.expYear = 22
        params2.expMonth = 12
        XCTAssertEqual(params1, params2)
        params1.additionalAPIParameters["test"] = "bla"
        XCTAssertNotEqual(params1, params2)
        params2.additionalAPIParameters["test"] = "bla"
        XCTAssertEqual(params1, params2)
    }
    
    func testCardParamsFromPaymentMethodParams() {
        let pmCardParams = STPPaymentMethodCardParams()
        pmCardParams.number = "4242424242424242"
        pmCardParams.cvc = "123"
        pmCardParams.expYear = 22
        pmCardParams.expMonth = 12
        let addressParams = STPPaymentMethodBillingDetails()
        addressParams.name = "Tester McTestington"
        let address = STPPaymentMethodAddress()
        address.line1 = "123 Fake St"
        address.line2 = "Apt 123"
        address.city = "City"
        address.state = "NY"
        address.country = "US"
        address.postalCode = "12345"
        addressParams.address = address
        let pmParams = STPPaymentMethodParams(card: pmCardParams, billingDetails: addressParams, metadata: nil)
        let cardParams = STPCardParams(paymentMethodParams: pmParams)
        XCTAssertEqual(cardParams.number, "4242424242424242")
        XCTAssertEqual(cardParams.cvc, "123")
        XCTAssertEqual(cardParams.expYear, 22)
        XCTAssertEqual(cardParams.expMonth, 12)
        XCTAssertEqual(cardParams.name, "Tester McTestington")
        XCTAssertEqual(cardParams.addressLine1, "123 Fake St")
        XCTAssertEqual(cardParams.addressLine2, "Apt 123")
        XCTAssertEqual(cardParams.addressCity, "City")
        XCTAssertEqual(cardParams.addressState, "NY")
        XCTAssertEqual(cardParams.addressCountry, "US")
        XCTAssertEqual(cardParams.addressZip, "12345")
    }
}

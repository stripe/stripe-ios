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
}

//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodCardWalletVisaCheckoutTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodCardWalletVisaCheckoutTest: XCTestCase {
    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["card"]["wallet"]["visa_checkout"] as? [AnyHashable : Any]
        let visaCheckout = STPPaymentMethodCardWalletVisaCheckout.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(Int(visaCheckout ?? 0))
        XCTAssertEqual(visaCheckout?.name, "Jenny")
        XCTAssertEqual(visaCheckout?.email, "jenny@example.com")
        XCTAssertNotNil(visaCheckout?.billingAddress ?? 0)
        XCTAssertNotNil(visaCheckout?.shippingAddress ?? 0)
    }
}
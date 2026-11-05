//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodCardWalletVisaCheckoutTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import StripePayments
import StripePaymentsTestUtils
import XCTest

class STPPaymentMethodCardWalletVisaCheckoutTest: XCTestCase {
    func testDecodedObjectFromAPIResponseMapping() {
        let response = ((STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)["card"] as! [AnyHashable: Any])["wallet"] as! [AnyHashable: Any])["visa_checkout"] as? [AnyHashable: Any]
        let visaCheckout = STPPaymentMethodCardWalletVisaCheckout.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(visaCheckout)
        XCTAssertEqual(visaCheckout?.name, "Jenny")
        XCTAssertEqual(visaCheckout?.email, "jenny@example.com")
        XCTAssertNotNil(visaCheckout?.billingAddress)
        XCTAssertNotNil(visaCheckout?.shippingAddress)
    }
}

//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodCardWalletMasterpassTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodCardWalletMasterpassTest: XCTestCase {
    func testDecodedObjectFromAPIResponseMapping() {
        // We reuse the visa checkout JSON because it's identical to the masterpass version
        let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["card"]["wallet"]["visa_checkout"] as? [AnyHashable : Any]
        let masterpass = STPPaymentMethodCardWalletMasterpass.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(Int(masterpass ?? 0))
        XCTAssertEqual(masterpass?.name, "Jenny")
        XCTAssertEqual(masterpass?.email, "jenny@example.com")
        XCTAssertNotNil(masterpass?.billingAddress ?? 0)
        XCTAssertNotNil(masterpass?.shippingAddress ?? 0)
    }
}

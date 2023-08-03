//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodAddressTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodAddressTest: XCTestCase {
    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["billing_details"]["address"] as? [AnyHashable : Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodAddress.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPPaymentMethodAddress.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["billing_details"]["address"]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["billing_details"]["address"] as? [AnyHashable : Any]
        let address = STPPaymentMethodAddress.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(address?.city, "München")
        XCTAssertEqual(address?.country, "DE")
        XCTAssertEqual(address?.postalCode, "80337")
        XCTAssertEqual(address?.line1, "Marienplatz")
        XCTAssertEqual(address?.line2, "8")
        XCTAssertEqual(address?.state, "Bayern")
    }
}

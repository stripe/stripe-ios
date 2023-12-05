//
//  STPPaymentMethodDisplayBrandTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 11/30/23.
//

import Foundation

import XCTest

class STPPaymentMethodDisplayBrandTest: XCTestCase {
    func testDecodedObjectFromAPIResponse() {
        let response = [
            "type": "visa"
        ]

        let displayBrand = STPPaymentMethodDisplayBrand.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(displayBrand)
        XCTAssertEqual(displayBrand?.type, "visa")
    }
}

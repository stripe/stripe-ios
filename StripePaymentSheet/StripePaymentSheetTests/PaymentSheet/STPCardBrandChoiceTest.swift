//
//  STPCardBrandChoiceTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/29/23.
//

import Foundation
@testable import StripePaymentSheet
import XCTest

class STPCardBrandChoiceTest: XCTestCase {

    func testDecodingHappy() throws {
        let responseDict = ["eligible": true]

        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: responseDict))
        XCTAssertEqual(true, cardBranceChoice.eligible)
    }

    func testDecodingNil() throws {
        XCTAssertNil(STPCardBrandChoice.decodedObject(fromAPIResponse: nil))
    }

    func testDecodingEmpty() throws {
        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: [:]))
        XCTAssertEqual(false, cardBranceChoice.eligible)
    }
}

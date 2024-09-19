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
        let responseDict: [String : Any] = ["eligible": true, "preferred_networks": ["cartes_bancaires"], "supported_cobranded_networks" : ["cartes_bancaires": true]]

        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: responseDict))
        XCTAssertEqual(true, cardBranceChoice.eligible)
        XCTAssertEqual(["cartes_bancaires"], cardBranceChoice.preferredNetworks)
        XCTAssertEqual(["cartes_bancaires": true], cardBranceChoice.supportedCobrandedNetworks)
    }

    func testDecodingNil() throws {
        XCTAssertNil(STPCardBrandChoice.decodedObject(fromAPIResponse: nil))
    }

    func testDecodingEmpty() throws {
        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: [:]))
        XCTAssertEqual(false, cardBranceChoice.eligible)
    }
}

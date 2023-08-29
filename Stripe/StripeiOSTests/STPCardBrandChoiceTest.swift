//
//  STPCardBrandChoiceTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/29/23.
//

import Foundation
@_spi(STP) import StripePayments
import XCTest

class STPCardBrandChoiceTest: XCTestCase {
    func testDecodingHappy() throws {
        let responseDict = ["eligible": true,
                            "preferred_networks": ["cartes_bancaires", "visa"], ] as [String: Any]

        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: responseDict))
        XCTAssertEqual(true, cardBranceChoice.eligible)
        XCTAssertEqual(["cartes_bancaires", "visa"], cardBranceChoice.preferredNetworks)
    }

    func testDecodingMissingNetworks() throws {
        let responseDict = ["eligible": true] as [String: Any]

        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: responseDict))
        XCTAssertEqual(true, cardBranceChoice.eligible)
        XCTAssertNil(cardBranceChoice.preferredNetworks)
    }

    func testDecodingMissingEligible() throws {
        let responseDict = ["preferred_networks": ["cartes_bancaires", "visa"]] as [String: Any]

        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: responseDict))
        XCTAssertEqual(false, cardBranceChoice.eligible)
        XCTAssertEqual(["cartes_bancaires", "visa"], cardBranceChoice.preferredNetworks)
    }

    func testDecodingNil() throws {
        XCTAssertNil(STPCardBrandChoice.decodedObject(fromAPIResponse: nil))
    }

    func testDecodingEmpty() throws {
        let cardBranceChoice = try XCTUnwrap(STPCardBrandChoice.decodedObject(fromAPIResponse: [:]))
        XCTAssertEqual(false, cardBranceChoice.eligible)
        XCTAssertNil(cardBranceChoice.preferredNetworks)
    }
}

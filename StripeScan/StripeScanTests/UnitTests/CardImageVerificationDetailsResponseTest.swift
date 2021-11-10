//
//  CardImageVerificationDetailsResponseTest.swift
//  CardVerifyTests
//
//  Created by Jaime Park on 9/16/21.
//

import XCTest
@testable import StripeScan

class CardImageVerificationDetailsResponseTest: XCTestCase {
    func testCaredImageVerificationDetailsDecode_Success() throws {
        let initializeClientJSONData = try TestData.initializeClient.dataFromJSONFile()
        let response = try JSONDecoder().decode(CardImageVerificationDetailsResponse.self, from: initializeClientJSONData)
        XCTAssertEqual(response.expectedCard.last4, "4242")
        XCTAssertEqual(response.expectedCard.issuer, "Visa")
    }
}

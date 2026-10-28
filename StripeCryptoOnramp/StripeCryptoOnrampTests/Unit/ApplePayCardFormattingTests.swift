//
//  ApplePayCardFormattingTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 10/14/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeApplePay
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCryptoOnramp
import XCTest

final class ApplePayCardFormattingTests: XCTestCase {
    func testCardFundingDescriptions() throws {
        let creditCard = try makeCard(funding: "credit")
        XCTAssertEqual(String.Localized.redactedCardDetails(using: creditCard), "Visa Credit •••• 4242")

        let debitCard = try makeCard(funding: "debit")
        XCTAssertEqual(String.Localized.redactedCardDetails(using: debitCard), "Visa Debit •••• 4242")

        let prepaidCard = try makeCard(funding: "prepaid")
        XCTAssertEqual(String.Localized.redactedCardDetails(using: prepaidCard), "Visa Prepaid •••• 4242")

        let unknownFundingCard = try makeCard(funding: "unknown")
        XCTAssertEqual(String.Localized.redactedCardDetails(using: unknownFundingCard), "Visa Card •••• 4242")

        let futureFundingCard = try makeCard(funding: "future_funding")
        XCTAssertEqual(String.Localized.redactedCardDetails(using: futureFundingCard), "Visa Card •••• 4242")
    }

    func testMissingFundingFallsBackToCard() throws {
        let card = try makeCard(funding: nil)
        XCTAssertEqual(String.Localized.redactedCardDetails(using: card), "Visa Card •••• 4242")
    }

    func testMissingLast4ReturnsNil() throws {
        let card = try makeCard(funding: "credit", last4: nil)
        XCTAssertNil(String.Localized.redactedCardDetails(using: card))
    }

    private func makeCard(funding: String?, last4: String? = "4242") throws -> StripeAPI.PaymentMethod.Card {
        var json: [String: Any] = [
            "brand": "visa",
            "exp_month": 12,
            "exp_year": 2030,
        ]
        json["funding"] = funding
        json["last4"] = last4
        let data = try JSONSerialization.data(withJSONObject: json)
        return try StripeJSONDecoder.decode(jsonData: data)
    }
}

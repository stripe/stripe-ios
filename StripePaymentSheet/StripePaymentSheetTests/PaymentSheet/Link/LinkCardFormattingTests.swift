//
//  LinkCardFormattingTests.swift
//  StripePaymentSheetTests
//
//  Created by Michael Liberatore on 10/14/26.
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class LinkCardFormattingTests: XCTestCase {
    func testCardFormattingMatchesLinkController() {
        let creditDetails = makePaymentDetails(funding: .credit, nickname: nil)
        let creditFormatted = LinkController.formattedCardDetails(brand: .visa, funding: "credit", last4: "4242")
        XCTAssertEqual(creditDetails.linkPaymentDetailsFormattedString, creditFormatted)

        let debitDetails = makePaymentDetails(funding: .debit, nickname: nil)
        let debitFormatted = LinkController.formattedCardDetails(brand: .visa, funding: "debit", last4: "4242")
        XCTAssertEqual(debitDetails.linkPaymentDetailsFormattedString, debitFormatted)

        let prepaidDetails = makePaymentDetails(funding: .prepaid, nickname: nil)
        let prepaidFormatted = LinkController.formattedCardDetails(brand: .visa, funding: "prepaid", last4: "4242")
        XCTAssertEqual(prepaidDetails.linkPaymentDetailsFormattedString, prepaidFormatted)

        let unknownDetails = makePaymentDetails(funding: .unparsable, nickname: nil)
        let unknownFormatted = LinkController.formattedCardDetails(brand: .visa, funding: "", last4: "4242")
        XCTAssertEqual(unknownDetails.linkPaymentDetailsFormattedString, unknownFormatted)
    }

    func testCardFormattingPreservesNickname() {
        let details = makePaymentDetails(funding: .credit, nickname: "Personal card")
        XCTAssertEqual(details.linkPaymentDetailsFormattedString, "Personal card •••• 4242")
    }

    private func makePaymentDetails(funding: ConsumerPaymentDetails.Details.Card.Funding, nickname: String?) -> ConsumerPaymentDetails {
        ConsumerPaymentDetails(
            stripeID: "",
            details: .card(card: .init(
                expiryYear: 2030,
                expiryMonth: 12,
                brand: "visa",
                networks: [],
                last4: "4242",
                funding: funding,
                checks: nil
            )),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nickname,
            isDefault: false
        )
    }
}

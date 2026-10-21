//
//  LinkPaymentMethodPreviewTests.swift
//  StripePaymentSheetTests
//

import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

final class LinkPaymentMethodPreviewTests: XCTestCase {
    @MainActor
    func testCardFundingAndDisplayComeFromSameSelection() {
        let cases: [(ConsumerPaymentDetails.Details.Card.Funding, STPCardFundingType)] = [
            (.debit, .debit), (.credit, .credit), (.prepaid, .prepaid), (.unparsable, .other),
        ]
        // Saved and newly entered cards share the same consumer payment details representation.
        for isDefault in [true, false] {
            for (funding, expected) in cases {
                let selection = paymentDetails(.card(card: card(funding: funding)), isDefault: isDefault)
                let preview = LinkController.PaymentMethodPreview(paymentDetails: selection, icon: UIImage(), label: "Link")
                guard case .card(let actualFunding, let brand, let last4) = preview.instrumentDetails else {
                    return XCTFail("Expected card metadata")
                }
                XCTAssertEqual(actualFunding, expected)
                XCTAssertEqual(brand, .visa)
                XCTAssertEqual(last4, "4242")
                XCTAssertEqual(preview.paymentMethodType, .card)
                XCTAssertEqual(preview.sublabel, selection.linkPaymentDetailsFormattedString)
            }
        }
    }

    @MainActor
    func testUnknownBrandRemainsACard() {
        let selection = paymentDetails(.card(card: card(funding: .unparsable, brand: "unrecognized")))
        let preview = LinkController.PaymentMethodPreview(paymentDetails: selection, icon: UIImage(), label: "Link")
        guard case .card(let funding, let brand, _) = preview.instrumentDetails else {
            return XCTFail("Expected card metadata")
        }
        XCTAssertEqual(funding, .other)
        XCTAssertEqual(brand, .unknown)
    }

    @MainActor
    func testSwitchingCardBankCardPreservesEarlierSnapshots() {
        // Given a selected card and its copied preview
        var selection = paymentDetails(.card(card: card(funding: .debit)))
        let first = LinkController.PaymentMethodPreview(paymentDetails: selection, icon: UIImage(), label: "Link")

        // When the selection changes to a bank and then a different card
        selection = paymentDetails(.bankAccount(bankAccount: .init(iconCode: nil, name: "Test Bank", last4: "6789", country: "COUNTRY_US")))
        let bank = LinkController.PaymentMethodPreview(paymentDetails: selection, icon: UIImage(), label: "Link")
        XCTAssertEqual(bank.sublabel, selection.linkPaymentDetailsFormattedString)
        selection = paymentDetails(.card(card: card(funding: .credit, last4: "4444")))
        let latest = LinkController.PaymentMethodPreview(paymentDetails: selection, icon: UIImage(), label: "Link")

        // Then every preview retains only its own instrument's metadata
        guard case .card(let firstFunding, _, let firstLast4) = first.instrumentDetails,
              case .bankAccount(let bankLast4) = bank.instrumentDetails,
              case .card(let latestFunding, _, let latestLast4) = latest.instrumentDetails else {
            return XCTFail("Expected disjoint instrument summaries")
        }
        XCTAssertEqual(firstFunding, .debit)
        XCTAssertEqual(firstLast4, "4242")
        XCTAssertEqual(bank.paymentMethodType, .bankAccount)
        XCTAssertEqual(bankLast4, "6789")
        XCTAssertEqual(latestFunding, .credit)
        XCTAssertEqual(latestLast4, "4444")
        XCTAssertTrue(first.sublabel?.contains("4242") == true)
        XCTAssertTrue(latest.sublabel?.contains("4444") == true)
    }

    @MainActor
    func testGenericPresentationDoesNotImplyCardMetadata() {
        let selection = paymentDetails(.generic(rawValue: "UNRECOGNIZED"))
        let preview = LinkController.PaymentMethodPreview(paymentDetails: selection, icon: UIImage(), label: "Link")
        XCTAssertEqual(preview.paymentMethodType, .card)
        XCTAssertNil(preview.instrumentDetails)
        XCTAssertEqual(preview.sublabel, selection.linkPaymentDetailsFormattedString)
    }

    private func card(funding: ConsumerPaymentDetails.Details.Card.Funding, brand: String = "visa", last4: String = "4242") -> ConsumerPaymentDetails.Details.Card {
        .init(expiryYear: 2099, expiryMonth: 12, brand: brand, networks: [], last4: last4, funding: funding, checks: nil)
    }

    private func paymentDetails(_ details: ConsumerPaymentDetails.Details, isDefault: Bool = false) -> ConsumerPaymentDetails {
        .init(stripeID: "test_selection", details: details, billingAddress: nil, billingEmailAddress: nil, nickname: nil, isDefault: isDefault)
    }
}

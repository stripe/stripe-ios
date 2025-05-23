//
//  VerticalPaymentMethodListViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/17/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class VerticalPaymentMethodListViewControllerTest: XCTestCase {
    var shouldSelectPaymentMethodReturnValue: Bool = false

    func testCurrentSelection() {
        let savedPaymentMethod = STPPaymentMethod._testCard()
        // Given a list view with a saved card...
        let sut = VerticalPaymentMethodListViewController(
            initialSelection: .saved(
                paymentMethod: savedPaymentMethod
            ),
            savedPaymentMethods: [savedPaymentMethod],
            paymentMethodTypes: [.stripe(.card)],
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "USD",
            amount: 1099,
            incentive: nil,
            delegate: self
        )
        // ...the current selection should be the saved PM
        let savedPMButton = sut.getRowButton(accessibilityIdentifier: "•••• 4242")
        XCTAssertEqual(sut.currentSelection, .saved(paymentMethod: savedPaymentMethod))
        XCTAssertTrue(savedPMButton.isSelected)

        // Selecting Apple Pay...
        shouldSelectPaymentMethodReturnValue = true // (and mocking `didTapPaymentMethod` to return true)
        let applePayRowButton = sut.getRowButton(accessibilityIdentifier: "Apple Pay")
        sut.didTap(rowButton: applePayRowButton, selection: .applePay)
        // ...should change the current selection from the saved PM...
        XCTAssertFalse(savedPMButton.isSelected)
        // ...to Apple Pay.
        XCTAssertEqual(sut.currentSelection, .applePay)
        XCTAssertTrue(applePayRowButton.isSelected)

        // Selecting card...
        shouldSelectPaymentMethodReturnValue = false // (and mocking `didTapPaymentMethod` to return false)
        let cardButton = sut.getRowButton(accessibilityIdentifier: "New card")
        sut.didTap(rowButton: cardButton, selection: .new(paymentMethodType: .stripe(.card)))
        // ...should not change the current selection...
        XCTAssertFalse(cardButton.isSelected)
        // ...and Apple Pay should remain selected
        XCTAssertEqual(sut.currentSelection, .applePay)
        XCTAssertTrue(applePayRowButton.isSelected)
    }

    func testSavedCardCopy() {
        let savedPaymentMethods = [
            STPPaymentMethod._testSEPA(),
            STPPaymentMethod._testCard(),
        ]
        // Given a list view with a saved card...
        let sut = VerticalPaymentMethodListViewController(
            initialSelection: .saved(
                paymentMethod: savedPaymentMethods.first!
            ),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "USD",
            amount: 1099,
            incentive: nil,
            delegate: self
        )

        // The card button should say "New card"
        XCTAssert(sut.rowButtons.contains { $0.accessibilityIdentifier == "New card" })
    }

    func testNoSavedCardCopy() {
        let savedPaymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        // Given a list view without a saved card...
        let sut = VerticalPaymentMethodListViewController(
            initialSelection: .saved(
                paymentMethod: savedPaymentMethods.first!
            ),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "USD",
            amount: 1099,
            incentive: nil,
            delegate: self
        )

        // The card button should say "Card"
        XCTAssert(sut.rowButtons.contains { $0.accessibilityIdentifier == "Card" })
    }

    func testApplePayAndLinkOrdering() {
        // If cards are available, Apple Pay / Link appear after it
        let sut = VerticalPaymentMethodListViewController(
            initialSelection: nil,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.SEPADebit), .stripe(.card)],
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "USD",
            amount: 1099,
            incentive: nil,
            delegate: self
        )
        XCTAssertEqual(["SEPA Debit", "Card", "Apple Pay", "Link"], sut.rowButtons.map { $0.label.text })

        // If cards only, Apple Pay / Link appear after it
        let sut_cards_only = VerticalPaymentMethodListViewController(
            initialSelection: nil,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "USD",
            amount: 1099,
            incentive: nil,
            delegate: self
        )
        XCTAssertEqual(["Card", "Apple Pay", "Link"], sut_cards_only.rowButtons.map { $0.label.text })

        // Without cards, Apple Pay / Link appear first
        let sut_no_cards = VerticalPaymentMethodListViewController(
            initialSelection: nil,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.SEPADebit)],
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "USD",
            amount: 1099,
            incentive: nil,
            delegate: self
        )
        XCTAssertEqual(["Apple Pay", "Link", "SEPA Debit"], sut_no_cards.rowButtons.map { $0.label.text })
    }
}

extension VerticalPaymentMethodListViewControllerTest: VerticalPaymentMethodListViewControllerDelegate {
    func didTapSavedPaymentMethodAccessoryButton() {
        // no-op
    }

    func shouldSelectPaymentMethod(_ selection: StripePaymentSheet.RowButtonType) -> Bool {
        return shouldSelectPaymentMethodReturnValue
    }

    func didTapPaymentMethod(_ selection: StripePaymentSheet.RowButtonType) {
        // no-op
    }
}

extension VerticalPaymentMethodListViewController {
    func getRowButton(accessibilityIdentifier: String) -> RowButton {
        return rowButtons.first { $0.accessibilityIdentifier == accessibilityIdentifier }!
    }
}

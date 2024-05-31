//
//  VerticalPaymentMethodListViewTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/17/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class VerticalPaymentMethodListViewTest: XCTestCase {
    var didTapPaymentMethodReturnValue: Bool = false

    func testCurrentSelection() {
        let savedPaymentMethod = STPPaymentMethod._testCard()
        // Given a list view with a saved card...
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: savedPaymentMethod, paymentMethodTypes: [.stripe(.card)], shouldShowApplePay: true, shouldShowLink: true, rightAccessoryType: .edit, appearance: .default)
        sut.delegate = self
        // ...the current selection should be the saved PM
        let savedPMButton = sut.getRowButton(accessibilityIdentifier: "••••4242")
        XCTAssertEqual(sut.currentSelection, .saved(paymentMethod: savedPaymentMethod))
        XCTAssertTrue(savedPMButton.isSelected)

        // Selecting Apple Pay...
        didTapPaymentMethodReturnValue = true // (and mocking `didTapPaymentMethod` to return true)
        let applePayRowButton = sut.getRowButton(accessibilityIdentifier: "Apple Pay")
        sut.didTap(rowButton: applePayRowButton, selection: .applePay)
        // ...should change the current selection from the saved PM...
        XCTAssertFalse(savedPMButton.isSelected)
        // ...to Apple Pay.
        XCTAssertEqual(sut.currentSelection, .applePay)
        XCTAssertTrue(applePayRowButton.isSelected)

        // Selecting card...
        didTapPaymentMethodReturnValue = false // (and mocking `didTapPaymentMethod` to return false)
        let cardButton = sut.getRowButton(accessibilityIdentifier: "Card")
        sut.didTap(rowButton: cardButton, selection: .new(paymentMethodType: .stripe(.card)))
        // ...should not change the current selection...
        XCTAssertFalse(cardButton.isSelected)
        // ...and Apple Pay should remain selected
        XCTAssertEqual(sut.currentSelection, .applePay)
        XCTAssertTrue(applePayRowButton.isSelected)
    }

}

extension VerticalPaymentMethodListViewTest: VerticalPaymentMethodListViewDelegate {
    func didTapPaymentMethod(_ selection: StripePaymentSheet.VerticalPaymentMethodListSelection) -> Bool {
        return didTapPaymentMethodReturnValue
    }

    func didTapSavedPaymentMethodAccessoryButton() {
        // no-op
    }
}

extension VerticalPaymentMethodListView {
    func getRowButton(accessibilityIdentifier: String) -> RowButton {
        return stackView.arrangedSubviews.compactMap { $0 as? RowButton }.first { $0.accessibilityIdentifier == accessibilityIdentifier }!
    }
}

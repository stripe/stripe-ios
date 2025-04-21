//
//  PaymentMethodRowButtonSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 5/15/24.
//

import Foundation
import StripeCoreTestUtils
import UIKit
@_spi(STP)@_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet

class PaymentMethodRowButtonSnapshotTests: STPSnapshotTestCase {

    func testPaymentMethodRowButton_unselected() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: .default)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_selected() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: .default)
        rowButton.state = .selected
        verify(rowButton)
    }

    func testPaymentMethodRowButton_editing_canRemove_canUpdate() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: .default)
        rowButton.state = .editing(allowsRemoval: true, allowsUpdating: true)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_editing_canRemove_cantUpdate() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: .default)
        rowButton.state = .editing(allowsRemoval: true, allowsUpdating: false)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_editing_cantRemove_canUpdate() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: .default)
        rowButton.state = .editing(allowsRemoval: false, allowsUpdating: true)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_selected_with_zero_border_width() {
        var appearance = PaymentSheet.Appearance.default
        appearance.borderWidth = 0
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .selected
        verify(rowButton)
    }
    
    func testPaymentMethodRowButton_ignoresEmbeddedConfiguration() {
        var appearance = PaymentSheet.Appearance.default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .selected
        verify(rowButton)
    }
    
    func testPaymentMethodRowButton_newPaymentMethod_unselected() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .instantDebits,
            hasSavedCard: false,
            promoText: nil,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        verify(rowButton)
    }
    
    func testPaymentMethodRowButton_newPaymentMethod_withPromo_unselected() {
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .instantDebits,
            hasSavedCard: false,
            promoText: "$5",
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        verify(rowButton)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

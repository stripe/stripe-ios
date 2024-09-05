//
//  PaymentMethodRowButtonSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 5/15/24.
//

import Foundation
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP)@_spi(EmbeddedPaymentMethodsViewBeta) import StripePaymentSheet

class PaymentMethodRowButtonSnapshotTests: STPSnapshotTestCase {
    
    private var appearance: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance.default
        appearance.paymentOptionView.style = .floating
        return appearance
    }

    func testPaymentMethodRowButton_unselected() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_selected() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .selected
        verify(rowButton)
    }

    func testPaymentMethodRowButton_editing_canRemove_canUpdate() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .editing(allowsRemoval: true, allowsUpdating: true)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_editing_canRemove_cantUpdate() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .editing(allowsRemoval: true, allowsUpdating: false)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_editing_cantRemove_canUpdate() {
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .editing(allowsRemoval: false, allowsUpdating: true)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_selected_with_zero_border_width() {
        var appearance = PaymentSheet.Appearance.default
        appearance.borderWidth = 0
        appearance.paymentOptionView.style = .floating
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: STPPaymentMethod._testCard(), appearance: appearance)
        rowButton.state = .selected
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

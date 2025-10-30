//
//  PaymentMethodRowButtonSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 5/15/24.
//

import Foundation
import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import UIKit

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

    func testPaymentMethodRowButton_newPaymentMethod_linkType_unselected() {
        let card = STPPaymentMethod._testLink()
        card.linkPaymentDetails = .card(
            LinkPaymentDetails.Card(
                id: "csmr_123",
                displayName: "Visa Credit",
                expMonth: 12,
                expYear: 2030,
                last4: "4242",
                brand: .visa
            )
        )
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: card, appearance: .default)
        verify(rowButton)
    }

    func testPaymentMethodRowButton_newPaymentMethod_linkCardBrandType_unselected() {
        let card = STPPaymentMethod._testCard()
        card.linkPaymentDetails = .bankAccount(
            LinkPaymentDetails.BankDetails(
                id: "csmr_123",
                bankName: "Stripe Bank",
                last4: "4242"
            )
        )
        let rowButton = SavedPaymentMethodRowButton(paymentMethod: card, appearance: .default)
        verify(rowButton)
    }

    func testEmbeddedPaymentMethodIconLayoutMargins() {
        // For every embedded row style...
        for style in PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style.allCases {
            var appearance = PaymentSheet.Appearance()
            appearance.embeddedPaymentElement.row.style = style
            appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins = .init(top: 100, leading: 0, bottom: 100, trailing: 30) // Note: Top and bottom margins should be ignored
            let rowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: .stripe(.card),
                hasSavedCard: false,
                appearance: appearance,
                shouldAnimateOnPress: false,
                isEmbedded: true,
                didTap: { _ in }
            )
            rowButton.isSelected = true
            // ...the row button icon should have 0 left padding and 30 right padding
            verify(rowButton, identifier: "\(style)_0_left_padding_30_right_padding")
        }

        // Non-embedded row button should ignore `paymentMethodIconLayoutMargins`
        var appearance = PaymentSheet.Appearance()
        appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins = .init(top: 100, leading: 100, bottom: 100, trailing: 100)
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            appearance: appearance,
            shouldAnimateOnPress: false,
            isEmbedded: false,
            didTap: { _ in }
        )
        verify(rowButton, identifier: "non_embedded_unaffected")
    }

    func testAppearanceEmbeddedPaymentElementRowTitleAndSubtitleFont() {
        // For every embedded row style...
        for style in PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style.allCases {
            var appearance = PaymentSheet.Appearance()
            appearance.embeddedPaymentElement.row.style = style
            // ...with `appearance.embeddedPaymentElement.row.titleFont` set to a custom italic font...
            appearance.embeddedPaymentElement.row.titleFont = .italicSystemFont(ofSize: 12)
            // ...and `appearance.embeddedPaymentElement.row.subtitleFont` set to a custom italic font...
            appearance.embeddedPaymentElement.row.subtitleFont = .italicSystemFont(ofSize: 10)
            let rowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: .stripe(.klarna),
                hasSavedCard: false,
                appearance: appearance,
                shouldAnimateOnPress: false,
                isEmbedded: true,
                didTap: { _ in }
            )
            rowButton.isSelected = true
            // ...the row button label should have the custom italic font
            verify(rowButton, identifier: "\(style)_custom_italic_font")
        }

        // Non-embedded row button should ignore `appearance.embeddedPaymentElement.row.titleFont` and `subtitleFont`
        var appearance = PaymentSheet.Appearance()
        appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins = .init(top: 100, leading: 100, bottom: 100, trailing: 100)
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            appearance: appearance,
            shouldAnimateOnPress: false,
            isEmbedded: false,
            didTap: { _ in }
        )
        verify(rowButton, identifier: "non_embedded_unaffected")
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

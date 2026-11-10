//
//  PaymentMethodRowButtonSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 5/15/24.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
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
            promotionsHelper: nil,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        verify(rowButton)
    }

    func testPaymentMethodRowButton_cardArt() {
        let appearance = PaymentSheet.Appearance()
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .instantDebits,
            hasSavedCard: false,
            promoText: nil,
            promotionsHelper: nil,
            appearance: appearance,
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
            promotionsHelper: nil,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        verify(rowButton)
    }

    func testPaymentMethodRowButton_paymentMethodMessaging_unselected() {
        let rowButton = makePaymentMethodMessagingRowButton(isEmbedded: false)
        verify(rowButton, identifier: "payment_method_messaging_unselected")
    }

    func testPaymentMethodRowButton_paymentMethodMessaging_selected() {
        let rowButton = makePaymentMethodMessagingRowButton(isEmbedded: false)
        rowButton.updateSelectedState(true, willDisplayForm: false)
        verify(rowButton, identifier: "payment_method_messaging_selected")
    }

    func testEmbeddedPaymentMethodRowButton_paymentMethodMessaging_unselected() {
        let rowButton = makePaymentMethodMessagingRowButton(isEmbedded: true)
        verify(rowButton, identifier: "embedded_payment_method_messaging_unselected")
    }

    func testEmbeddedPaymentMethodRowButton_paymentMethodMessaging_selected() {
        let rowButton = makePaymentMethodMessagingRowButton(isEmbedded: true)
        rowButton.updateSelectedState(true, willDisplayForm: false)
        verify(rowButton, identifier: "embedded_payment_method_messaging_selected")
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
                promotionsHelper: nil,
                appearance: appearance,
                shouldAnimateOnPress: false,
                isEmbedded: true,
                didTap: { _ in }
            )
            rowButton.updateSelectedState(true, willDisplayForm: false)
            // ...the row button icon should have 0 left padding and 30 right padding
            verify(rowButton, identifier: "\(style)_0_left_padding_30_right_padding")
        }

        // Non-embedded row button should ignore `paymentMethodIconLayoutMargins`
        var appearance = PaymentSheet.Appearance()
        appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins = .init(top: 100, leading: 100, bottom: 100, trailing: 100)
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            promotionsHelper: nil,
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
                promotionsHelper: nil,
                appearance: appearance,
                shouldAnimateOnPress: false,
                isEmbedded: true,
                didTap: { _ in }
            )
            rowButton.updateSelectedState(true, willDisplayForm: false)
            // ...the row button label should have the custom italic font
            verify(rowButton, identifier: "\(style)_custom_italic_font")
        }

        // Non-embedded row button should ignore `appearance.embeddedPaymentElement.row.titleFont` and `subtitleFont`
        var appearance = PaymentSheet.Appearance()
        appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins = .init(top: 100, leading: 100, bottom: 100, trailing: 100)
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.card),
            hasSavedCard: false,
            promotionsHelper: nil,
            appearance: appearance,
            shouldAnimateOnPress: false,
            isEmbedded: false,
            didTap: { _ in }
        )
        verify(rowButton, identifier: "non_embedded_unaffected")
    }

    func testEmbeddedPaymentMethod_cardArt() {
        for style in PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style.allCases {
            var appearance = PaymentSheet.Appearance()
            appearance.embeddedPaymentElement.row.style = style
            let rowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: .stripe(.card),
                hasSavedCard: false,
                promotionsHelper: nil,
                appearance: appearance,
                shouldAnimateOnPress: false,
                isEmbedded: true,
                didTap: { _ in }
            )
            rowButton.updateSelectedState(true, willDisplayForm: false)
            verify(rowButton, identifier: "\(style)")
        }
    }

    func testPaymentMethodRowButton_serverDriven() {
        // Given a server-driven payment method whose 48x48 pixel icon is drawn at 3x
        let iconURL = "https://js.stripe.com/test/snapshot-server-driven-icon@3x.png"
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let iconData = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48), format: format).pngData { _ in
            UIColor.systemIndigo.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 48, height: 48), cornerRadius: 9).fill()
        }
        stub(condition: { $0.url?.absoluteString == iconURL }) { _ in
            HTTPStubsResponse(data: iconData, statusCode: 200, headers: nil)
        }
        addTeardownBlock { HTTPStubs.removeAllStubs() }
        let paymentMethod = try! ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(ServerDrivenPaymentMethodFixtures.json {
            $0[jsonDict: "display"]?[jsonDict: "icon"]?[jsonDict: "light"]?["url"] = iconURL
        })

        // When its row is made and the icon downloads
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: .serverDriven(paymentMethod),
            hasSavedCard: false,
            promoText: nil,
            promotionsHelper: nil,
            appearance: .default,
            shouldAnimateOnPress: false,
            didTap: { _ in }
        )
        let downloaded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in rowButton.imageView.image?.size == CGSize(width: 16, height: 16) }, object: nil)
        wait(for: [downloaded], timeout: 5)

        // Then the row shows the server's label, subtitle and icon, at 16pt
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

    private func makePaymentMethodMessagingRowButton(isEmbedded: Bool) -> RowButton {
        var appearance = PaymentSheet.Appearance.default
        if isEmbedded {
            appearance.embeddedPaymentElement.row.style = .flatWithRadio
        }

        return RowButton.makeForPaymentMethodType(
            paymentMethodType: .stripe(.affirm),
            currency: "USD",
            hasSavedCard: false,
            promotionsHelper: ._testValueInTreatment(),
            appearance: appearance,
            shouldAnimateOnPress: false,
            isEmbedded: isEmbedded,
            didTap: { _ in }
        )
    }
}

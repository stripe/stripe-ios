//
//  EmbeddedPaymentMethodsViewSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

class EmbeddedPaymentMethodsViewSnapshotTests: STPSnapshotTestCase {

    // MARK: Flat radio snapshot tests

    func testEmbeddedPaymentMethodsView_flatRadio() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_savedPaymentMethod() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noApplePay() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noLink() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.klarna)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)
        verify(embeddedView)
        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatRadio_rowHeightSingleLine() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorThickness() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.separatorThickness = 10

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.separatorColor = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorInset() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.separatorInsets = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50)

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_topSeparatorDisabled() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_bottomSeparatorDisabled() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_colorSelected() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.radio.selectedColor = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping the last button
        if let rowButton = embeddedView.stackView.arrangedSubviews.last(where: { $0 is RowButton }) as? RowButton {
            embeddedView.didTap(selectedRowButton: rowButton, selection: .new(paymentMethodType: .stripe(.cashApp)))
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_colorUnselected() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.flat.radio.unselectedColor = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_componentBackgroundColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.colors.componentBackground = .purple

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_smallFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_largeFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    // MARK: Floating snapshot tests

    func testEmbeddedPaymentMethodsView_floating() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeightSingleLine() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_floating_spacing() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.embeddedPaymentElement.row.floating.spacing = 30

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_selectedBorder() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .style = .floatingButton
        appearance.selectedBorderWidth = 5.0
        appearance.colors.selectedComponentBorder = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping the last button
        if let rowButton = embeddedView.stackView.arrangedSubviews.last(where: { $0 is RowButton }) as? RowButton {
            embeddedView.didTap(selectedRowButton: rowButton, selection: .new(paymentMethodType: .stripe(.cashApp)))
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_borderWidth() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .style = .floatingButton
        appearance.borderWidth = 5.0
        appearance.colors.primary = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping the last button
        if let rowButton = embeddedView.stackView.arrangedSubviews.last(where: { $0 is RowButton }) as? RowButton {
            embeddedView.didTap(selectedRowButton: rowButton, selection: .new(paymentMethodType: .stripe(.cashApp)))
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_componentBackgroundColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.colors.componentBackground = .purple

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_cornerRadius() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.cornerRadius = 15

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_smallFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_largeFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.style = .floatingButton
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    // MARK: Initial selection tests

    func testEmbeddedPaymentMethodsView_flatRadio_initialApplePay() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .applePay,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_initialLink() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .link,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_initialSavedCard() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: ._testCard(),
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .edit)

        verify(embeddedView)
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

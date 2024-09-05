//
//  EmbeddedPaymentMethodsViewSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

class EmbeddedPaymentMethodsViewSnapshotTests: STPSnapshotTestCase {

    // MARK: Flat radio snapshot tests

    func testEmbeddedPaymentMethodsView_flatRadio() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorThickness() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.flat.separatorThickness = 10

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.flat.separatorColor = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorInset() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.flat.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50)

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_topSeparatorDisabled() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.flat.topSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_bottomSeparatorDisabled() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.flat.bottomSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_colorSelected() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio
        appearance.paymentOptionView?.paymentMethodRow.flat.radio.colorSelected = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping a button
        if let rowButton = embeddedView.stackView.arrangedSubviews.first(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_genericTestAppearance() {
        var appearance: PaymentSheet.Appearance = ._testMSPaintTheme
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatRadio

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: ._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        // Simulate tapping a button
        if let rowButton = embeddedView.stackView.arrangedSubviews.first(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    // MARK: Flat check snapshot tests

    func testEmbeddedPaymentMethodsView_flatCheck() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_separatorThickness() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.flat.separatorThickness = 10

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_separatorColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.flat.separatorColor = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_separatorInset() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.flat.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50)

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_topSeparatorDisabled() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.flat.topSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_bottomSeparatorDisabled() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.flat.bottomSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_checkmarkColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck
        appearance.paymentOptionView?.paymentMethodRow.flat.checkmark.color = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping a button
        if let rowButton = embeddedView.stackView.arrangedSubviews.first(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatCheck_genericTestAppearance() {
        var appearance: PaymentSheet.Appearance = ._testMSPaintTheme
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .flatCheck

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: ._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        // Simulate tapping a button
        if let rowButton = embeddedView.stackView.arrangedSubviews.first(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    // MARK: Floating snapshot tests

    func testEmbeddedPaymentMethodsView_floating() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating
        appearance.paymentOptionView?.paymentMethodRow.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_spacing() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating
        appearance.paymentOptionView?.paymentMethodRow.spacing = 30

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_selectedBorder() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating
        appearance.borderWidthSelected = 5.0
        appearance.colors.componentBorderSelected = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping a button
        if let rowButton = embeddedView.stackView.arrangedSubviews.first(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_genericAppearance() {
        var appearance: PaymentSheet.Appearance = ._testMSPaintTheme
        appearance.paymentOptionView = .init()
        appearance.paymentOptionView?.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: ._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

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

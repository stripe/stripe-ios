//
//  EmbeddedPaymentMethodsViewSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(EmbeddedPaymentMethodsViewBeta) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

class EmbeddedPaymentMethodsViewSnapshotTests: STPSnapshotTestCase {

    // MARK: Flat radio snapshot tests

    func testEmbeddedPaymentMethodsView_flatRadio() {
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_savedPaymentMethod() {
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      embeddedAppearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noApplePay() {
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: .default,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noLink() {
        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_rowHeight() {
        var appearance: EmbeddedAppearance = .default
        appearance.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.klarna)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)
        verify(embeddedView)
        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(embeddedAppearance: .default)
        let defaultInset = EmbeddedAppearance.default.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatRadio_rowHeightSingleLine() {
        var appearance: EmbeddedAppearance = .default
        appearance.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(embeddedAppearance: .default)
        let defaultInset = EmbeddedAppearance.default.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorThickness() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.separatorThickness = 10

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorColor() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.separatorColor = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_separatorInset() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50)

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_topSeparatorDisabled() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.topSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_bottomSeparatorDisabled() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.bottomSeparatorEnabled = false

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_colorSelected() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.radio.colorSelected = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping the last button
        if let rowButton = embeddedView.stackView.arrangedSubviews.last(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_colorUnselected() {
        var appearance: EmbeddedAppearance = .default
        appearance.flat.radio.colorUnselected = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_componentBackgroundColor() {
        var appearance: EmbeddedAppearance = .default
        appearance.colors.componentBackground = .purple

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_smallFont() {
        var appearance: EmbeddedAppearance = .default
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_largeFont() {
        var appearance: EmbeddedAppearance = .default
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    // MARK: Floating snapshot tests

    func testEmbeddedPaymentMethodsView_floating() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_savedPaymentMethod() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noApplePay() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noLink() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeight() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(embeddedAppearance: .default)
        let defaultInset = EmbeddedAppearance.default.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeightSingleLine() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(embeddedAppearance: .default)
        let defaultInset = EmbeddedAppearance.default.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_floating_spacing() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.floating.spacing = 30

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_selectedBorder() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.borderWidthSelected = 5.0
        appearance.colors.componentBorderSelected = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping the last button
        if let rowButton = embeddedView.stackView.arrangedSubviews.last(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_borderWidth() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.borderWidth = 5.0
        appearance.colors.primary = .red

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        // Simulate tapping the last button
        if let rowButton = embeddedView.stackView.arrangedSubviews.last(where: { $0 is RowButton }) as? RowButton {
            embeddedView.handleRowSelection(selectedRowButton: rowButton)
        }

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_componentBackgroundColor() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.colors.componentBackground = .purple

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_cornerRadius() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.cornerRadius = 15

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_smallFont() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_largeFont() {
        var appearance: EmbeddedAppearance = .default
        appearance.style = .floating
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      embeddedAppearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none)

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

//
//  EmbeddedPaymentMethodsViewSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(CustomPaymentMethodsBeta) @_spi(AppearanceAPIAdditionsPreview) @_spi(CustomEmbeddedDisclosureImagePreview) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

class EmbeddedPaymentMethodsViewSnapshotTests: STPSnapshotTestCase {

    // MARK: Flat radio snapshot tests

    func testEmbeddedPaymentMethodsView_flatRadio() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .external(._testBufoPayValue())],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())
        // Note: BufoPay logo will not show in the screenshot, our snapshots currently cannot load remote images
        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_savedPaymentMethod() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMoreChevron,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noApplePay() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_noLink() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())
        verify(embeddedView)
        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    // MARK: Floating snapshot tests

    func testEmbeddedPaymentMethodsView_floating() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMoreChevron,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_floating_rowHeightSingleLine() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_floating_spacing() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.embeddedPaymentElement.row.floating.spacing = 30

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_selectedBorder() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .row.style = .floatingButton
        appearance.selectedBorderWidth = 5.0
        appearance.colors.selectedComponentBorder = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_borderWidth() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .row.style = .floatingButton
        appearance.borderWidth = 5.0
        appearance.colors.primary = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_componentBackgroundColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.colors.componentBackground = .purple

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_cornerRadius() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.cornerRadius = 15

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_smallFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_largeFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    // MARK: Initial selection tests

    func testEmbeddedPaymentMethodsView_flatRadio_initialApplePay() {
        let initialSelection: RowButtonType = .applePay

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: initialSelection,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        XCTAssertEqual(embeddedView.selectedRowButton?.type, initialSelection)
        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_initialLink() {
        let initialSelection: RowButtonType = .link
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: initialSelection,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        XCTAssertEqual(embeddedView.selectedRowButton?.type, initialSelection)
        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_initialSavedCard() {
        let initialSelection: RowButtonType = .saved(paymentMethod: ._testCard())

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: initialSelection,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: ._testCard(),
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .edit,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        XCTAssertEqual(embeddedView.selectedRowButton?.type, initialSelection)
        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_promoBadge() {
        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .instantDebits, .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: MockMandateProvider(),
            incentive: PaymentMethodIncentive(identifier: "link_instant_debits", displayText: "$5")
        )

        verify(embeddedView)
    }

    // MARK: Flat with checkmark snapshot tests

    func testEmbeddedPaymentMethodsView_flatWithCheckmark() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_rowHeightSingleLine() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_spacing() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        appearance.embeddedPaymentElement.row.floating.spacing = 30

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_selectedBorder() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .row.style = .flatWithCheckmark
        appearance.selectedBorderWidth = 5.0
        appearance.colors.selectedComponentBorder = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_borderWidth() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .row.style = .flatWithCheckmark
        appearance.borderWidth = 5.0
        appearance.colors.primary = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_cornerRadius() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        appearance.cornerRadius = 15

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_smallFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_largeFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_promoBadge_unselected() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .new(paymentMethodType: .stripe(.card)),
            paymentMethodTypes: [.stripe(.card), .instantDebits, .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: appearance,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: MockMandateProvider(),
            incentive: PaymentMethodIncentive(identifier: "link_instant_debits", displayText: "$5")
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithCheckmark_promoBadge_selected() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .new(paymentMethodType: .instantDebits),
            paymentMethodTypes: [.stripe(.card), .instantDebits, .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: appearance,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: MockMandateProvider(),
            incentive: PaymentMethodIncentive(identifier: "link_instant_debits", displayText: "$5")
        )

        verify(embeddedView)
    }

    // MARK: Flat with chevron snapshot tests

    func testEmbeddedPaymentMethodsView_flatWithDisclosure() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_color() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.embeddedPaymentElement.row.flat.disclosure.color = .purple

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_customDisclosureView() {
        // Custom small 👃 icon
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.embeddedPaymentElement.row.flat.disclosure.color = .purple
        appearance.embeddedPaymentElement.row.flat.disclosure.disclosureImage = UIImage(systemName: "nose", withConfiguration: UIImage.SymbolConfiguration(pointSize: 5))
        let embeddedView = EmbeddedPaymentMethodsView(
            savedPaymentMethod: ._testCard(),
            appearance: appearance,
            savedPaymentMethodAccessoryType: .viewMore
        )
        verify(embeddedView, identifier: "small_purple_nose_icon")

        // Custom BIG PNG
        appearance.embeddedPaymentElement.row.flat.disclosure.color = .systemGray
        appearance.embeddedPaymentElement.row.flat.disclosure.disclosureImage = UIImage(named: "polling_error_icon", in: Bundle(for: PaymentSheet.self), with: nil)
        let embeddedViewBigCustomIcon = EmbeddedPaymentMethodsView(
            savedPaymentMethod: ._testCard(),
            appearance: appearance,
            savedPaymentMethodAccessoryType: .viewMore
        )
        verify(embeddedViewBigCustomIcon, identifier: "big_error_icon")

        // Custom svg
        let image = UIImage(named: "afterpay_icon_info", in: Bundle(for: PaymentSheet.self), with: nil)
        appearance.embeddedPaymentElement.row.flat.disclosure.disclosureImage = image
        let embeddedViewSmallCustomIcon = EmbeddedPaymentMethodsView(
            savedPaymentMethod: ._testCard(),
            appearance: appearance,
            savedPaymentMethodAccessoryType: .viewMore
        )
        verify(embeddedViewSmallCustomIcon, identifier: "info_icon")
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_savedPaymentMethod() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: .saved(paymentMethod: STPPaymentMethod._testCard()),
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: STPPaymentMethod._testCard(),
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .viewMore,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_noApplePay() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: false,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_noLink() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_rowHeight() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_rowHeightSingleLine() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.embeddedPaymentElement.row.additionalInsets = 20

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: false,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)

        // Assert height
        let defaultHeight = RowButton.calculateTallestHeight(appearance: .default, isEmbedded: true)
        let defaultInset = PaymentSheet.Appearance.default.embeddedPaymentElement.row.additionalInsets
        for case let rowButton as RowButton in embeddedView.stackView.arrangedSubviews {
            let newHeight = rowButton.frame.size.height
            XCTAssertEqual((appearance.embeddedPaymentElement.row.additionalInsets - defaultInset) * 2, newHeight - defaultHeight)
        }
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_spacing() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.embeddedPaymentElement.row.floating.spacing = 30

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_selectedBorder() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .row.style = .flatWithDisclosure
        appearance.selectedBorderWidth = 5.0
        appearance.colors.selectedComponentBorder = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_borderWidth() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement .row.style = .flatWithDisclosure
        appearance.borderWidth = 5.0
        appearance.colors.primary = .red

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        // Simulate tapping the last button (Cash App Pay)
        embeddedView.didTap(rowButton: embeddedView.rowButtons.last!)

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_cornerRadius() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.cornerRadius = 15

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_smallFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.font.sizeScaleFactor = 0.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_largeFont() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure
        appearance.font.sizeScaleFactor = 1.5
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 12)!

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatWithDisclosure_promoBadge_unselected() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithDisclosure

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .new(paymentMethodType: .stripe(.card)),
            paymentMethodTypes: [.stripe(.card), .instantDebits, .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: appearance,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: MockMandateProvider(),
            incentive: PaymentMethodIncentive(identifier: "link_instant_debits", displayText: "$5")
        )

        verify(embeddedView)
    }

    // MARK: Mandate tests

    func testEmbeddedPaymentMethodsView_withMandateProviderAttributedText_noInitialSelection() {
        let mandateText = NSAttributedString(string: "Lorem ipsum odor amet, consectetuer adipiscing elit. Efficitur purus auctor sit parturient nec, sit eget. Aaccumsan integer natoque nunc sodales. Dictum vehicula parturient phasellus imperdiet varius lectus magnis.")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderAttributedText_withInitialSelection() {
        let mandateText = NSAttributedString(string: "Lorem ipsum odor amet, consectetuer adipiscing elit. Efficitur purus auctor sit parturient nec, sit eget. Aaccumsan integer natoque nunc sodales. Dictum vehicula parturient phasellus imperdiet varius lectus magnis.")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .applePay,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderAttributedText_withInitialSelection_withAppearance() {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.text = .blue
        appearance.colors.textSecondary = .red

        let mandateText = NSAttributedString(string: "Lorem ipsum odor amet, consectetuer adipiscing elit. Efficitur purus auctor sit parturient nec, sit eget. Aaccumsan integer natoque nunc sodales. Dictum vehicula parturient phasellus imperdiet varius lectus magnis.")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .link,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: appearance,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderAttributedText_savedPaymentMethod() {
        let mandateText = NSAttributedString(string: "Lorem ipsum odor amet, consectetuer adipiscing elit. Efficitur purus auctor sit parturient nec, sit eget. Aaccumsan integer natoque nunc sodales. Dictum vehicula parturient phasellus imperdiet varius lectus magnis.")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)
        let savedPaymentMethod = STPPaymentMethod._testCard()

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .saved(paymentMethod: savedPaymentMethod),
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: savedPaymentMethod,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .edit,
            mandateProvider: mockMandateProvider,
            savedPaymentMethods: [savedPaymentMethod]
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_floating_withMandateProviderAttributedText() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .floatingButton
        let mandateText = NSAttributedString(string: "Lorem ipsum odor amet, consectetuer adipiscing elit. Efficitur purus auctor sit parturient nec, sit eget. Aaccumsan integer natoque nunc sodales. Dictum vehicula parturient phasellus imperdiet varius lectus magnis.")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: appearance,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderEmptyAttributedText() {
        let mandateText = NSAttributedString(string: "")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderLongAttributedText() {
        let longText = String(repeating: "This is a long mandate text. ", count: 20)
        let mandateText = NSAttributedString(string: longText)
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderNilAttributedText() {
        let mockMandateProvider = MockMandateProvider(attributedText: nil)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .applePay,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withMandateProviderAttributedText_shouldShowMandateFalse() {
        let mandateText = NSAttributedString(string: "Lorem ipsum odor amet, consectetuer adipiscing elit. Efficitur purus auctor sit parturient nec, sit eget. Aaccumsan integer natoque nunc sodales. Dictum vehicula parturient phasellus imperdiet varius lectus magnis.")
        let mockMandateProvider = MockMandateProvider(attributedText: mandateText)

        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: .applePay,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: mockMandateProvider,
            shouldShowMandate: false
        )

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withSavedCard() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withoutSavedCard() {
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testUSBankAccount()])

        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_withReturningLinkConsumer() {
        LinkAccountContext.shared.account = PaymentSheetLinkAccount._testValue(email: "foo@bar.com")
        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: MockMandateProvider(),
            savedPaymentMethods: []
        )
        let window = UIWindow()
        window.backgroundColor = .systemBackground
        window.isHidden = false
        window.addAndPinSubview(embeddedView, insets: .zero)
        verify(window)
        LinkAccountContext.shared.account = nil
    }

    func testEmbeddedPaymentMethodsView_withUnknownLinkConsumer() {
        LinkAccountContext.shared.account = PaymentSheetLinkAccount._testValue(email: "foo@bar.com", isRegistered: false)
        let embeddedView = EmbeddedPaymentMethodsView(
            initialSelection: nil,
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
            savedPaymentMethod: nil,
            appearance: .default,
            shouldShowApplePay: true,
            shouldShowLink: true,
            savedPaymentMethodAccessoryType: .none,
            mandateProvider: MockMandateProvider(),
            savedPaymentMethods: []
        )
        let window = UIWindow()
        window.backgroundColor = .systemBackground
        window.isHidden = false
        window.addAndPinSubview(embeddedView, insets: .zero)
        verify(window)
        LinkAccountContext.shared.account = nil
    }

    func testEmbeddedPaymentMethodsView_iconStyleOutlined() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.iconStyle = .outlined

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.USBankAccount)],
                                                      savedPaymentMethod: nil,
                                                      appearance: appearance,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard(), ._testUSBankAccount()])

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

extension PaymentSheetLinkAccount {
    static func _testValue(
        email: String,
        isRegistered: Bool = true,
        displayablePaymentDetails: ConsumerSession.DisplayablePaymentDetails? = nil
    ) -> PaymentSheetLinkAccount {
        var session: ConsumerSession?
        if isRegistered {
            session = ConsumerSession(
                clientSecret: "client_secret",
                emailAddress: email,
                redactedFormattedPhoneNumber: "+1********55",
                unredactedPhoneNumber: nil,
                phoneNumberCountry: nil,
                verificationSessions: [
                    .init(type: .sms, state: .verified)
                ],
                supportedPaymentDetailsTypes: [.card],
                mobileFallbackWebviewParams: nil
            )
        }
        return .init(
            email: email,
            session: session,
            publishableKey: "pk_123",
            displayablePaymentDetails: displayablePaymentDetails,
            useMobileEndpoints: true
        )
    }
}

class MockMandateProvider: MandateTextProvider {
    private let mandateResolver: (PaymentSheet.PaymentMethodType?) -> (NSAttributedString?)

    init(mandateResolver: @escaping (PaymentSheet.PaymentMethodType?) -> (NSAttributedString?)) {
        self.mandateResolver = mandateResolver
    }

    init(attributedText: NSAttributedString? = nil) {
        self.mandateResolver = { _ in return attributedText }
    }

    func mandate(for paymentMethodType: PaymentSheet.PaymentMethodType?, savedPaymentMethod: STPPaymentMethod?, bottomNoticeAttributedString: NSAttributedString?) -> NSAttributedString? {
        return mandateResolver(paymentMethodType)
    }
}

extension EmbeddedPaymentMethodsView {
    convenience init(
        initialSelection: RowButtonType? = nil,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.card), .stripe(.cashApp)],
        savedPaymentMethod: STPPaymentMethod? = nil,
        appearance: PaymentSheet.Appearance = .default,
        shouldShowApplePay: Bool = true,
        shouldShowLink: Bool = true,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType? = nil,
        mandateProvider: MandateTextProvider = MockMandateProvider(),
        shouldShowMandate: Bool = true,
        savedPaymentMethods: [STPPaymentMethod] = [],
        customer: PaymentSheet.CustomerConfiguration? = nil,
        incentive: PaymentMethodIncentive? = nil,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) {
        self.init(
            initialSelectedRowType: initialSelection,
            initialSelectedRowChangeButtonState: nil,
            paymentMethodTypes: paymentMethodTypes,
            savedPaymentMethod: savedPaymentMethod,
            appearance: appearance,
            shouldShowApplePay: shouldShowApplePay,
            shouldShowLink: shouldShowLink,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            mandateProvider: mandateProvider,
            shouldShowMandate: shouldShowMandate,
            savedPaymentMethods: savedPaymentMethods,
            customer: customer,
            incentive: incentive,
            analyticsHelper: ._testValue(),
            delegate: nil
        )
    }
}

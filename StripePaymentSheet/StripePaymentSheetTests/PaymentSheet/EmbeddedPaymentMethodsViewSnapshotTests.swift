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
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

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
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.klarna)],
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
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))

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

    func testEmbeddedPaymentMethodsView_flatRadio_componentBackgroundColor() {
        var appearance: PaymentSheet.Appearance = .default
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
    
    func testEmbeddedPaymentMethodsView_bacsDebit_darkBackground() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.colors.componentBackground = .black
        appearance.colors.componentText = .lightText
        appearance.colors.componentPlaceholderText = .lightText

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: nil,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.bacsDebit)],
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
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))

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
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))

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
        let initialSelection: EmbeddedPaymentMethodsView.Selection = .applePay

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: initialSelection,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        XCTAssertEqual(embeddedView.selection, initialSelection)
        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_initialLink() {
        let initialSelection: EmbeddedPaymentMethodsView.Selection = .link
        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: initialSelection,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: nil,
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .none,
                                                      mandateProvider: MockMandateProvider())

        XCTAssertEqual(embeddedView.selection, initialSelection)
        verify(embeddedView)
    }

    func testEmbeddedPaymentMethodsView_flatRadio_initialSavedCard() {
        let initialSelection: EmbeddedPaymentMethodsView.Selection = .saved(paymentMethod: ._testCard())

        let embeddedView = EmbeddedPaymentMethodsView(initialSelection: initialSelection,
                                                      paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)],
                                                      savedPaymentMethod: ._testCard(),
                                                      appearance: .default,
                                                      shouldShowApplePay: true,
                                                      shouldShowLink: true,
                                                      savedPaymentMethodAccessoryType: .edit,
                                                      mandateProvider: MockMandateProvider(),
                                                      savedPaymentMethods: [._testCard()])

        XCTAssertEqual(embeddedView.selection, initialSelection)
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
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))
        
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
        embeddedView.didTap(selection: .new(paymentMethodType: .stripe(.cashApp)))
        
        verify(embeddedView)
    }
    
    func testEmbeddedPaymentMethodsView_flatWithCheckmark_componentBackgroundColor() {
        var appearance: PaymentSheet.Appearance = .default
        appearance.embeddedPaymentElement.row.style = .flatWithCheckmark
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
        appearance.colors.textSecondary = .red
        appearance.colors.componentBackground = .gray

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

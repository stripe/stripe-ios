//
//  CardBrandChoiceElementSnapshotTest.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 2/27/26.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripePaymentsUI
@_spi(STP) @testable import StripeUICore
import UIKit

// @iOS26
final class CardBrandChoiceElementSnapshotTest: STPSnapshotTestCase {
    var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()
    var theme: ElementsAppearance {
        return appearance.asElementsTheme
    }

    // MARK: - CardBrandChoiceElement (CBC Redesign) Tests

    // Due to limitations of snapshot tests, the iOS26 snapshot recorded shows a rectangular border instead of a capsule
    func testCardBrandChoiceElement() {
        let element = CardBrandChoiceElement(
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        verify(element)
    }

    // Due to limitations of snapshot tests, the iOS26 snapshot recorded shows a rectangular border instead of a capsule
    func testCardBrandChoiceElement_withDisallowedBrands() {
        let element = CardBrandChoiceElement(
            cardBrands: [],
            disallowedCardBrands: [],
            theme: theme
        )
        element.update(cardBrands: [.visa, .cartesBancaires], disallowedCardBrands: [.visa])
        element.select(.cartesBancaires)
        verify(element)
    }

    // Due to limitations of snapshot tests, the iOS26 snapshot recorded shows a rectangular border instead of a capsule
    func testCardBrandChoiceElement_CB() {
        let element = CardBrandChoiceElement(
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        // Select a brand
        let brand: STPCardBrand = .cartesBancaires
        element.select(brand)
        verify(element)
    }

    // Due to limitations of snapshot tests, the iOS26 snapshot recorded shows a rectangular border instead of a capsule
    func testCardBrandChoiceElement_Visa() {
        let element = CardBrandChoiceElement(
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        // Select a brand
        let brand: STPCardBrand = .visa
        element.select(brand)
        verify(element)
    }

    func testCardBrandChoiceElement_appearance() {
        appearance = ._testMSPaintTheme

        let element = CardBrandChoiceElement(
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        // Select a brand
        let brand: STPCardBrand = .cartesBancaires
        element.select(brand)
        verify(element)
    }

    // MARK: - CBC Tooltip Tests

    // Due to limitations of snapshot tests, the iOS26 snapshot recorded shows a rectangular border instead of a capsule
    func testCBCTooltipView() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionWithTooltip(appearance: appearance)
        STPSnapshotVerifyView(cardSection.view)
    }

    // Due to limitations of snapshot tests, the iOS26 snapshot recorded shows a rectangular border instead of a capsule
    func testCBCTooltipView_darkMode() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let cardSection = makeCardSectionWithTooltip(appearance: appearance, darkMode: true)
        STPSnapshotVerifyView(cardSection.view)
    }

    func testCBCTooltipView_appearance() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        appearance = ._testMSPaintTheme
        let cardSection = makeCardSectionWithTooltip(appearance: appearance)
        STPSnapshotVerifyView(cardSection.view)
    }
}

private extension CardBrandChoiceElementSnapshotTest {
    func verify(_ element: CardBrandChoiceElement) {
        let view = element.view
        view.backgroundColor = appearance.colors.background

        // Let the view size itself based on its intrinsic content size
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        view.bounds = CGRect(origin: .zero, size: size)
        view.layoutIfNeeded()

        STPSnapshotVerifyView(view)
    }

    /// Creates a CardSectionElement in a window with the CBC tooltip visible.
    func makeCardSectionWithTooltip(appearance: PaymentSheet.Appearance, darkMode: Bool = false) -> CardSectionElement {
        let cardSection = CardSectionElement(
            cardBrandChoiceEligible: true,
            hostedSurface: .paymentSheet,
            theme: appearance.asElementsTheme,
            analyticsHelper: ._testValue(),
            opensCardScannerAutomatically: false
        )

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        if darkMode {
            window.overrideUserInterfaceStyle = .dark
        }
        cardSection.view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(cardSection.view)
        NSLayoutConstraint.activate([
            cardSection.view.topAnchor.constraint(equalTo: window.topAnchor),
            cardSection.view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            cardSection.view.widthAnchor.constraint(equalToConstant: 320),
        ])
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        _ = cardSection.panElement.textFieldView.textField.becomeFirstResponder()
        cardSection.panElement.setText("4000002500001001")
        window.layoutIfNeeded()

        return cardSection
    }
}

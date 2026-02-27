//
//  CardBrandChoiceElementSnapshotTest.swift
//  StripePaymentSheet
//

import StripeCoreTestUtils
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripeUICore
import UIKit

final class CardBrandChoiceElementSnapshotTest: STPSnapshotTestCase {
    var appearance = PaymentSheet.Appearance()
    var theme: ElementsAppearance {
        return appearance.asElementsTheme
    }

    // MARK: - CardBrandChoiceElement (CBC Redesign) Tests

    func testCardBrandChoiceElement() {
        let element = CardBrandChoiceElement(
            enableCBCRedesign: true,
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        verify(element)
    }

    func testCardBrandChoiceElement_withDisallowedBrands() {
        let element = CardBrandChoiceElement(
            enableCBCRedesign: true,
            cardBrands: [],
            disallowedCardBrands: [],
            theme: theme
        )
        // Trigger auto-select by updating with one brand disallowed
        element.update(cardBrands: [.visa, .cartesBancaires], disallowedCardBrands: [.visa])
        verify(element)
    }

    func testCardBrandChoiceElement_CB() {
        let element = CardBrandChoiceElement(
            enableCBCRedesign: true,
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        // Select a brand
        element.selectorElement?.selectBrand(.cartesBancaires)
        verify(element)
    }

    func testCardBrandChoiceElement_Visa() {
        let element = CardBrandChoiceElement(
            enableCBCRedesign: true,
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        // Select a brand
        element.selectorElement?.selectBrand(.visa)
        verify(element)
    }

    func testCardBrandChoiceElement_appearance() {
        appearance = ._testMSPaintTheme

        let element = CardBrandChoiceElement(
            enableCBCRedesign: true,
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme
        )
        element.selectorElement?.selectBrand(.visa)
        verify(element)
    }

    // MARK: - DropdownElement (Legacy) Tests

    func testDropdownElement() {
        let element = CardBrandChoiceElement(
            enableCBCRedesign: false,
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme,
            includePlaceholder: true
        )
        verify(element)
    }

    func testDropdownElement_noPlaceholder() {
        let element = CardBrandChoiceElement(
            enableCBCRedesign: false,
            cardBrands: [.visa, .cartesBancaires],
            disallowedCardBrands: [],
            theme: theme,
            includePlaceholder: false
        )
        verify(element)
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
}

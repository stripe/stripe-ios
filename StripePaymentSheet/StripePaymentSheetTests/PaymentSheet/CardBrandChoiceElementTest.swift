//
//  CardBrandChoiceElementTest.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 3/9/26.
//

@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

final class CardBrandChoiceElementTest: XCTestCase {

    // MARK: - Helpers

    /// Extracts the underlying SegmentedSelectorElement from the CardBrandChoiceElement.
    private func selector(from element: CardBrandChoiceElement) -> SegmentedSelectorElement {
        guard case .selector(let selector) = element.variant else {
            fatalError("Expected .selector variant")
        }
        return selector
    }

    // MARK: - Tests

    func testUpdate_oneAllowedBrand() {
        let element = CardBrandChoiceElement(enableCBCRedesign: true)
        element.update(cardBrands: [.visa, .cartesBancaires], disallowedCardBrands: [.cartesBancaires])

        // The only enabled brand (Visa) should be auto-selected
        XCTAssertEqual(element.selectedBrand, .visa)

        let selector = selector(from: element)
        if let selectedItem = selector.selectedItem {
            // Tapping the selected item should NOT deselect it
            selector.didTap(selectedItem)
            XCTAssertNotNil(selector.selectedItem)
        } else {
            XCTFail("Visa should be selected")
        }
    }

    func testUpdate_allowsDeselectionWhenMultipleAllowedBrands() {
        let element = CardBrandChoiceElement(enableCBCRedesign: true)
        element.update(cardBrands: [.visa, .cartesBancaires], disallowedCardBrands: [])

        let selector = selector(from: element)

        // Select one brand
        selector.didTap(selector.items[0])
        XCTAssertNotNil(element.selectedBrand)

        // Tapping the selected item again should deselect it
        if let selectedItem = selector.selectedItem {
            selector.didTap(selectedItem)
            XCTAssertNil(selector.selectedItem)
        } else {
            XCTFail("A card brand should be selected")
        }
    }

    func testUpdate_reallowsDeselectionWhenBrandsChange() {
        let element = CardBrandChoiceElement(enableCBCRedesign: true)

        // Start with 1 enabled brand — deselection blocked
        element.update(cardBrands: [.visa, .cartesBancaires], disallowedCardBrands: [.cartesBancaires])
        
        // The only enabled brand (Visa) should be auto-selected
        XCTAssertEqual(element.selectedBrand, .visa)

        let selector = selector(from: element)
        if let selectedItem = selector.selectedItem {
            XCTAssertFalse(selector.allowDeselection)
            // Tapping the selected item should NOT deselect it
            selector.didTap(selectedItem)
            XCTAssertNotNil(selector.selectedItem)
        } else {
            XCTFail("Visa should be selected")
        }

        // Update to 2 enabled brands — deselection should be allowed again
        element.update(cardBrands: [.visa, .cartesBancaires], disallowedCardBrands: [])
        XCTAssertTrue(selector.allowDeselection)

        // Tap Visa again to verify deselection works
        if let selectedItem = selector.selectedItem {
            selector.didTap(selectedItem)
            XCTAssertNil(selector.selectedItem)
        } else {
            XCTFail("Visa should be selected")
        }
    }
}

//
//  CardBrandSelectorElementTest.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 2/11/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import XCTest

final class CardBrandSelectorElementTest: XCTestCase {

    // MARK: - Brand display

    func testUpdate_displaysBrands() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])

        XCTAssertEqual(element.brands, [.visa, .mastercard])
        XCTAssertNil(element.selectedBrand)
    }

    func testUpdate_withEmptyBrands() {
        let element = CardBrandSelectorElement()
        element.update(brands: [], disallowedBrands: [])

        XCTAssertTrue(element.brands.isEmpty)
        XCTAssertNil(element.selectedBrand)
    }

    // MARK: - Selection

    func testSelect_brand() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])

        element.select(brand: .visa)
        XCTAssertEqual(element.selectedBrand, .visa)
    }

    func testSelect_nilDeselects() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])

        element.select(brand: .visa)
        XCTAssertEqual(element.selectedBrand, .visa)

        element.select(brand: nil)
        XCTAssertNil(element.selectedBrand)
    }

    // MARK: - Toggle behavior

    func testToggle_selectAndDeselect() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])

        // Select visa
        element.select(brand: .visa)
        XCTAssertEqual(element.selectedBrand, .visa)

        // Deselect by setting nil
        element.select(brand: nil)
        XCTAssertNil(element.selectedBrand)

        // Select again
        element.select(brand: .mastercard)
        XCTAssertEqual(element.selectedBrand, .mastercard)
    }

    // MARK: - Disallowed brands

    func testDisallowedBrands_preventSelection() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [.mastercard])

        // The view should prevent tapping disallowed brands
        let view = element.cardBrandSelectorView
        XCTAssertTrue(view.disallowedBrands.contains(.mastercard))
    }

    // MARK: - Preferred networks

    func testSelect_preferredNetwork() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard, .cartesBancaires], disallowedBrands: [])

        element.select(brand: .mastercard)
        XCTAssertEqual(element.selectedBrand, .mastercard)
    }

    // MARK: - Sub-label

    func testSubLabelText_shown_whenMultipleBrands_noSelection_panEditing() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])
        element.isPanFieldEditing = true

        XCTAssertEqual(element.subLabelText, String.Localized.choose_a_card_brand)
    }

    func testSubLabelText_hidden_whenBrandSelected() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])
        element.isPanFieldEditing = true

        element.select(brand: .visa)
        XCTAssertNil(element.subLabelText)
    }

    func testSubLabelText_hidden_whenPanNotEditing() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])
        element.isPanFieldEditing = false

        XCTAssertNil(element.subLabelText)
    }

    func testSubLabelText_hidden_whenSingleBrand() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa], disallowedBrands: [])
        element.isPanFieldEditing = true

        XCTAssertNil(element.subLabelText)
    }

    func testSubLabelText_hidden_whenNoBrands() {
        let element = CardBrandSelectorElement()
        element.isPanFieldEditing = true

        XCTAssertNil(element.subLabelText)
    }

    // MARK: - Validation

    func testValidationState_alwaysValid() {
        let element = CardBrandSelectorElement()
        XCTAssertEqual(element.validationState, .valid)

        element.update(brands: [.visa, .mastercard], disallowedBrands: [])
        XCTAssertEqual(element.validationState, .valid)
    }

    // MARK: - collectsUserInput

    func testCollectsUserInput() {
        let element = CardBrandSelectorElement()
        XCTAssertTrue(element.collectsUserInput)
    }

    // MARK: - Reset

    func testReset_clearsBrandsAndSelection() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])
        element.select(brand: .visa)

        element.reset()

        XCTAssertTrue(element.brands.isEmpty)
        XCTAssertNil(element.selectedBrand)
    }

    // MARK: - Delegate

    func testDelegate_calledOnSelection() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])

        let delegateExpectation = expectation(description: "Delegate called")
        let testDelegate = TestElementDelegate {
            delegateExpectation.fulfill()
        }
        element.delegate = testDelegate

        element.select(brand: .visa)
        waitForExpectations(timeout: 1)
    }

    func testDelegate_calledOnPanFieldEditingChange() {
        let element = CardBrandSelectorElement()
        element.update(brands: [.visa, .mastercard], disallowedBrands: [])

        let delegateExpectation = expectation(description: "Delegate called")
        let testDelegate = TestElementDelegate {
            delegateExpectation.fulfill()
        }
        element.delegate = testDelegate

        element.isPanFieldEditing = true
        waitForExpectations(timeout: 1)
    }
}

// MARK: - Test Helpers

private class TestElementDelegate: ElementDelegate {
    let onDidUpdate: () -> Void

    init(onDidUpdate: @escaping () -> Void) {
        self.onDidUpdate = onDidUpdate
    }

    func didUpdate(element: Element) {
        onDidUpdate()
    }

    func continueToNextField(element: Element) {}
}

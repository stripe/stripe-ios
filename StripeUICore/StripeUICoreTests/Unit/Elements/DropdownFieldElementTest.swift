//
//  DropdownFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeUICore
import XCTest

final class DropdownFieldElementTest: XCTestCase {

    let items = ["A", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }

    func testNoDefault() {
        let element = DropdownFieldElement(items: items, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testWithDefault() {
        let element = DropdownFieldElement(items: items, defaultIndex: 3, label: "")
        XCTAssertEqual(element.selectedIndex, 3)
    }

    func testDefaultExceedsMax() {
        let element = DropdownFieldElement(items: items, defaultIndex: items.count, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testDefaultExceedsMin() {
        let element = DropdownFieldElement(items: items, defaultIndex: -1, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testDisableDropdownWithSingleElement() {
        let multipleElements = DropdownFieldElement(items: items, defaultIndex: -1, label: "", disableDropdownWithSingleElement: true)

        XCTAssertEqual(multipleElements.pickerFieldView.isUserInteractionEnabled, true)

        let singleElement = DropdownFieldElement(items: [DropdownFieldElement.DropdownItem(pickerDisplayName: "Item", labelDisplayName: "Item", accessibilityValue: "Item", rawData: "Item")], defaultIndex: -1, label: "", disableDropdownWithSingleElement: true)

        XCTAssertEqual(singleElement.pickerFieldView.isUserInteractionEnabled, false)
    }

    func testDidUpdate() {
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)
        // Emulate a user changing the picker and hitting done button
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 3)
    }

    func testDidUpdateToDefault() {
        // Ensure `didUpdate` is not called if the selection doesn't change

        var index: Int?
        let element = DropdownFieldElement(items: items, defaultIndex: 0, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)

        // Emulate a user changing the picker
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        XCTAssertNil(index)

        // Emulate a user changing the picker back
        element.pickerView(element.pickerView, didSelectRow: 0, inComponent: 0)
        XCTAssertNil(index)

        // Emulate user hitting the done button
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertNil(index)
    }

    func testUpdate() {
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)
        // Emulate a user changing the picker and hitting done button
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 3)

        // Update items with same list should keep original item selected
        element.update(items: items)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 3)

        // Update items removing/replacing item at index 4, should select the first index
        let items = ["A", "B", "C", "DD"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }
        element.update(items: items)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 0)
    }

    func testCantSelectDisabledItem() {
        let disabledItem = DropdownFieldElement.DropdownItem(pickerDisplayName: "Disabled",
                                                             labelDisplayName: "Disabled",
                                                             accessibilityValue: "Disabled",
                                                             rawData: "Disabled",
                                                             isDisabled: true)
        let itemsWithDisabled = items + [disabledItem]
        XCTAssertEqual(4, items.count)

        var index: Int?
        let element = DropdownFieldElement(items: itemsWithDisabled, defaultIndex: 0, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)

        // Emulate a user changing the picker and hitting the done button
        element.pickerView(element.pickerView, didSelectRow: 2, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 2)

        element.pickerView(element.pickerView, didSelectRow: 4, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        // Should stay selected on previous selection
        XCTAssertEqual(index, 2)
    }

    // MARK: - startsEmpty tests

    func testStartsEmptyInitialState() {
        let element = DropdownFieldElement(items: items, label: "", startsEmpty: true)
        // First item should be the auto-generated placeholder
        XCTAssertTrue(element.items.first?.isPlaceholder ?? false)
        // Placeholder selected
        XCTAssertEqual(element.selectedIndex, 0)
        // Validation should be invalid (not empty optional)
        XCTAssertFalse(element.validationState.isValid)
    }

    func testStartsEmptyOptionalIsValid() {
        let element = DropdownFieldElement(items: items, label: "", isOptional: true, startsEmpty: true)
        XCTAssertTrue(element.items.first?.isPlaceholder ?? false)
        XCTAssertEqual(element.selectedIndex, 0)
        // Optional field with no selection should still be valid
        XCTAssertTrue(element.validationState.isValid)
    }

    func testStartsEmptySelectingItemUpdatesValidation() {
        var didUpdateIndex: Int?
        let element = DropdownFieldElement(items: items, label: "", startsEmpty: true, didUpdate: { didUpdateIndex = $0 })

        // Select row 2
        element.pickerView(element.pickerView, didSelectRow: 2, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)

        XCTAssertEqual(didUpdateIndex, 2)
        XCTAssertTrue(element.validationState.isValid)
    }

}

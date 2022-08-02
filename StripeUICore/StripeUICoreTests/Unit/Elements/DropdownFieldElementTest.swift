//
//  DropdownFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/8/21.
//

import XCTest
@_spi(STP) @testable import StripeUICore

final class DropdownFieldElementTest: XCTestCase {

    let items = ["A", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityLabel: $0, rawData: $0) }

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

    func testDidUpdate() {
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)
        // Emulate a user changing the picker and hitting done button
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        element.didFinish(element.pickerFieldView)
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
        element.didFinish(element.pickerFieldView)
        XCTAssertNil(index)
    }
}

//
//  SegmentedSelectorElementTest.swift
//  StripeUICoreTests
//
//  Created by Joyce Qin on 3/4/26.
//

@_spi(STP) @testable import StripeUICore
import XCTest

final class SegmentedSelectorElementTest: XCTestCase {

    let items: [SegmentedSelectorItem] = {
        let itemNames = ["A", "B", "C"]
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed]
        return zip(itemNames, colors).map { name, color in
            // Create a simple colored circle as a placeholder image
            let size = CGSize(width: 16, height: 16)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                color.setFill()
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
            return SegmentedSelectorItem(
                rawData: name,
                image: image,
                accessibilityLabel: "Item \(name)"
            )
        }
    }()

    func testNoSelection() {
        let element = SegmentedSelectorElement(items: items)
        XCTAssertNil(element.selectedItem)
    }

    func testSelect() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[0])
        XCTAssertEqual(element.selectedItem, items[0])
    }

    func testSelectDifferentItem() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[0])
        element.select(items[2])
        XCTAssertEqual(element.selectedItem, items[2])
    }

    func testSelectNilDeselects() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[0])
        element.select(nil)
        XCTAssertNil(element.selectedItem)
    }

    func testSelectItemNotInList() {
        let element = SegmentedSelectorElement(items: Array(items.prefix(2)))
        element.select(items[2])
        XCTAssertNil(element.selectedItem)
    }

    func testTapSelectsItem() {
        let element = SegmentedSelectorElement(items: items)
        element.didTap(items[0])
        XCTAssertEqual(element.selectedItem, items[0])
    }

    func testTapSelectedItemDeselects() {
        let element = SegmentedSelectorElement(items: items)
        element.didTap(items[1])

        // Tap the already-selected item — should toggle off
        element.didTap(items[1])
        XCTAssertNil(element.selectedItem)
    }

    func testTapSelectedItemDoesNotDeselectWhenAllowDeselectionFalse() {
        let element = SegmentedSelectorElement(items: items, allowDeselection: false)
        element.didTap(items[1])

        // Tap the already-selected item — should not toggle off
        element.didTap(items[1])
        XCTAssertNotNil(element.selectedItem)
    }

    func testTapDifferentItemSwitchesSelection() {
        let element = SegmentedSelectorElement(items: items)
        element.didTap(items[0])

        element.didTap(items[2])
        XCTAssertEqual(element.selectedItem, items[2])
    }

    func testUpdateRemovingSelectedItemDeselects() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[2])

        // Remove the selected item from the list
        element.update(items: Array(items.prefix(2)))
        XCTAssertNil(element.selectedItem)
    }

    func testUpdateDisablingSelectedItemDeselects() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[1])

        // Disable the selected item
        element.update(items: items, disabledItems: Set([items[1]]))
        XCTAssertNil(element.selectedItem)
    }

    func testUpdatePreservesSelection() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[0])

        // Disable a different item
        element.update(items: items, disabledItems: Set([items[2]]))
        XCTAssertEqual(element.selectedItem, items[0])
    }

    func testSetAllowDeselection() {
        let element = SegmentedSelectorElement(items: items)
        element.select(items[0])
        element.didTap(items[0])
        // Allow deselection by default
        XCTAssertNil(element.selectedItem)

        // Don't allow deselection
        element.setAllowDeselection(false)
        element.select(items[0])
        element.didTap(items[0])
        XCTAssertEqual(element.selectedItem, items[0])
        // But allow selecting other elements
        element.didTap(items[1])
        XCTAssertEqual(element.selectedItem, items[1])
    }
}

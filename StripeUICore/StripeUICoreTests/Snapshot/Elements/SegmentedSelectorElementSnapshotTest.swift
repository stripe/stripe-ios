//
//  SegmentedSelectorElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Joyce Qin on 3/1/26.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

final class SegmentedSelectorElementSnapshotTest: STPSnapshotTestCase {
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
        let selectorElement = makeSegmentedSelectorElement()
        verify(selectorElement)
    }

    func testFirstItemSelected() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[0], animated: false, shouldAutoAdvance: false)
        verify(selectorElement)
    }

    func testMiddleItemSelected() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[1], animated: false, shouldAutoAdvance: false)
        verify(selectorElement)
    }

    func testLastItemSelected() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[2], animated: false, shouldAutoAdvance: false)
        verify(selectorElement)
    }

    func testWithDisabledItems() {
        let disabledItems = Set([items[1], items[2]])
        let selectorElement = makeSegmentedSelectorElement(disabledItems: disabledItems)
        verify(selectorElement)
    }

    func testWithDisabledItemsAndSelection() {
        let disabledItems = Set([items[1], items[2]])
        let selectorElement = makeSegmentedSelectorElement(disabledItems: disabledItems)
        // Select an enabled item
        selectorElement.select(items[0], animated: false, shouldAutoAdvance: false)
        verify(selectorElement)
    }

    func testTwoItems() {
        let twoItems = Array(items.prefix(2))
        let selectorElement = SegmentedSelectorElement(
            items: twoItems,
            disabledItems: [],
            theme: .default
        )
        verify(selectorElement)
    }

    func testTwoItemsWithSelection() {
        let twoItems = Array(items.prefix(2))
        let selectorElement = SegmentedSelectorElement(
            items: twoItems,
            disabledItems: [],
            theme: .default
        )
        selectorElement.select(twoItems[1], animated: false, shouldAutoAdvance: false)
        verify(selectorElement)
    }
}

private extension SegmentedSelectorElementSnapshotTest {
    func makeSegmentedSelectorElement(
        disabledItems: Set<SegmentedSelectorItem> = []
    ) -> SegmentedSelectorElement {
        return SegmentedSelectorElement(
            items: items,
            disabledItems: disabledItems,
            theme: .default
        )
    }

    func verify(_ element: SegmentedSelectorElement) {
        let view = element.view
        // Let the view size itself based on its intrinsic content size
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        view.bounds = CGRect(origin: .zero, size: size)
        view.layoutIfNeeded()

        STPSnapshotVerifyView(view)
    }
}

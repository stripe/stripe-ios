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
        selectorElement.select(items[0])
        verify(selectorElement)
    }

    func testMiddleItemSelected() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[1])
        verify(selectorElement)
    }

    func testLastItemSelected() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[2])
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
        selectorElement.select(items[0])
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
        selectorElement.select(twoItems[1])
        verify(selectorElement)
    }

    // MARK: - Dark mode

    func testNoSelection_darkMode() {
        let selectorElement = makeSegmentedSelectorElement()
        verify(selectorElement, darkMode: true)
    }

    func testFirstItemSelected_darkMode() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[0])
        verify(selectorElement, darkMode: true)
    }

    func testWithDisabledItems_darkMode() {
        let disabledItems = Set([items[1], items[2]])
        let selectorElement = makeSegmentedSelectorElement(disabledItems: disabledItems)
        verify(selectorElement, darkMode: true)
    }

    func testWithDisabledItemsAndSelection_darkMode() {
        let disabledItems = Set([items[1], items[2]])
        let selectorElement = makeSegmentedSelectorElement(disabledItems: disabledItems)
        selectorElement.select(items[0])
        verify(selectorElement, darkMode: true)
    }

    // MARK: - Update

    func testUpdateAddItems() {
        let twoItems = Array(items.prefix(2))
        let selectorElement = SegmentedSelectorElement(
            items: twoItems,
            disabledItems: [],
            theme: .default
        )
        // Update to three items
        selectorElement.update(items: items, disabledItems: [])
        verify(selectorElement)
    }

    func testUpdateRemoveItems() {
        let selectorElement = makeSegmentedSelectorElement()
        // Update to two items
        let twoItems = Array(items.prefix(2))
        selectorElement.update(items: twoItems, disabledItems: [])
        verify(selectorElement)
    }

    func testUpdateDisabledItems() {
        let selectorElement = makeSegmentedSelectorElement()
        // Select an item
        selectorElement.select(items[1])
        // Update to disable the last two items, including the previously selected item
        selectorElement.update(items: items, disabledItems: Set([items[1], items[2]]))
        verify(selectorElement)
    }

    func testUpdatePreservesSelection() {
        let selectorElement = makeSegmentedSelectorElement()
        selectorElement.select(items[0])
        // Update disabled items while keeping the selection
        selectorElement.update(items: items, disabledItems: Set([items[2]]))
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

    func verify(_ element: SegmentedSelectorElement, darkMode: Bool = false) {
        let view = element.view
        // Let the view size itself based on its intrinsic content size
        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        view.bounds = CGRect(origin: .zero, size: size)

        if darkMode {
            let window = UIWindow(frame: view.bounds)
            window.overrideUserInterfaceStyle = .dark
            window.isHidden = false
            window.addSubview(view)
            window.layoutIfNeeded()
            STPSnapshotVerifyView(view)
        } else {
            view.layoutIfNeeded()
            STPSnapshotVerifyView(view)
        }
    }
}

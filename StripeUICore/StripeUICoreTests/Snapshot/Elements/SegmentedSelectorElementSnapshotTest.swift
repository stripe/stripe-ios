//
//  SegmentedSelectorElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Joyce Qin on 3/1/26.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore
import StripePaymentsUI

final class SegmentedSelectorElementSnapshotTest: STPSnapshotTestCase {
    let items: [SegmentedSelectorItem] = {
        let brandNames = ["visa", "mastercard", "amex"]
        return brandNames.map { brand in
            let image = STPImageLibrary.cardBrandImage(for: STPCard.brand(from: brand))
            return SegmentedSelectorItem(
                rawData: brand,
                image: image,
                accessibilityLabel: brand.capitalized
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

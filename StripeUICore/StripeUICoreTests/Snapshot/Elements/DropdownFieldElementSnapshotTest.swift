//
//  DropdownFieldElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

final class DropdownFieldElementSnapshotTest: FBSnapshotTestCase {
    let items = ["A", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testDefault0() {
        let dropdownFieldElement = makeDropdownFieldElement(
            defaultIndex: 0
        )
        verify(dropdownFieldElement)
    }

    func testDefault3() {
        let dropdownFieldElement = makeDropdownFieldElement(
            defaultIndex: 3
        )
        verify(dropdownFieldElement)
    }

    func testChangeInput() {
        let dropdownFieldElement = makeDropdownFieldElement(
            defaultIndex: 0
        )
        // Emulate a user changing the picker
        dropdownFieldElement.pickerView(dropdownFieldElement.pickerView, didSelectRow: 3, inComponent: 0)
        verify(dropdownFieldElement)
    }
}

private extension DropdownFieldElementSnapshotTest {
    func makeDropdownFieldElement(
        defaultIndex: Int
    ) -> DropdownFieldElement {
        return DropdownFieldElement(
            items: items,
            defaultIndex: defaultIndex,
            label: "Label"
        )
    }

    func verify(_ dropdownFieldElement: DropdownFieldElement,
                file: StaticString = #filePath,
                line: UInt = #line) {
        let view = dropdownFieldElement.view
        view.autosizeHeight(width: 200)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

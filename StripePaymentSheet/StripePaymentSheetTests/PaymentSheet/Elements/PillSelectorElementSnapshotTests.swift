//
//  PillSelectorElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/20/26.

import StripeCoreTestUtils
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import UIKit

final class PillSelectorElementSnapshotTests: STPSnapshotTestCase {
    var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()

    func testLeftSelected() {
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "a")
        verify(element)
    }

    func testRightSelected() {
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "b")
        verify(element)
    }

    func testWithCaption() {
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "a", caption: "Helpful context below the pills")
        verify(element)
    }

    func testDisabled() {
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "a")
        element.setEnabled(false)
        verify(element)
    }

    func testDarkMode() {
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "b", caption: "Dark mode caption")
        verify(element, darkMode: true)
    }

    func testCustomAppearance() {
        appearance = ._testMSPaintTheme
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "a", caption: "Custom theme")
        verify(element)
    }

}

private extension PillSelectorElementSnapshotTests {
    func makeElement(
        left: (String, String),
        right: (String, String),
        selectedId: String,
        caption: String? = nil
    ) -> PillSelectorElement {
        PillSelectorElement(
            leftItem: PillSelectorItem(id: left.0, displayText: left.1),
            rightItem: PillSelectorItem(id: right.0, displayText: right.1),
            selectedItemId: selectedId,
            caption: caption,
            appearance: appearance
        )
    }

    func verify(
        _ element: PillSelectorElement,
        darkMode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = element.view
        view.backgroundColor = appearance.colors.background

        if darkMode {
            let container = UIView()
            container.overrideUserInterfaceStyle = .dark
            container.addSubview(view)
        }

        view.autosizeHeight(width: 320)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

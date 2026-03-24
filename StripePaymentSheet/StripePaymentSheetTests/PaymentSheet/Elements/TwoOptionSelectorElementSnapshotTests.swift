//
//  TwoOptionSelectorElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/20/26.

import StripeCoreTestUtils
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import UIKit
// @iOS26
// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
final class TwoOptionSelectorElementSnapshotTests: STPSnapshotTestCase {
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
        let element = makeElement(left: ("a", "Option A"), right: ("b", "Option B"), selectedId: "a", caption: "Helpful context below the selector")
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

private extension TwoOptionSelectorElementSnapshotTests {
    func makeElement(
        left: (String, String),
        right: (String, String),
        selectedId: String,
        caption: String? = nil
    ) -> TwoOptionSelectorElement {
        TwoOptionSelectorElement(
            leftItem: TwoOptionSelectorItem(id: left.0, displayText: left.1, accessibilityIdentifier: "option_\(left.0)"),
            rightItem: TwoOptionSelectorItem(id: right.0, displayText: right.1, accessibilityIdentifier: "option_\(right.0)"),
            selectedItemId: selectedId,
            caption: caption,
            appearance: appearance
        )
    }

    func verify(
        _ element: TwoOptionSelectorElement,
        darkMode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = element.view
        view.backgroundColor = appearance.colors.background
        view.autosizeHeight(width: 320)

        if darkMode {
            let window = UIWindow(frame: view.bounds)
            window.overrideUserInterfaceStyle = .dark
            window.isHidden = false
            view.translatesAutoresizingMaskIntoConstraints = true
            window.addSubview(view)
            window.layoutIfNeeded()
        }

        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

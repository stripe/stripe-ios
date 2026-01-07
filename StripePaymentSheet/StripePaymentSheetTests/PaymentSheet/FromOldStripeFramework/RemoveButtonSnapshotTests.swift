//
//  RemoveButtonSnapshotTests.swift
//  StripeiOSTests
//
//  Created by George Birch on 9/4/25.
//

import Foundation
import StripeCoreTestUtils
import UIKit
import XCTest
@testable@_spi(STP) import StripePaymentSheet


// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
// @iOS26
class RemoveButtonSnapshotTests: STPSnapshotTestCase {

    func testRemoveButton() {
        let removeButton = RemoveButton(appearance: .default.applyingLiquidGlassIfPossible())
        verify(removeButton)
    }

    func testRemoveButtonCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 0.85

        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton)
    }

    func testRemoveButtonCustomSheetBackgroundAndDanger() {
        var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()
        appearance.colors.danger = .orange
        appearance.colors.background = .gray
        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton)
    }

    func testRemoveButtonCustomZeroCornerRadius() {
        var appearance = PaymentSheet.Appearance().applyingLiquidGlassIfPossible()
        appearance.cornerRadius = 0
        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        mode: UIUserInterfaceStyle = .light,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // The remove button relies on external constraints to size itself, so we manually set dimensions for testing
        view.bounds = CGRect(x: 0, y: 0, width: 300, height: 44)

        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

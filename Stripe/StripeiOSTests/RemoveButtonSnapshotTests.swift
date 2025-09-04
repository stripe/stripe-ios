//
//  RemoveButtonSnapshotTests.swift
//  StripeiOSTests
//
//  Created by George Birch on 9/4/25.
//

import Foundation
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripePaymentSheet

class RemoveButtonSnapshotTests: STPSnapshotTestCase {

    func testRemoveButton() {
        let removeButton = RemoveButton()
        verify(removeButton)
    }

    func testRemoveButtonDark() {
        let removeButton = RemoveButton()
        verify(removeButton, mode: .dark)
    }

    func testRemoveButtonCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance()
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 0.85

        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton)
    }

    func testRemoveButtonCustomFontScalesDark() throws {
        var appearance = PaymentSheet.Appearance()
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 0.85

        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton, mode: .dark)
    }

    func testRemoveButtonCustomSheetBackgroundAndDanger() {
        var appearance = PaymentSheet.Appearance()
        appearance.colors.danger = .orange
        appearance.colors.background = .gray
        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton)
    }

    func testRemoveButtonCustomSheetBackgroundAndDangerDark() {
        var appearance = PaymentSheet.Appearance()
        appearance.colors.danger = .orange
        appearance.colors.background = .gray
        let removeButton = RemoveButton(appearance: appearance)
        verify(removeButton, mode: .dark)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        mode: UIUserInterfaceStyle = .light,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window.addSubview(view)
        window.isHidden = false

        if mode == .dark {
            window.overrideUserInterfaceStyle = .dark
        }

        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

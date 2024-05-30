//
//  RightAccessoryButtonSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 5/28/24.
//

import Foundation
import StripeCoreTestUtils
import UIKit
import XCTest

@testable@_spi(STP) import StripePaymentSheet

class RightAccessoryButtonSnapshotTests: STPSnapshotTestCase {

    func testRightAccessoryButtonSnapshotTests_viewMore() throws {
        let button = try XCTUnwrap(RowButton.RightAccessoryButton(accessoryType: .viewMore, appearance: .default))
        verify(button)
    }

    func testRightAccessoryButtonSnapshotTests_viewMore_customAppearance() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.primary = .red
        let button = try XCTUnwrap(RowButton.RightAccessoryButton(accessoryType: .viewMore, appearance: appearance))
        verify(button)
    }

    func testRightAccessoryButtonSnapshotTests_edit() throws {
        let button = try XCTUnwrap(RowButton.RightAccessoryButton(accessoryType: .edit, appearance: .default))
        verify(button)
    }

    func testRightAccessoryButtonSnapshotTests_edit_customAppearance() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.primary = .red
        let button = try XCTUnwrap(RowButton.RightAccessoryButton(accessoryType: .edit, appearance: appearance))
        verify(button)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

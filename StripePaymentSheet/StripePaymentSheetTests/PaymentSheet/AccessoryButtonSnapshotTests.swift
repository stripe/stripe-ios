//
//  AccessoryButtonSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 5/28/24.
//

import Foundation
import StripeCoreTestUtils
import UIKit
import XCTest

@testable@_spi(STP) import StripePaymentSheet

class AccessoryButtonSnapshotTests: STPSnapshotTestCase {

    func testAccessoryButtonSnapshotTests_none() {
        let button = AccessoryButton(accessoryType: .none, appearance: .default)
        XCTAssertNil(button)
    }

    func testAccessoryButtonSnapshotTests_viewMore() throws {
        let button = try XCTUnwrap(AccessoryButton(accessoryType: .viewMore, appearance: .default))
        verify(button)
    }

    func testAccessoryButtonSnapshotTests_viewMore_customAppearance() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.primary = .red
        let button = try XCTUnwrap(AccessoryButton(accessoryType: .viewMore, appearance: appearance))
        verify(button)
    }

    func testAccessoryButtonSnapshotTests_edit() throws {
        let button = try XCTUnwrap(AccessoryButton(accessoryType: .edit, appearance: .default))
        verify(button)
    }

    func testAccessoryButtonSnapshotTests_edit_customAppearance() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.colors.primary = .red
        let button = try XCTUnwrap(AccessoryButton(accessoryType: .edit, appearance: appearance))
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

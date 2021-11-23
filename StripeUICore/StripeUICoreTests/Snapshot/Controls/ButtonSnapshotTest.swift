//
//  ButtonSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Ramon Torres on 11/9/21.
//

import FBSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

final class ButtonSnapshotTest: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testPrimary() {
        let button = Button(title: "Send")
        verify(button)

        button.isHighlighted = true
        verify(button, identifier: "Highlighted")

        button.isHighlighted = false
        button.isEnabled = false
        verify(button, identifier: "Disabled")
    }

    func testSecondary() {
        let button = Button(style: .secondary, title: "Send")
        verify(button)

        button.isHighlighted = true
        verify(button, identifier: "Highlighted")

        button.isHighlighted = false
        button.isEnabled = false
        verify(button, identifier: "Disabled")
    }

    func testIcon() {
        let button = Button(title: "Add")
        button.directionalLayoutMargins = .insets(top: 16, leading: 16, bottom: 16, trailing: 16)

        button.icon = .mockIcon()
        verify(button, identifier: "Leading")

        button.iconPosition = .trailing
        verify(button, identifier: "Trailing")
    }

    func testColorCustomization() {
        let primaryButton = Button(style: .primary, title: "Delete")
        primaryButton.tintColor = .red
        primaryButton.font = .boldSystemFont(ofSize: 16)
        verify(primaryButton, identifier: "Primary")

        let secondaryButton = Button(style: .secondary, title: "Delete")
        secondaryButton.tintColor = .red
        secondaryButton.font = .boldSystemFont(ofSize: 16)
        verify(secondaryButton, identifier: "Secondary")
    }

    func testDisabledColorCustomization() {
        let button = Button(style: .primary, title: "Delete")
        button.disabledColor = .black
        button.isEnabled = false
        verify(button)
    }

    func verify(
        _ button: Button,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        button.autosizeHeight(width: 300)
        FBSnapshotVerifyView(button, identifier: identifier, file: file, line: line)
    }
}

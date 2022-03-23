//
//  ButtonSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Ramon Torres on 11/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) import StripeUICore

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
        let button = Button(configuration: .secondary(), title: "Send")
        verify(button)

        button.isHighlighted = true
        verify(button, identifier: "Highlighted")

        button.isHighlighted = false
        button.isEnabled = false
        verify(button, identifier: "Disabled")
    }

    func testPlain() {
        let button = Button(configuration: .plain(), title: "Cancel")
        verify(button)

        button.isHighlighted = true
        verify(button, identifier: "Highlighted")

        button.isHighlighted = false
        button.isEnabled = false
        verify(button, identifier: "Disabled")
    }

    func testIcon() {
        let button = Button(title: "Add")
        button.configuration.insets = .insets(top: 16, leading: 16, bottom: 16, trailing: 16)

        button.icon = .mockIcon()
        verify(button, identifier: "Leading")

        button.iconPosition = .trailing
        verify(button, identifier: "Trailing")
    }

    func testColorCustomization() {
        let primaryButton = Button(configuration: .primary(), title: "Delete")
        primaryButton.tintColor = .red
        verify(primaryButton, identifier: "Primary")

        let secondaryButton = Button(configuration: .secondary(), title: "Delete")
        secondaryButton.tintColor = .red
        verify(secondaryButton, identifier: "Secondary")
    }

    func testDisabledColorCustomization() {
        let button = Button(configuration: .primary(), title: "Delete")
        button.configuration.disabledBackgroundColor = .black
        button.isEnabled = false
        verify(button)
    }

    func testAttributedTitle() {
        let button = Button(title: "Hello")
        button.configuration.titleAttributes = [.underlineStyle: NSUnderlineStyle.single.rawValue]
        verify(button)
    }

    func testLoading() {
        let button = Button(title: "Save")
        button.isLoading = true
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

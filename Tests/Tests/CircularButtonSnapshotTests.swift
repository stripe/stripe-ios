//
//  CircularButtonSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 1/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe
@_spi(STP) import StripeUICore

@available(iOS 13.0, *)
class CircularButtonSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testNormal() {
        let button = CircularButton(style: .close)
        verify(button)
    }

    func testDisabled() {
        let button = CircularButton(style: .close)
        button.isEnabled = false
        verify(button)
    }

    func verify(
        _ button: CircularButton,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Ensures that the button shadow gets captured
        let wrapper = UIView()
        wrapper.addAndPinSubview(button, insets: .insets(top: 10, leading: 10, bottom: 10, trailing: 10))

        // Adding the view to a window updates the traits
        let window = UIWindow()
        window.addSubview(wrapper)

        let size = wrapper.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        wrapper.bounds = CGRect(origin: .zero, size: size)

        // Test light mode
        wrapper.overrideUserInterfaceStyle = .light
        FBSnapshotVerifyView(wrapper, identifier: identifier, file: file, line: line)

        // Test dark mode
        wrapper.overrideUserInterfaceStyle = .dark
        let updatedIdentifier = (identifier ?? "").appending("darkMode")
        FBSnapshotVerifyView(wrapper, identifier: updatedIdentifier, file: file, line: line)
    }

}

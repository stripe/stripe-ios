//
//  PayWithLinkButtonSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class PayWithLinkButtonSnapshotTests: FBSnapshotTestCase {

    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
    }

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testDefault() {
        let button = PayWithLinkButton()
        button.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: false
        )
        verify(button)

        button.isHighlighted = true
        verify(button, identifier: "Highlighted")
    }

    func testDisabled() {
        let button = PayWithLinkButton()
        button.isEnabled = false
        verify(button)
    }

    func testLoggedIn() {
        let button = PayWithLinkButton()
        button.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(button)
    }

    func testLoggedInWithLongEmailAddress() {
        let button = PayWithLinkButton()
        button.linkAccount = LinkAccountStub(
            email: "long.customer.name@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(button)
    }

    func verify(
        _ button: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        button.autosizeHeight(width: 300)
        FBSnapshotVerifyView(button, identifier: identifier, file: file, line: line)
    }

}

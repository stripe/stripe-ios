//
//  WalletHeaderViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class WalletHeaderViewSnapshotTests: FBSnapshotTestCase {

    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
    }

    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }

    func testApplePayButton() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            delegate: nil
        )
        verify(headerView)
    }

    func testLinkButton() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .link,
            delegate: nil
        )
        verify(headerView)

        headerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(headerView, identifier: "Logged in")
    }

    func testAllButtons() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            delegate: nil
        )
        verify(headerView)

        headerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(headerView, identifier: "Logged in")

        headerView.showsCardPaymentMessage = true
        verify(headerView, identifier: "Card only")
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

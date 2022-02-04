//
//  LinkWalletFooterViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 1/13/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class LinkWalletFooterViewSnapshotTests: FBSnapshotTestCase {

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
        let footerView = LinkWalletFooterView()
        footerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(footerView)
    }

    func testLongEmailAddress() {
        let footerView = LinkWalletFooterView()
        footerView.linkAccount = LinkAccountStub(
            email: "long.customer.name@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(footerView)
    }

    func verify(
        _ footer: LinkWalletFooterView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        footer.autosizeHeight(width: 300)
        FBSnapshotVerifyView(footer, identifier: identifier, file: file, line: line)
    }

}

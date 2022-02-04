//
//  Link2FAViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class Link2FAViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testModal() {
        let twoFactorAuthView = Link2FAView(mode: .modal, redactedPhoneNumber: "+1********55")
        twoFactorAuthView.tintColor = .linkBrand
        verify(twoFactorAuthView)
    }

    func testInline() {
        let twoFactorAuthView = Link2FAView(mode: .inline, redactedPhoneNumber: "+1********55")
        twoFactorAuthView.tintColor = .linkBrand
        verify(twoFactorAuthView)
    }

    func verify(
        _ view: Link2FAView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 340)
        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

}

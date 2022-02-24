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
        let sut = makeSUT(mode: .modal)
        verify(sut)
    }

    func testInlineLogin() {
        let sut = makeSUT(mode: .inlineLogin)
        verify(sut)
    }

    func testEmbedded() {
        let sut = makeSUT(mode: .embedded)
        verify(sut)
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

extension Link2FAViewSnapshotTests {

    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
    }

    func makeSUT(mode: Link2FAView.Mode) -> Link2FAView {
        let sut = Link2FAView(
            mode: mode,
            linkAccount: LinkAccountStub(
                email: "user@example.com",
                redactedPhoneNumber: "+1********55",
                isRegistered: true
            )
        )

        sut.tintColor = .linkBrand

        return sut
    }

}

//
//  LinkVerificationViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class LinkVerificationViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testModal() {
        let sut = makeSUT(mode: .modal)
        verify(sut)
    }

    func testModalWithErrorMessage() {
        let sut = makeSUT(mode: .modal)
        sut.errorMessage = "The provided verification code has expired."
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
        _ view: LinkVerificationView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

}

extension LinkVerificationViewSnapshotTests {

    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let isLoggedIn: Bool
    }

    func makeSUT(mode: LinkVerificationView.Mode) -> LinkVerificationView {
        let sut = LinkVerificationView(
            mode: mode,
            linkAccount: LinkAccountStub(
                email: "user@example.com",
                redactedPhoneNumber: "+1********55",
                isRegistered: true,
                isLoggedIn: false
            )
        )

        sut.tintColor = .linkBrand

        return sut
    }

}

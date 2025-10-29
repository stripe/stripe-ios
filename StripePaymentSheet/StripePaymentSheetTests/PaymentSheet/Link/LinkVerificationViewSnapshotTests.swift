//
//  LinkVerificationViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore

class LinkVerificationViewSnapshotTests: STPSnapshotTestCase {

    func testModal() {
        let sut = makeSUT(mode: .modal)
        verify(sut)
    }

    func testModalWithLogout() {
        let sut = makeSUT(mode: .modal, allowLogoutInDialog: true)
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

    func testEmbeddedWithInput() {
        let sut = makeSUT(mode: .embedded)
        sut.codeField.value = "1234"
        verify(sut)
    }

    func testCustomColors() {
        let appearance = LinkAppearance(
            colors: .init(
                primary: .systemTeal,
                selectedBorder: .red
            )
        )
        let sut = makeSUT(mode: .modal, appearance: appearance)
        sut.codeField.value = "1234"
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
        let sessionState: PaymentSheetLinkAccount.SessionState
        let consumerSessionClientSecret: String?
    }

    func makeSUT(mode: LinkVerificationView.Mode, appearance: LinkAppearance? = nil, allowLogoutInDialog: Bool = false) -> LinkVerificationView {
        let sut = LinkVerificationView(
            mode: mode,
            linkAccount: LinkAccountStub(
                email: "user@example.com",
                redactedPhoneNumber: "(•••) ••• ••55",
                isRegistered: true,
                sessionState: .verified,
                consumerSessionClientSecret: nil
            ),
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog
        )

        sut.tintColor = .linkIconBrand

        return sut
    }

}

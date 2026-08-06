//
//  PayWithLinkButtonSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import UIKit

@MainActor
final class PayWithLinkButtonSnapshotTests: STPSnapshotTestCase {
    private struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let sessionState: PaymentSheetLinkAccount.SessionState
        let consumerSessionClientSecret: String?
    }

    func testLoggedOutLink() {
        verify(brand: .link, identifier: "logged_out_link")
    }

    func testLoggedOutOnelink() {
        verify(brand: .onelink, identifier: "logged_out_onelink")
    }

    func testLoggedInShortEmailLink() {
        verify(
            brand: .link,
            email: "user@example.com",
            identifier: "logged_in_short_email_link"
        )
    }

    func testLoggedInLongEmailLink() {
        verify(
            brand: .link,
            email: "this.is.a.very.long.email.address@example.com",
            identifier: "logged_in_long_email_link"
        )
    }

    func testLoggedInShortEmailOnelink() {
        verify(
            brand: .onelink,
            email: "user@example.com",
            identifier: "logged_in_short_email_onelink"
        )
    }

    func testLoggedInLongEmailOnelink() {
        verify(
            brand: .onelink,
            email: "this.is.a.very.long.email.address@example.com",
            identifier: "logged_in_long_email_onelink"
        )
    }

    private func verify(
        brand: LinkBrand,
        email: String? = nil,
        identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = PayWithLinkButton(brand: brand)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 260, height: 44))

        if let email {
            button.linkAccount = LinkAccountStub(
                email: email,
                redactedPhoneNumber: nil,
                isRegistered: true,
                sessionState: .verified,
                consumerSessionClientSecret: nil
            )
        }

        button.layoutIfNeeded()
        STPSnapshotVerifyView(button, identifier: identifier, file: file, line: line)
    }
}

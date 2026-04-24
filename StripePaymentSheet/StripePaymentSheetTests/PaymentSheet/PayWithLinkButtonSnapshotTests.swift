//
//  PayWithLinkButtonSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import UIKit

final class PayWithLinkButtonSnapshotTests: STPSnapshotTestCase {

    private let emailAddress = "customer@example.com"

    func testDefault() {
        let sut = makeSUT()
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: false)
        verify(sut)
    }

    func testDefault_notlink() {
        let sut = makeSUT(brand: .notlink)
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: false)
        verify(sut)
    }

    private func verify(
        _ sut: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.autosizeHeight(width: 300)
        STPSnapshotVerifyView(sut, identifier: identifier, file: file, line: line)
    }
}

private extension PayWithLinkButtonSnapshotTests {
    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let isRegistered: Bool
        var redactedPhoneNumber: String?
        let sessionState: PaymentSheetLinkAccount.SessionState
        let consumerSessionClientSecret: String?
    }

    func makeAccountStub(email: String, isRegistered: Bool) -> LinkAccountStub {
        LinkAccountStub(
            email: email,
            isRegistered: isRegistered,
            redactedPhoneNumber: "+1********55",
            sessionState: .verified,
            consumerSessionClientSecret: nil
        )
    }

    func makeSUT(brand: LinkBrand = .link) -> PayWithLinkButton {
        PayWithLinkButton(brand: brand)
    }
}

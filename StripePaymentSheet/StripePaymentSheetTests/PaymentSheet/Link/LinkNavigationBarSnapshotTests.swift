//
//  LinkNavigationBarSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 4/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class LinkNavigationBarSnapshotTests: STPSnapshotTestCase {

    func testDefault() {
        let sut = makeSUT()
        verify(sut)

        let backSut = makeSUT()
        backSut.setStyle(.back(showAdditionalButton: false))
        verify(backSut, identifier: "BackButton")
    }

    func testTitle() {
        let sut = makeSUT(title: "Test title")
        sut.setStyle(.back(showAdditionalButton: false))
        verify(sut)
    }

    func testLongTitle() {
        let sut = makeSUT(title: "Test title that is pretty long")
        sut.setStyle(.back(showAdditionalButton: false))
        verify(sut)
    }

    func testTruncatingTitle() {
        let sut = makeSUT(title: "Test title that is pretty long and should wrap")
        sut.setStyle(.back(showAdditionalButton: false))
        verify(sut)
    }

    func verify(
        _ sut: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = sut.systemLayoutSizeFitting(
            CGSize(width: 375, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        sut.bounds = CGRect(origin: .zero, size: size)
        STPSnapshotVerifyView(sut, identifier: identifier, file: file, line: line)
    }

}

extension LinkNavigationBarSnapshotTests {
    fileprivate struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let sessionState: PaymentSheetLinkAccount.SessionState
        let consumerSessionClientSecret: String?
    }

    fileprivate func makeAccountStub() -> LinkAccountStub {
        return LinkAccountStub(
            email: "test@example.com",
            redactedPhoneNumber: "+1********55",
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: nil
        )
    }

    fileprivate func makeSUT(title: String? = nil) -> LinkSheetNavigationBar {
        let sut = LinkSheetNavigationBar(isTestMode: false, appearance: .init())
        sut.title = title
        return sut
    }
}

//
//  LinkNavigationBarSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 4/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase

@testable import Stripe

class LinkNavigationBarSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testDefault() {
        let sut = makeSUT()
        verify(sut)

        sut.showBackButton = true
        verify(sut, identifier: "BackButton")
    }

    func testWithEmailAddress() {
        let sut = makeSUT()
        sut.linkAccount = makeAccountStub(email: "user@example.com")
        verify(sut)

        sut.showBackButton = true
        verify(sut, identifier: "BackButton")
    }

    func testWithLongEmailAddress() {
        let sut = makeSUT()
        sut.linkAccount = makeAccountStub(email: "a.very.very.long.customer.name@example.com")
        verify(sut)

        sut.showBackButton = true
        verify(sut, identifier: "BackButton")
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

private extension LinkNavigationBarSnapshotTests {
    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let isLoggedIn: Bool
    }

    func makeAccountStub(email: String) -> LinkAccountStub {
        return LinkAccountStub(
            email: email,
            redactedPhoneNumber: "+1********55",
            isRegistered: true,
            isLoggedIn: true
        )
    }

    func makeSUT() -> LinkNavigationBar {
        return LinkNavigationBar()
    }
}

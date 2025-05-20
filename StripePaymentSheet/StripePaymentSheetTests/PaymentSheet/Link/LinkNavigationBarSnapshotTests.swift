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
    }

    fileprivate func makeAccountStub() -> LinkAccountStub {
        return LinkAccountStub(
            email: "test@example.com",
            redactedPhoneNumber: "+1********55",
            isRegistered: true
        )
    }

    fileprivate func makeSUT() -> LinkSheetNavigationBar {
        LinkSheetNavigationBar(isTestMode: false, appearance: .init())
    }
}

//
//  LinkBadgeViewSnapshotTest.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 4/29/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class LinkBadgeViewSnapshotTest: STPSnapshotTestCase {

    func testNeutral() {
        verify(
            LinkBadgeView(
                type: .neutral,
                text: "Neutral message"
            )
        )
    }

    func testError() {
        verify(
            LinkBadgeView(
                type: .error,
                text: "Error message"
            )
        )
    }

    func verify(
        _ sut: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = sut.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        sut.bounds = CGRect(origin: .zero, size: size)
        STPSnapshotVerifyView(sut, identifier: identifier, file: file, line: line)
    }

}

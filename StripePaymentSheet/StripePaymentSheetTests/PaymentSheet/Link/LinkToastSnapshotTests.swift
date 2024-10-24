//
//  LinkToastSnapshotTests.swift
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

class LinkToastSnapshotTests: STPSnapshotTestCase {

    func testSuccess() {
        let toast = LinkToast(type: .success, text: "Success message!")
        verify(toast)
    }

    func verify(
        _ toast: LinkToast,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = toast.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        toast.bounds = CGRect(origin: .zero, size: size)
        STPSnapshotVerifyView(toast, identifier: identifier, file: file, line: line)
    }

}

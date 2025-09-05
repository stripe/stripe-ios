//
//  LinkHintMessageViewSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/14/25.
//

import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

// @iOS26
class LinkHintMessageViewSnapshotTests: STPSnapshotTestCase {

    func testNormalLengthMessage() {
        let hintView = LinkHintMessageView(message: "Debit is most likely to be accepted.")
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }

    func testLongMessageWithWrapping() {
        let hintView = LinkHintMessageView(message: "This is a much longer message that should definitely wrap to multiple lines")
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }
}

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

    override static func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testNormalLengthMessage() {
        let hintView = LinkHintMessageView(message: "Debit is most likely to be accepted.", style: .filled)
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }

    func testLongMessageWithWrapping() {
        recordMode = true
        let hintView = LinkHintMessageView(message: "This is a much longer message that should definitely wrap to multiple lines", style: .filled)
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }

    func testOutlinedStyle() {
        let hintView = LinkHintMessageView(message: "This is your default payment method.", style: .outlined)
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }

    func testNormalLengthMessageErrorStyle() {
        let hintView = LinkHintMessageView(message: "Debit is most likely to be accepted.", style: .error)
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }

    func testLongMessageWithWrappingErrorStyle() {
        recordMode = true
        let hintView = LinkHintMessageView(message: "This is a much longer message that should definitely wrap to multiple lines", style: .error)
        hintView.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
        hintView.layoutIfNeeded()

        STPSnapshotVerifyView(hintView)
    }

}

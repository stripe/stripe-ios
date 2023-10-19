//
//  PaymentSheetFlowControllerViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet

import XCTest

final class PaymentSheetFlowControllerViewControllerSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testSavedScreen_card() {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            configuration: ._testValue_MostPermissive(),
            isApplePayEnabled: false,
            isLinkEnabled: false
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_us_bank_account() {
        let paymentMethods = [
            STPPaymentMethod._testUSBankAccount(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            configuration: ._testValue_MostPermissive(),
            isApplePayEnabled: false,
            isLinkEnabled: false
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_SEPA_debit() {
        let paymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            configuration: ._testValue_MostPermissive(),
            isApplePayEnabled: false,
            isLinkEnabled: false
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}

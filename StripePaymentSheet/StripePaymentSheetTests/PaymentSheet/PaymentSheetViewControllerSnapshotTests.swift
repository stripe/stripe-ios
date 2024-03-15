//
//  PaymentSheetViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet

import XCTest

final class PaymentSheetViewControllerSnapshotTests: STPSnapshotTestCase {

    func testSavedScreen_card() {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
        ]
        let sut = PaymentSheetViewController(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            configuration: ._testValue_MostPermissive(),
            isApplePayEnabled: false,
            isLinkEnabled: false,
            isCVCRecollectionEnabled: false,
            delegate: self
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_us_bank_account() {
        let paymentMethods = [
            STPPaymentMethod._testUSBankAccount(),
        ]
        let sut = PaymentSheetViewController(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            configuration: ._testValue_MostPermissive(),
            isApplePayEnabled: false,
            isLinkEnabled: false,
            isCVCRecollectionEnabled: false,
            delegate: self
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_SEPA_debit() {
        let paymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        let sut = PaymentSheetViewController(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            configuration: ._testValue_MostPermissive(),
            isApplePayEnabled: false,
            isLinkEnabled: false,
            isCVCRecollectionEnabled: false,
            delegate: self
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}

extension PaymentSheetViewControllerSnapshotTests: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerFinishedOnPay(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerCanceledOnPay(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerFailedOnPay(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController, result: StripePaymentSheet.PaymentSheetResult, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerShouldConfirm(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController, with paymentOption: StripePaymentSheet.PaymentOption, completion: @escaping (StripePaymentSheet.PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
    }

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController, result: StripePaymentSheet.PaymentSheetResult) {
    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController) {
    }

    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewController) {
    }
}

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
    func makeTestLoadResult(savedPaymentMethods: [STPPaymentMethod]) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testValue(),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)]
        )
    }

    func testSavedScreen_card() {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
        ]
        let sut = PaymentSheetViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue(),
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
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue(),
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
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue(),
            delegate: self
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}

extension PaymentSheetViewControllerSnapshotTests: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerFinishedOnPay(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerCanceledOnPay(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerFailedOnPay(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol, result: StripePaymentSheet.PaymentSheetResult, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerShouldConfirm(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol, with paymentOption: StripePaymentSheet.PaymentOption, completion: @escaping (StripePaymentSheet.PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
    }

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol, result: StripePaymentSheet.PaymentSheetResult) {
    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol) {
    }

    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: StripePaymentSheet.PaymentSheetViewControllerProtocol) {
    }
}

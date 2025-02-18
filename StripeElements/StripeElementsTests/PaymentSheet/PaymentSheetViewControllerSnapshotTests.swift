//
//  PaymentSheetViewControllerSnapshotTests.swift
//  StripeElementsTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripeElements

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
    func paymentSheetViewControllerFinishedOnPay(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerCanceledOnPay(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerFailedOnPay(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol, result: StripeElements.PaymentSheetResult, completion: (() -> Void)?) {
    }
    func paymentSheetViewControllerShouldConfirm(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol, with paymentOption: StripeElements.PaymentOption, completion: @escaping (StripeElements.PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
    }

    func paymentSheetViewControllerDidFinish(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol, result: StripeElements.PaymentSheetResult) {
    }

    func paymentSheetViewControllerDidCancel(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol) {
    }

    func paymentSheetViewControllerDidSelectPayWithLink(_ paymentSheetViewController: StripeElements.PaymentSheetViewControllerProtocol) {
    }
}

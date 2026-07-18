//
//  PaymentSheetViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore

import XCTest

final class PaymentSheetViewControllerSnapshotTests: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func makeTestLoadResult(savedPaymentMethods: [STPPaymentMethod]) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testValue(),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
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
            delegate: self,
            previousPaymentOption: nil
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
            delegate: self,
            previousPaymentOption: nil
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
            delegate: self,
            previousPaymentOption: nil
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    @MainActor
    func testPreviousNewPaymentMethodInputIsPreserved() throws {
        // Given completed card input and a saved method that would otherwise show the saved-method screen
        let confirmParams = IntentConfirmParams(
            params: ._testValidCardValue(),
            type: .stripe(.card)
        )
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: [._testUSBankAccount()],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )
        let sut = PaymentSheetViewController(
            configuration: PaymentSheet.Configuration(),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            delegate: self,
            previousPaymentOption: .new(confirmParams: confirmParams)
        )

        // When the controller is rebuilt
        sut.loadViewIfNeeded()

        // Then it shows the new-payment form with the previous input
        let cardForm = try XCTUnwrap(sut.formCache[.stripe(.card)])
        XCTAssertEqual(
            cardForm.getTextFieldElement("Card number")?.text,
            confirmParams.paymentMethodParams.card?.number
        )
    }

    @MainActor
    func testPreviousExternalPaymentMethodDoesNotReplaceSavedScreen() throws {
        // Given a saved method and a previous external payment method
        let externalPaymentMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/paypal.png")!,
            darkImageUrl: nil
        )
        let externalConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: [externalPaymentMethod.type],
            externalPaymentMethodConfirmHandler: { _, _ in .completed }
        )
        let externalPaymentOption = try XCTUnwrap(
            ExternalPaymentOption.from(externalPaymentMethod, configuration: externalConfiguration)
        )
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.externalPaymentMethodConfiguration = externalConfiguration
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testValue(),
            elementsSession: ._testValue(
                paymentMethodTypes: ["card"],
                externalPaymentMethodTypes: [externalPaymentMethod.type]
            ),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card), .external(externalPaymentOption)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )
        let sut = PaymentSheetViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            delegate: self,
            previousPaymentOption: .external(
                paymentMethod: externalPaymentOption,
                billingDetails: .init()
            )
        )

        // When the controller is rebuilt
        sut.loadViewIfNeeded()

        // Then it continues to show the saved-method screen instead of the external-payment form
        XCTAssertTrue(
            !sut.navigationBar.closeButtonLeft.isHidden || !sut.navigationBar.closeButtonRight.isHidden
        )
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

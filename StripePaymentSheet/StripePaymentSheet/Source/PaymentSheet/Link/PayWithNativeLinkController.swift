//
//  PayWithLinkController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// Standalone Link controller
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
final class PayWithNativeLinkController {

    typealias CompletionBlock = PaymentSheetResultCompletionBlock

    private let paymentHandler: STPPaymentHandler

    private var completion: PaymentSheetResultCompletionBlock?

    private var selfRetainer: PayWithNativeLinkController?

    let intent: Intent
    let elementsSession: STPElementsSession
    let configuration: PaymentElementConfiguration
    let analyticsHelper: PaymentSheetAnalyticsHelper

    init(intent: Intent, elementsSession: STPElementsSession, configuration: PaymentElementConfiguration, analyticsHelper: PaymentSheetAnalyticsHelper) {
        self.intent = intent
        self.elementsSession = elementsSession
        self.configuration = configuration
        self.analyticsHelper = analyticsHelper
        self.paymentHandler = .init(apiClient: configuration.apiClient)
    }

    func present(on viewController: UIViewController, completion: @escaping CompletionBlock) {
        present(from: viewController, completion: completion)
    }

    func presentAsBottomSheet(from presentingController: UIViewController,
                              shouldOfferApplePay: Bool,
                              shouldFinishOnClose: Bool,
                              completion: @escaping PaymentSheetResultCompletionBlock) {
        self.selfRetainer = self


        let payWithLinkVC = PayWithLinkViewController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            shouldOfferApplePay: shouldOfferApplePay,
            shouldFinishOnClose: shouldFinishOnClose,
            analyticsHelper: self.analyticsHelper
        )

        payWithLinkVC.payWithLinkDelegate = self


        presentingController.presentAsBottomSheet(
            payWithLinkVC.bottomSheetViewController,
            appearance: self.configuration.appearance,
            completion: {}
        )
        payWithLinkVC.load()

        self.completion =  { status, result in
            payWithLinkVC.bottomSheetViewController.dismiss(animated: true)
            completion(status, result)
        }
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) {
        // Similarly to `PKPaymentAuthorizationController`, `LinkController` should retain
        // itself while presented.
        self.selfRetainer = self
        self.completion = completion

        let payWithLinkViewController = PayWithLinkViewController(intent: intent,
                                                                  elementsSession: elementsSession, configuration: configuration, analyticsHelper: analyticsHelper)
        payWithLinkViewController.payWithLinkDelegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            payWithLinkViewController.modalPresentationStyle = .formSheet
        }
        payWithLinkViewController.isModalInPresentation = true

        presentingController.present(payWithLinkViewController, animated: true)
    }

}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PayWithNativeLinkController: PayWithLinkViewControllerDelegate {

    func payWithLinkViewControllerDidConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: payWithLinkViewController,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            analyticsHelper: analyticsHelper,
            completion: completion
        )
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        payWithLinkViewController.dismiss(animated: true)
        completion?(.canceled, nil)
        selfRetainer = nil
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        payWithLinkViewController.dismiss(animated: true)
        completion?(result, deferredIntentConfirmationType)
        selfRetainer = nil
    }

}

// Used if the native controlled falls back to the web controller
// We may want to refactor this someday to merge PayWithNativeLinkController and PayWithWebLinkController.
extension PayWithNativeLinkController: PayWithLinkWebControllerDelegate {
    func payWithLinkWebControllerDidComplete(
        _ payWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption
    ) {
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: payWithLinkWebController,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            integrationShape: .complete,
            analyticsHelper: analyticsHelper
        ) { result, deferredIntentConfirmationType in
            self.completion?(result, deferredIntentConfirmationType)
            self.selfRetainer = nil
        }
    }

    func payWithLinkWebControllerDidCancel() {
        completion?(.canceled, nil)
        selfRetainer = nil
    }
}

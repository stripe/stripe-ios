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

    private let paymentHandler: STPPaymentHandler

    private var completion: ((PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?, _ didFinish: Bool) -> Void)?

    private var selfRetainer: PayWithNativeLinkController?

    let intent: Intent
    let elementsSession: STPElementsSession
    let configuration: PaymentElementConfiguration
    let logPayment: Bool
    let analyticsHelper: PaymentSheetAnalyticsHelper

    init(intent: Intent,
         elementsSession: STPElementsSession,
         configuration: PaymentElementConfiguration,
         logPayment: Bool = true,
         analyticsHelper: PaymentSheetAnalyticsHelper) {
        self.intent = intent
        self.logPayment = logPayment
        self.elementsSession = elementsSession
        self.configuration = configuration
        self.analyticsHelper = analyticsHelper
        self.paymentHandler = .init(apiClient: configuration.apiClient)
    }

    func presentAsBottomSheet(from presentingController: UIViewController,
                              shouldOfferApplePay: Bool,
                              hidingUnderlyingBottomSheet: Bool = true,
                              shouldFinishOnClose: Bool,
                              completion: @escaping ((PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?, _ didFinish: Bool) -> Void)) {
        self.selfRetainer = self

        let targetBottomSheet = presentingController as? BottomSheetViewController ?? presentingController.bottomSheetController
        let targetPresentationController = targetBottomSheet?.presentingViewController

        let presentBottomSheet: (UIViewController) -> Void = { presentingController in
            let payWithLinkVC = PayWithLinkViewController(
                intent: self.intent,
                linkAccount: LinkAccountContext.shared.account,
                elementsSession: self.elementsSession,
                configuration: self.configuration,
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: shouldFinishOnClose,
                analyticsHelper: self.analyticsHelper
            )

            payWithLinkVC.payWithLinkDelegate = self
            presentingController.presentAsBottomSheet(
                payWithLinkVC,
                appearance: self.configuration.appearance,
                completion: {}
            )

            self.completion =  { result, status, didFinish in
                payWithLinkVC.dismiss(animated: true)
                completion(result, status, didFinish)
                if case .completed = result {
                    return
                }
                // Handle representing the previous bottom sheet
                if let targetBottomSheet, let targetPresentationController, hidingUnderlyingBottomSheet {
                    targetPresentationController.presentAsBottomSheet(targetBottomSheet, appearance: self.configuration.appearance)
                }
            }
        }

        // Dismiss the underlying bottom sheet
        if let targetBottomSheet, let targetPresentationController, hidingUnderlyingBottomSheet {
            targetBottomSheet.dismiss(animated: true) {
                presentBottomSheet(targetPresentationController)
            }
        } else {
            presentBottomSheet(presentingController)
        }
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
            completion: { result, confirmationType in
                if self.logPayment {
                    self.analyticsHelper.logPayment(paymentOption: paymentOption, result: result, deferredIntentConfirmationType: confirmationType)
                }
                completion(result, confirmationType)
            }
        )
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        payWithLinkViewController.dismiss(animated: true)
        completion?(.canceled, nil, false)
        selfRetainer = nil
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        payWithLinkViewController.dismiss(animated: true)
        completion?(result, deferredIntentConfirmationType, true)
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
            self.completion?(result, deferredIntentConfirmationType, true)
            self.selfRetainer = nil
        }
    }

    func payWithLinkWebControllerDidCancel() {
        completion?(.canceled, nil, false)
        selfRetainer = nil
    }
}

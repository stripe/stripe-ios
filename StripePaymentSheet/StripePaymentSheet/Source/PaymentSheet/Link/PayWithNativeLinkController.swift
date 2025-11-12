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

    enum Mode {
        case full
        case paymentMethodSelection
    }

    enum CompletionResult {
        case full(
            result: PaymentSheetResult,
            deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?,
            didFinish: Bool
        )
        case paymentMethodSelection(
            confirmOption: PaymentSheet.LinkConfirmOption?,
            shouldReturnToPaymentSheet: Bool = false
        )

        var shouldShowPaymentSheetAgain: Bool {
            switch self {
            case .full(let result, _, _):
                return result.isCanceledOrFailed
            case .paymentMethodSelection(let confirmOption, _):
                return confirmOption == nil
            }
        }
    }

    private let paymentHandler: STPPaymentHandler

    private var completion: ((CompletionResult) -> Void)?

    private var selfRetainer: PayWithNativeLinkController?

    let mode: Mode
    let intent: Intent
    let elementsSession: STPElementsSession
    let configuration: PaymentElementConfiguration
    let logPayment: Bool
    let analyticsHelper: PaymentSheetAnalyticsHelper
    let supportedPaymentMethodTypes: [LinkPaymentMethodType]

    private let linkAppearance: LinkAppearance?
    private let linkConfiguration: LinkConfiguration?
    private let confirmationChallenge: ConfirmationChallenge?

    init(
        mode: Mode,
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        logPayment: Bool = true,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        supportedPaymentMethodTypes: [LinkPaymentMethodType] = LinkPaymentMethodType.allCases,
        linkAppearance: LinkAppearance? = nil,
        linkConfiguration: LinkConfiguration? = nil,
        confirmationChallenge: ConfirmationChallenge? = nil
    ) {
        self.mode = mode
        self.intent = intent
        self.logPayment = logPayment
        self.elementsSession = elementsSession
        self.configuration = configuration
        self.analyticsHelper = analyticsHelper
        self.supportedPaymentMethodTypes = supportedPaymentMethodTypes
        self.paymentHandler = .init(apiClient: configuration.apiClient)
        self.linkAppearance = linkAppearance
        self.linkConfiguration = linkConfiguration
        self.confirmationChallenge = confirmationChallenge
    }

    func presentAsBottomSheet(
        from presentingController: UIViewController,
        shouldOfferApplePay: Bool,
        hidingUnderlyingBottomSheet: Bool = true,
        shouldFinishOnClose: Bool,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?, _ didFinish: Bool) -> Void
    ) {
        presentAsBottomSheetInternal(
            from: presentingController,
            shouldOfferApplePay: shouldOfferApplePay,
            hidingUnderlyingBottomSheet: hidingUnderlyingBottomSheet,
            shouldFinishOnClose: shouldFinishOnClose,
            canSkipWalletAfterVerification: false // Only available for payment method selection,
        ) { completionResult in
            guard case .full(let result, let deferredIntentConfirmationType, let didFinish) = completionResult else {
                return
            }

            completion(result, deferredIntentConfirmationType, didFinish)
        }
    }

    func presentForPaymentMethodSelection(
        from presentingController: UIViewController,
        initiallySelectedPaymentDetailsID: String?,
        shouldShowSecondaryCta: Bool = true,
        canSkipWalletAfterVerification: Bool,
        completion: @escaping (_ confirmOption: PaymentSheet.LinkConfirmOption?, _ shouldReturnToPaymentSheet: Bool) -> Void
    ) {
        presentAsBottomSheetInternal(
            from: presentingController,
            shouldOfferApplePay: false,
            hidingUnderlyingBottomSheet: true,
            launchedFromFlowController: true,
            initiallySelectedPaymentDetailsID: initiallySelectedPaymentDetailsID,
            callToAction: .continue,
            shouldFinishOnClose: false,
            shouldShowSecondaryCta: shouldShowSecondaryCta,
            canSkipWalletAfterVerification: canSkipWalletAfterVerification
        ) { completionResult in
            guard case .paymentMethodSelection(let confirmOption, let shouldReturnToPaymentSheet) = completionResult else {
                return
            }

            completion(confirmOption, shouldReturnToPaymentSheet)
        }
    }

    private func presentAsBottomSheetInternal(
        from presentingController: UIViewController,
        shouldOfferApplePay: Bool,
        hidingUnderlyingBottomSheet: Bool = true,
        launchedFromFlowController: Bool = false,
        initiallySelectedPaymentDetailsID: String? = nil,
        callToAction: ConfirmButton.CallToActionType? = nil,
        shouldFinishOnClose: Bool,
        shouldShowSecondaryCta: Bool = true,
        canSkipWalletAfterVerification: Bool,
        completion: @escaping (CompletionResult) -> Void
    ) {
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
                shouldShowSecondaryCta: shouldShowSecondaryCta,
                launchedFromFlowController: launchedFromFlowController,
                initiallySelectedPaymentDetailsID: initiallySelectedPaymentDetailsID,
                canSkipWalletAfterVerification: canSkipWalletAfterVerification,
                callToAction: callToAction,
                analyticsHelper: self.analyticsHelper,
                supportedPaymentMethodTypes: self.supportedPaymentMethodTypes,
                linkAppearance: self.linkAppearance,
                linkConfiguration: self.linkConfiguration
            )

            payWithLinkVC.payWithLinkDelegate = self
            presentingController.presentAsBottomSheet(
                payWithLinkVC,
                appearance: self.configuration.appearance,
                completion: {}
            )

            self.completion =  { completionResult in
                payWithLinkVC.dismiss(animated: true) {
                    completion(completionResult)

                    guard completionResult.shouldShowPaymentSheetAgain else {
                        return
                    }
                    // Handle representing the previous bottom sheet
                    if let targetBottomSheet, let targetPresentationController, hidingUnderlyingBottomSheet {
                        targetPresentationController.presentAsBottomSheet(targetBottomSheet, appearance: self.configuration.appearance)
                    }
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
    func payWithLinkViewControllerDidFinish(
        _ payWithLinkViewController: PayWithLinkViewController,
        confirmOption: PaymentSheet.LinkConfirmOption
    ) {
        payWithLinkViewController.dismiss(animated: true) {
            self.completion?(.paymentMethodSelection(confirmOption: confirmOption))
        }
    }

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
            confirmationChallenge: confirmationChallenge,
            analyticsHelper: analyticsHelper,
            completion: { result, confirmationType in
                if self.logPayment {
                    self.analyticsHelper.logPayment(paymentOption: paymentOption, result: result, deferredIntentConfirmationType: confirmationType)
                }
                completion(result, confirmationType)
            }
        )
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController, shouldReturnToPaymentSheet: Bool) {
        payWithLinkViewController.dismiss(animated: true) {
            let completionResult: CompletionResult = {
                switch self.mode {
                case .paymentMethodSelection:
                    return .paymentMethodSelection(confirmOption: nil, shouldReturnToPaymentSheet: shouldReturnToPaymentSheet)
                case .full:
                    return .full(result: .canceled, deferredIntentConfirmationType: nil, didFinish: false)
                }
            }()

            self.completion?(completionResult)
            self.selfRetainer = nil
        }
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        payWithLinkViewController.dismiss(animated: true) {
            self.completion?(.full(result: result, deferredIntentConfirmationType: deferredIntentConfirmationType, didFinish: true))
            self.selfRetainer = nil
        }
    }

    func payWithLinkViewControllerShouldCancel3DS2ChallengeFlow(_ payWithLinkViewController: PayWithLinkViewController) {
        paymentHandler.cancel3DS2ChallengeFlow()
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
            confirmationChallenge: confirmationChallenge,
            analyticsHelper: analyticsHelper
        ) { result, deferredIntentConfirmationType in
            self.completion?(.full(result: result, deferredIntentConfirmationType: deferredIntentConfirmationType, didFinish: true))
            self.selfRetainer = nil
        }
    }

    func payWithLinkWebControllerDidCancel() {
        completion?(.full(result: .canceled, deferredIntentConfirmationType: nil, didFinish: false))
        selfRetainer = nil
    }
}

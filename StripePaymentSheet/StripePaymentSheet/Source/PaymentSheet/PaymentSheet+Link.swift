//
//  PaymentSheet+Link.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - Webview Link

extension PaymentSheet: PayWithLinkWebControllerDelegate {

    func payWithLinkWebControllerDidComplete(
        _ PayWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption
    ) {
        guard let psvc = self.findPaymentSheetViewController() else {
            stpAssertionFailure()
            return
        }
        let backgroundColor = self.configuration.appearance.colors.background.withAlphaComponent(0.85)
        self.bottomSheetViewController.addBlurEffect(animated: false, backgroundColor: backgroundColor) {
            self.bottomSheetViewController.startSpinner()
            psvc.clearTextFields()
            psvc.pay(with: paymentOption)
        }
    }

    func payWithLinkWebControllerDidCancel() {
    }
}

extension PaymentSheet {
    func presentPayWithLinkController(
        from presentingController: UIViewController,
        intent: Intent,
        elementsSession: STPElementsSession,
        completion: (() -> Void)? = nil
    ) {
        let payWithLinkVC = PayWithLinkWebController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration
        )

        payWithLinkVC.payWithLinkDelegate = self
        payWithLinkVC.present(over: presentingController)
    }

}

// MARK: - Native Link

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {

    func presentPayWithNativeLinkController(
        from presentingController: UIViewController,
        intent: Intent,
        elementsSession: STPElementsSession,
        shouldOfferApplePay: Bool,
        shouldFinishOnClose: Bool,
        completion: (() -> Void)?
    ) {
        let payWithLinkVC = PayWithLinkViewController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            shouldOfferApplePay: shouldOfferApplePay,
            shouldFinishOnClose: shouldFinishOnClose,
            analyticsHelper: self.analyticsHelper,
            presentingController: presentingController
        )

        payWithLinkVC.payWithLinkDelegate = self

        if UIDevice.current.userInterfaceIdiom == .pad {
            payWithLinkVC.modalPresentationStyle = .formSheet
        } else {
            if #available(iOS 15.0, *) {
                if let sheetController = payWithLinkVC.sheetPresentationController {
                    payWithLinkVC.modalPresentationStyle = .pageSheet
                    sheetController.detents = [.medium(), .large()]
                    sheetController.prefersScrollingExpandsWhenScrolledToEdge = true
                    sheetController.prefersEdgeAttachedInCompactHeight = true
                }
            }
        }
        payWithLinkVC.isModalInPresentation = true

        bottomSheetViewController.dismiss(animated: true) {
            presentingController.present(payWithLinkVC, animated: true, completion: completion)
        }
    }

    func verifyLinkSessionIfNeeded(
        with paymentOption: PaymentOption,
        intent: Intent,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard
            case .link(let linkOption) = paymentOption,
            let linkAccount = linkOption.account,
            linkAccount.sessionState == .requiresVerification
        else {
            // No verification required
            completion?(true)
            return
        }

        let verificationController = LinkVerificationController(
            mode: .inlineLogin,
            linkAccount: linkAccount,
            configuration: configuration
        )
        verificationController.present(from: bottomSheetViewController) { [weak self] result in
            self?.bottomSheetViewController.dismiss(animated: true, completion: nil)
            switch result {
            case .completed:
                completion?(true)
            case .canceled, .failed:
                completion?(false)
            }
        }
    }

}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet: PayWithLinkViewControllerDelegate {

    func payWithLinkViewControllerDidConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        PaymentSheet.confirm(
            configuration: self.configuration,
            authenticationContext: self.bottomSheetViewController,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: self.paymentHandler,
            integrationShape: .complete,
            analyticsHelper: analyticsHelper)
        { result, confirmationType in
            if case let .failed(error) = result {
                self.mostRecentError = error
            }
            self.analyticsHelper.logPayment(paymentOption: paymentOption, result: result, deferredIntentConfirmationType: confirmationType)

            completion(result, confirmationType)
            payWithLinkViewController.dismiss(animated: true)
        }
    }

    func payWithLinkViewControllerDidCancel(
        _ payWithLinkViewController: PayWithLinkViewController,
        presentingViewController: UIViewController?
    ) {
        payWithLinkViewController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            presentingViewController?.presentAsBottomSheet(
                bottomSheetViewController,
                appearance: self.configuration.appearance
            )
        }
    }

    func payWithLinkViewControllerDidFinish(
        _ payWithLinkViewController: PayWithLinkViewController,
        result: PaymentSheetResult,
        deferredIntentConfirmationType: StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?
    ) {
        completion?(result)
    }

    private func findPaymentSheetViewController() -> PaymentSheetViewControllerProtocol? {
        for vc in bottomSheetViewController.contentStack {
            if let paymentSheetVC = vc as? PaymentSheetViewControllerProtocol {
                return paymentSheetVC
            }
        }

        return nil
    }
}

// MARK: - Native Link helpers

/// Check if native Link is available on this device
func deviceCanUseNativeLink(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration) -> Bool {
    let useAttestationEndpoints = elementsSession.linkSettings?.useAttestationEndpoints ?? false
    guard useAttestationEndpoints else {
        return false
    }

    // If we're in testmode, we don't need to attest for native Link
    if configuration.apiClient.isTestmode {
        return true
    }

    return configuration.apiClient.stripeAttest.isSupported
}

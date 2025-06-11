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
        onClose: (() -> Void)? = nil
    ) {
        let payWithNativeLink = PayWithNativeLinkController(mode: .full, intent: intent, elementsSession: elementsSession, configuration: configuration, analyticsHelper: analyticsHelper)

        payWithNativeLink.presentAsBottomSheet(from: presentingController, shouldOfferApplePay: shouldOfferApplePay, shouldFinishOnClose: shouldFinishOnClose, completion: { result, _, didFinish in
            if case let .failed(error) = result {
                self.mostRecentError = error
            }

            if didFinish {
                self.completion?(result)
            }

            onClose?()
        })
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {

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

// MARK: - Link features

extension PaymentSheet {

    @_spi(STP) public enum LinkFeatureFlags {

        /// Decides whether Link shows more actively in FlowController.
        /// Only enable this in the PaymentSheet playground.
        @_spi(STP) public static var enableLinkFlowControllerChanges: Bool = false

        /// Decides whether Link inline verification is shown in the `WalletButtonsView`.
        @_spi(STP) public static var enableLinkInlineVerification: Bool = false
    }
}

//
//  LinkFlowControllerHelpers.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 5/14/25.
//

@_spi(STP) import StripePayments
import UIKit

extension STPElementsSession {

    func enableFlowControllerRUX(for configuration: PaymentElementConfiguration) -> Bool {
        let usesNative = deviceCanUseNativeLink(elementsSession: self, configuration: configuration)
        let disableFlowControllerRUX = linkSettings?.disableFlowControllerRUX ?? false
        return PaymentSheet.LinkFeatureFlags.enableLinkFlowControllerChanges && !disableFlowControllerRUX && usesNative
    }
}

extension UIViewController {

    func presentNativeLink(
        selectedPaymentDetailsID: String?,
        configuration: PaymentElementConfiguration,
        intent: Intent,
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        verificationDismissed: (() -> Void)? = nil,
        callback: @escaping (_ confirmOption: PaymentSheet.LinkConfirmOption?, _ shouldReturnToPaymentSheet: Bool) -> Void
    ) {
        let linkAccount = LinkAccountContext.shared.account

        if let linkAccount, linkAccount.sessionState == .requiresVerification {
            let verificationController = LinkVerificationController(
                mode: .inlineLogin,
                linkAccount: linkAccount,
                configuration: configuration
            )

            verificationController.present(from: bottomSheetController ?? self) { [weak self] result in
                guard let self, case .completed = result else {
                    verificationDismissed?()
                    return
                }

                self.presentNativeLink(
                    selectedPaymentDetailsID: selectedPaymentDetailsID,
                    intent: intent,
                    elementsSession: elementsSession,
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    callback: callback
                )
            }
        } else {
            presentNativeLink(
                selectedPaymentDetailsID: selectedPaymentDetailsID,
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                analyticsHelper: analyticsHelper,
                callback: callback
            )
        }
    }

    private func presentNativeLink(
        selectedPaymentDetailsID: String?,
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        callback: @escaping (_ confirmOption: PaymentSheet.LinkConfirmOption?, _ shouldReturnToPaymentSheet: Bool) -> Void
    ) {
        let payWithLinkController = PayWithNativeLinkController(
            mode: .paymentMethodSelection,
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            logPayment: false,
            analyticsHelper: analyticsHelper
        )

        payWithLinkController.presentForPaymentMethodSelection(
            from: self,
            initiallySelectedPaymentDetailsID: selectedPaymentDetailsID,
            completion: callback
        )
    }
}

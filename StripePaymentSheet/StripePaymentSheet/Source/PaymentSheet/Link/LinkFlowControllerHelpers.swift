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
        return !disableFlowControllerRUX && usesNative
    }
}

extension UIViewController {

    func presentNativeLink(
        selectedPaymentDetailsID: String?,
        linkAccount: PaymentSheetLinkAccount? = LinkAccountContext.shared.account,
        configuration: PaymentElementConfiguration,
        intent: Intent,
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        verificationDismissed: (() -> Void)? = nil,
        callback: @escaping (_ confirmOption: PaymentSheet.LinkConfirmOption?, _ shouldReturnToPaymentSheet: Bool) -> Void
    ) {
        if let linkAccount, linkAccount.sessionState == .requiresVerification {
            let verificationController = LinkVerificationController(
                mode: .inlineLogin,
                linkAccount: linkAccount,
                configuration: configuration,
                allowLogoutInDialog: true
            )

            verificationController.present(from: bottomSheetController ?? self) { [weak self] result in
                if case .switchAccount = result {
                    // The user logged out in the dialog. Clear the account, but still open the Link flow
                    // to allow them to sign into another account.
                    LinkAccountContext.shared.account = nil
                }

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
            canSkipWalletAfterVerification: false,
            completion: callback
        )
    }
}

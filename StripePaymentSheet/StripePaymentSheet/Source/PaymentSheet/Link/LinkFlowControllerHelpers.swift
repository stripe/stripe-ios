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
            let canSkipWallet = elementsSession.canSkipLinkWallet && selectedPaymentDetailsID == nil

            let verificationController = LinkVerificationController(
                mode: .inlineLogin,
                linkAccount: linkAccount,
                configuration: configuration,
                elementsSession: elementsSession,
                shouldLoadConsumerState: canSkipWallet
            )

            verificationController.present(from: bottomSheetController ?? self) { [weak self] result in
                guard let self, case let .completed(linkConsumerState) = result else {
                    verificationDismissed?()
                    return
                }

                guard let updatedAccount = LinkAccountContext.shared.account else {
                    verificationDismissed?()
                    return
                }

                if let linkConsumerState, let paymentDetails = linkConsumerState.defaultPaymentDetails, paymentDetails.isValidCard {
                    // Immediately return the valid default payment method
                    callback(
                        .withPaymentDetails(
                            account: updatedAccount,
                            paymentDetails: paymentDetails,
                            confirmationExtras: nil,
                            shippingAddress: linkConsumerState.defaultShippingAddress
                        ),
                        false
                    )
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

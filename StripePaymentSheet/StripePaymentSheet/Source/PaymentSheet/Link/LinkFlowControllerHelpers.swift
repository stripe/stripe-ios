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
        configuration: PaymentElementConfiguration,
        intent: Intent,
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        supportedPaymentMethodTypes: [LinkPaymentMethodType] = LinkPaymentMethodType.allCases,
        linkAppearance: LinkAppearance? = nil,
        linkConfiguration: LinkConfiguration? = nil,
        shouldShowSecondaryCta: Bool = true,
        confirmationChallenge: ConfirmationChallenge? = nil,
        callback: @escaping (_ confirmOption: PaymentSheet.LinkConfirmOption?, _ shouldReturnToPaymentSheet: Bool) -> Void
    ) {
        let payWithLinkController = PayWithNativeLinkController(
            mode: .paymentMethodSelection,
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            logPayment: false,
            analyticsHelper: analyticsHelper,
            supportedPaymentMethodTypes: supportedPaymentMethodTypes,
            linkAppearance: linkAppearance,
            linkConfiguration: linkConfiguration,
            confirmationChallenge: confirmationChallenge
        )

        payWithLinkController.presentForPaymentMethodSelection(
            from: self,
            initiallySelectedPaymentDetailsID: selectedPaymentDetailsID,
            shouldShowSecondaryCta: shouldShowSecondaryCta,
            canSkipWalletAfterVerification: false,
            completion: callback
        )
    }
}

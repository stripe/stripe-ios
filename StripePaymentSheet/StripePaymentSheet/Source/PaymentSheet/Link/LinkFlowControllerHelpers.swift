//
//  LinkFlowControllerHelpers.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 5/14/25.
//

import UIKit

extension PaymentSheetLinkAccount {

    func fetchDefaultPaymentDetails(
        elementsSession: STPElementsSession,
        completion: @escaping (ConsumerPaymentDetails?) -> Void
    ) {
        let supportedTypes = Array(supportedPaymentDetailsTypes(for: elementsSession))

        listPaymentDetails(supportedTypes: supportedTypes) { result in
            var linkPaymentDetails: ConsumerPaymentDetails?

            switch result {
            case .success(let paymentDetails):
                linkPaymentDetails = paymentDetails.first(where: \.isDefault) ?? paymentDetails.first
            case .failure:
                break
            }

            completion(linkPaymentDetails)
        }
    }
}

extension UIViewController {

    func presentNativeLink(
        selectedPaymentDetailsID: String?,
        configuration: PaymentElementConfiguration,
        intent: Intent,
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: PayWithLinkViewControllerDelegate,
        verificationCompletion: @escaping (PaymentSheetLinkAccount) -> Void
    ) {
        let linkAccount = LinkAccountContext.shared.account

        if let linkAccount, linkAccount.sessionState == .requiresVerification {
            let verificationController = LinkVerificationController(
                mode: .inlineLogin,
                linkAccount: linkAccount,
                configuration: configuration
            )

            verificationController.present(from: self.bottomSheetController!) { result in
                switch result {
                case .completed:
                    if let linkAccount = LinkAccountContext.shared.account {
                        verificationCompletion(linkAccount)
                    }
                case .canceled:
                    print("LinkVerificationController canceled")
                case .failed:
                    print("LinkVerificationController failed")
                }
            }
        } else {
            presentNativeLinkInsteadOfFlowController(
                selectedPaymentDetailsID: selectedPaymentDetailsID,
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                analyticsHelper: analyticsHelper,
                delegate: delegate
            )
        }
    }

    func presentNativeLinkInsteadOfFlowController(
        selectedPaymentDetailsID: String?,
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: PayWithLinkViewControllerDelegate
    ) {
        let payWithLinkVC = PayWithLinkViewController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            shouldOfferApplePay: false,
            shouldFinishOnClose: false,
            initiallySelectedPaymentDetailsID: selectedPaymentDetailsID,
            callToAction: .continue,
            analyticsHelper: analyticsHelper
        )

        payWithLinkVC.payWithLinkDelegate = delegate

        if UIDevice.current.userInterfaceIdiom == .pad {
            payWithLinkVC.modalPresentationStyle = .formSheet
        }
        payWithLinkVC.isModalInPresentation = true

        present(payWithLinkVC, animated: true)
    }
}

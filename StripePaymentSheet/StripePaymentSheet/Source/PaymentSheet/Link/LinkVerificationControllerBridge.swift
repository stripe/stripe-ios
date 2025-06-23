//
//  LinkVerificationControllerBridge.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/21/25.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public class LinkVerificationControllerBridge {
    private let flowController: PaymentSheet.FlowController
    private var completionHandler: (() -> Void)?
    private var payWithLinkViewController: PayWithLinkViewController?

    @_spi(STP) public init(flowController: PaymentSheet.FlowController) {
        self.flowController = flowController
    }

    @_spi(STP) public func startVerification(from viewController: UIViewController, completion: @escaping () -> Void) {
        // Store the completion handler
        self.completionHandler = completion

        if let account = LinkAccountContext.shared.account, account.isRegistered {
            let verificationController = LinkVerificationController(
                linkAccount: LinkAccountContext.shared.account!,
                configuration: flowController.configuration
            )
            verificationController.present(from: viewController) { result in
                print(result)
                completion()
            }
        } else {
            let payWithLinkVC = PayWithLinkViewController(
                intent: flowController.intent,
                linkAccount: LinkAccountContext.shared.account,
                elementsSession: flowController.elementsSession,
                configuration: flowController.configuration,
                analyticsHelper: flowController.analyticsHelper
            )

            // Store reference to prevent deallocation
            self.payWithLinkViewController = payWithLinkVC
            payWithLinkVC.payWithLinkDelegate = self

            viewController.presentAsBottomSheet(
                payWithLinkVC,
                appearance: flowController.configuration.appearance
            )
        }
    }

    private func handleCompletion() {
        // Call the stored completion handler and clean up references
        completionHandler?()
        completionHandler = nil
        payWithLinkViewController = nil
    }
}

extension LinkVerificationControllerBridge: PayWithLinkViewControllerDelegate {
    func payWithLinkViewControllerDidConfirm(_ payWithLinkViewController: PayWithLinkViewController, intent: Intent, elementsSession: STPElementsSession, with paymentOption: PaymentOption, completion: @escaping (PaymentSheetResult, StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
        print(#function)
        payWithLinkViewController.dismiss(animated: true) { [weak self] in
            self?.handleCompletion()
        }
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController, shouldReturnToPaymentSheet: Bool) {
        print(#function)
        payWithLinkViewController.dismiss(animated: true) { [weak self] in
            self?.handleCompletion()
        }
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult, deferredIntentConfirmationType: StripeCore.STPAnalyticsClient.DeferredIntentConfirmationType?) {
        print(#function)
        payWithLinkViewController.dismiss(animated: true) { [weak self] in
            self?.handleCompletion()
        }
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, confirmOption: PaymentSheet.LinkConfirmOption) {
        print(#function)
        payWithLinkViewController.dismiss(animated: true) { [weak self] in
            self?.handleCompletion()
        }
    }
}

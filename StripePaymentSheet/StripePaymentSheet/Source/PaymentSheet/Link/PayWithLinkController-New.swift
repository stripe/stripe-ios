//
//  PayWithNativeLinkController.swift
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

    typealias CompletionBlock = PaymentSheetResultCompletionBlock

    private let paymentHandler: STPPaymentHandler

    private var completion: PaymentSheetResultCompletionBlock?

    private var selfRetainer: PayWithNativeLinkController?

    let intent: Intent
    let elementsSession: STPElementsSession
    let configuration: PaymentSheet.Configuration

    init(intent: Intent, elementsSession: STPElementsSession, configuration: PaymentSheet.Configuration) {
        self.intent = intent
        self.configuration = configuration
        self.elementsSession = elementsSession
        self.paymentHandler = .init(apiClient: configuration.apiClient)
    }

    func present(completion: @escaping CompletionBlock) {
        guard
            let keyWindow = UIApplication.shared.stp_hackilyFumbleAroundUntilYouFindAKeyWindow(),
            let presentedViewController = keyWindow.findTopMostPresentedViewController()
        else {
            assertionFailure("No key window with view controller found")
            return
        }

        present(from: presentedViewController, completion: completion)
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping PaymentSheetResultCompletionBlock
    ) {
        // Similarly to `PKPaymentAuthorizationController`, `LinkController` should retain
        // itself while presented.
        self.selfRetainer = self
        self.completion = completion

        let payWithLinkViewController = PayWithLinkViewController(intent: intent, elementsSession: elementsSession, configuration: configuration)
        payWithLinkViewController.payWithLinkDelegate = self
        payWithLinkViewController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad
            ? .formSheet
            : .overFullScreen

        presentingController.present(payWithLinkViewController, animated: true)
    }

}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PayWithNativeLinkController: PayWithLinkViewControllerDelegate {

    func payWithLinkViewControllerDidConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: payWithLinkViewController,
            intent: intent,
//            TODO(link): Add elements session
            elementsSession: STPElementsSession.makeBackupElementsSession(allResponseFields: [:], paymentMethodTypes: []),
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            isFlowController: false,
            completion: completion
        )
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        payWithLinkViewController.dismiss(animated: true)
//        TODO(link): Return deferred intent confirmation type, not .client
        completion?(.canceled, .client)
        selfRetainer = nil
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult) {
        payWithLinkViewController.dismiss(animated: true)
//        TODO(link): Return deferred intent confirmation type, not .client
        completion?(result, .client)
        selfRetainer = nil
    }

}

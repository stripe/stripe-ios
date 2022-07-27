//
//  PayWithLinkController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 7/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// Standalone Link controller
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
final class PayWithLinkController {

    typealias CompletionBlock = PaymentSheetResultCompletionBlock

    private let paymentHandler: STPPaymentHandler

    private var completion: PaymentSheetResultCompletionBlock?

    private var selfRetainer: PayWithLinkController?

    let intent: Intent
    let configuration: PaymentSheet.Configuration

    init(intent: Intent, configuration: PaymentSheet.Configuration) {
        self.intent = intent
        self.configuration = configuration
        self.paymentHandler = .init(apiClient: configuration.apiClient)
    }

    func present(completion: @escaping CompletionBlock) {
        guard
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
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

        let payWithLinkViewController = PayWithLinkViewController(intent: intent, configuration: configuration)
        payWithLinkViewController.payWithLinkDelegate = self
        payWithLinkViewController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad
            ? .formSheet
            : .overFullScreen

        presentingController.present(payWithLinkViewController, animated: true)
    }

}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PayWithLinkController: PayWithLinkViewControllerDelegate {

    func payWithLinkViewControllerDidConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: payWithLinkViewController,
            intent: intent,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            completion: completion
        )
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController) {
        payWithLinkViewController.dismiss(animated: true)
        completion?(.canceled)
        selfRetainer = nil
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult) {
        payWithLinkViewController.dismiss(animated: true)
        completion?(result)
        selfRetainer = nil
    }

}

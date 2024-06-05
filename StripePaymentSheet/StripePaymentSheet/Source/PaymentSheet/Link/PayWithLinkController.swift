//
//  PayWithLinkController.swift
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
final class PayWithLinkController {

    typealias CompletionBlock = ((PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void)

    private let paymentHandler: STPPaymentHandler

    private var completion: CompletionBlock?

    private var selfRetainer: PayWithLinkController?

    let intent: Intent
    let configuration: PaymentSheet.Configuration

    init(intent: Intent, configuration: PaymentSheet.Configuration) {
        self.intent = intent
        self.configuration = configuration
        self.paymentHandler = .init(apiClient: configuration.apiClient)
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        // Similarly to `PKPaymentAuthorizationController`, `LinkController` should retain
        // itself while presented.
        self.selfRetainer = self
        self.completion = completion

        let payWithLinkWebController = PayWithLinkWebController(intent: intent, configuration: configuration)
        payWithLinkWebController.payWithLinkDelegate = self
        payWithLinkWebController.present(over: presentingController)
    }

}

extension PayWithLinkController: PayWithLinkWebControllerDelegate {

    func payWithLinkWebControllerDidComplete(
        _ payWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        with paymentOption: PaymentOption
    ) {
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: payWithLinkWebController,
            intent: intent,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            isFlowController: false
        ) { result, deferredIntentConfirmationType in
            self.completion?(result, deferredIntentConfirmationType)
            self.selfRetainer = nil
        }
    }

    func payWithLinkWebControllerDidCancel(_ payWithLinkWebController: PayWithLinkWebController) {
        completion?(.canceled, nil)
        selfRetainer = nil
    }

}

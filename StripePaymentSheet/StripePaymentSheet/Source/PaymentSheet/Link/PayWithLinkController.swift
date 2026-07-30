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
    typealias ConfirmHandler = (STPAuthenticationContext, Intent, STPElementsSession, PaymentOption, @escaping CompletionBlock) -> Void

    private let paymentHandler: STPPaymentHandler

    private var completion: CompletionBlock?

    private var selfRetainer: PayWithLinkController?

    let intent: Intent
    let elementsSession: STPElementsSession
    let configuration: PaymentElementConfiguration
    let analyticsHelper: PaymentSheetAnalyticsHelper
    private let confirmationChallenge: ConfirmationChallenge?
    // If you pass a confirmHandler, it's used to confirm the payment. Otherwise, PaymentSheet.confirm is used.
    private let confirmHandler: ConfirmHandler?

    init(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        checkout: CheckoutSessionBillingAddressUpdater? = nil,
        confirmationChallenge: ConfirmationChallenge?,
        confirmHandler: ConfirmHandler? = nil
    ) {
        self.intent = intent
        self.elementsSession = elementsSession
        self.configuration = configuration
        self.paymentHandler = .init(apiClient: configuration.apiClient)
        self.analyticsHelper = analyticsHelper
        self.confirmationChallenge = confirmationChallenge
        self.confirmHandler = confirmHandler
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        // Similarly to `PKPaymentAuthorizationController`, `LinkController` should retain
        // itself while presented.
        self.selfRetainer = self
        self.completion = completion

        let payWithLinkWebController = PayWithLinkWebController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            linkAccount: LinkAccountContext.shared.account
        )
        payWithLinkWebController.payWithLinkDelegate = self
        payWithLinkWebController.present(over: presentingController)
    }

}

extension PayWithLinkController: PayWithLinkWebControllerDelegate {

    func payWithLinkWebControllerDidComplete(
        _ payWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption
    ) {
        // If you pass a confirmHandler, it's used to confirm the payment. Otherwise, PaymentSheet.confirm is used.
        if let confirmHandler {
            confirmHandler(payWithLinkWebController, intent, elementsSession, paymentOption) { result, deferredIntentConfirmationType in
                self.completion?(result, deferredIntentConfirmationType)
                self.selfRetainer = nil
            }
            return
        }

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: payWithLinkWebController,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            integrationShape: .complete,
            confirmationChallenge: confirmationChallenge,
            analyticsHelper: analyticsHelper
        ) { result, deferredIntentConfirmationType in
            self.completion?(result, deferredIntentConfirmationType)
            self.selfRetainer = nil
        }
    }

    func payWithLinkWebControllerDidCancel() {
        completion?(.canceled, nil)
        selfRetainer = nil
    }

}

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
    let elementsSession: STPElementsSession
    let configuration: PaymentElementConfiguration
    let analyticsHelper: PaymentSheetAnalyticsHelper
    private let passiveCaptchaChallenge: PassiveCaptchaChallenge?

    init(intent: Intent, elementsSession: STPElementsSession, configuration: PaymentElementConfiguration, analyticsHelper: PaymentSheetAnalyticsHelper, passiveCaptchaChallenge: PassiveCaptchaChallenge?) {
        self.intent = intent
        self.elementsSession = elementsSession
        self.configuration = configuration
        self.paymentHandler = .init(apiClient: configuration.apiClient)
        self.analyticsHelper = analyticsHelper
        self.passiveCaptchaChallenge = passiveCaptchaChallenge
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        // Similarly to `PKPaymentAuthorizationController`, `LinkController` should retain
        // itself while presented.
        self.selfRetainer = self
        self.completion = completion

        let payWithLinkWebController = PayWithLinkWebController(intent: intent, elementsSession: elementsSession, configuration: configuration)
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
        Task {
            await PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: payWithLinkWebController,
                intent: intent,
                elementsSession: elementsSession,
                paymentOption: paymentOption,
                paymentHandler: paymentHandler,
                integrationShape: .complete,
                hcaptchaToken: passiveCaptchaChallenge?.fetchToken(),
                analyticsHelper: analyticsHelper
            ) { result, deferredIntentConfirmationType in
                self.completion?(result, deferredIntentConfirmationType)
                self.selfRetainer = nil
            }
        }
    }

    func payWithLinkWebControllerDidCancel() {
        completion?(.canceled, nil)
        selfRetainer = nil
    }

}

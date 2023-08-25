//
//  PaymentSheet+API.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheet {

    /// Confirms a PaymentIntent with the given PaymentOption and returns a PaymentResult
    static func confirm(
        configuration: PaymentSheet.Configuration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool = false,
        paymentMethodID: String? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        // Translates a STPPaymentHandler result to a PaymentResult
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSError?) -> Void = { status, error in
            completion(makePaymentSheetResult(for: status, error: error), nil)
        }

        switch paymentOption {
        // MARK: - Apple Pay
        case .applePay:
            guard
                let applePayContext = STPApplePayContext.create(
                    intent: intent,
                    configuration: configuration,
                    completion: completion
                )
            else {
                assertionFailure(PaymentSheetError.applePayNotSupportedOrMisconfigured.debugDescription)
                completion(.failed(error: PaymentSheetError.applePayNotSupportedOrMisconfigured), nil)
                return
            }
            applePayContext.presentApplePay()

        // MARK: - New Payment Method
        case let .new(confirmParams):
            switch intent {
            // MARK: ↪ PaymentIntent
            case .paymentIntent(let paymentIntent):
                // The Dashboard app cannot pass `paymentMethodParams` ie payment_method_data
                if configuration.apiClient.publishableKeyIsUserKey {
                    configuration.apiClient.createPaymentMethod(with: confirmParams.paymentMethodParams) {
                        paymentMethod,
                        error in
                        if let error = error {
                            completion(.failed(error: error), nil)
                            return
                        }
                        let paymentIntentParams = confirmParams.makeDashboardParams(
                            paymentIntentClientSecret: paymentIntent.clientSecret,
                            paymentMethodID: paymentMethod?.stripeId ?? "",
                            configuration: configuration
                        )
                        paymentIntentParams.shipping = makeShippingParams(
                            for: paymentIntent,
                            configuration: configuration
                        )
                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext,
                            completion: { actionStatus, _, error in
                                paymentHandlerCompletion(actionStatus, error)
                            }
                        )
                    }
                } else {
                    let params = makePaymentIntentParams(
                        confirmPaymentMethodType: .new(
                            params: confirmParams.paymentMethodParams,
                            paymentOptions: confirmParams.confirmPaymentMethodOptions,
                            shouldSave: confirmParams.saveForFutureUseCheckboxState == .selected
                        ),
                        paymentIntent: paymentIntent,
                        configuration: configuration
                    )
                    paymentHandler.confirmPayment(
                        params,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                }
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .new(
                        params: confirmParams.paymentMethodParams,
                        paymentOptions: confirmParams.confirmPaymentMethodOptions,
                        shouldSave: false
                    ),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ Deferred Intent
            case .deferredIntent(_, let intentConfig):
                handleDeferredIntentConfirmation(
                    confirmType: .new(
                        params: confirmParams.paymentMethodParams,
                        paymentOptions: confirmParams.confirmPaymentMethodOptions,
                        shouldSave: confirmParams.saveForFutureUseCheckboxState == .selected
                    ),
                    configuration: configuration,
                    intentConfig: intentConfig,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    isFlowController: isFlowController,
                    completion: completion
                )
            }

        // MARK: - Saved Payment Method
        case let .saved(paymentMethod):
            switch intent {
            // MARK: ↪ PaymentIntent
            case .paymentIntent(let paymentIntent):
                let paymentIntentParams = makePaymentIntentParams(confirmPaymentMethodType: .saved(paymentMethod), paymentIntent: paymentIntent, configuration: configuration)

                // The Dashboard app requires MOTO
                if configuration.apiClient.publishableKeyIsUserKey {
                    paymentIntentParams.paymentMethodOptions?.setMoto()
                }

                paymentHandler.confirmPayment(
                    paymentIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .saved(paymentMethod),
                    setupIntent: setupIntent,
                    configuration: configuration
                )
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ Deferred Intent
            case .deferredIntent(_, let intentConfig):
                handleDeferredIntentConfirmation(
                    confirmType: .saved(paymentMethod),
                    configuration: configuration,
                    intentConfig: intentConfig,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler,
                    isFlowController: isFlowController,
                    completion: completion
                )
            }
        // MARK: - Link
        case .link(let confirmOption):
            let confirmWithPaymentMethodParams: (STPPaymentMethodParams) -> Void = { paymentMethodParams in
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodParams = paymentMethodParams
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodParams = paymentMethodParams
                    setupIntentParams.returnURL = configuration.returnURL
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                case .deferredIntent(_, let intentConfig):
                    handleDeferredIntentConfirmation(
                        confirmType: .new(
                            params: paymentMethodParams,
                            paymentOptions: STPConfirmPaymentMethodOptions(),
                            shouldSave: false
                        ),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        completion: completion
                    )
                }
            }
            let confirmWithPaymentMethod: (STPPaymentMethod) -> Void = { paymentMethod in
                let mandateCustomerAcceptanceParams = STPMandateCustomerAcceptanceParams()
                let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
                // Tell Stripe to infer mandate info from client
                onlineParams.inferFromClient = true
                mandateCustomerAcceptanceParams.onlineParams = onlineParams
                mandateCustomerAcceptanceParams.type = .online
                let mandateData = STPMandateDataParams(customerAcceptance: mandateCustomerAcceptanceParams)
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentIntentParams.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
                    paymentIntentParams.mandateData = mandateData
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodID = paymentMethod.stripeId
                    setupIntentParams.returnURL = configuration.returnURL
                    setupIntentParams.mandateData = mandateData
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: { actionStatus, _, error in
                            paymentHandlerCompletion(actionStatus, error)
                        }
                    )
                case .deferredIntent(_, let intentConfig):
                    handleDeferredIntentConfirmation(
                        confirmType: .saved(paymentMethod),
                        configuration: configuration,
                        intentConfig: intentConfig,
                        authenticationContext: authenticationContext,
                        paymentHandler: paymentHandler,
                        isFlowController: isFlowController,
                        completion: completion
                    )
                }
            }

            let confirmWithPaymentDetails:
                (
                    PaymentSheetLinkAccount,
                    ConsumerPaymentDetails
                ) -> Void = { linkAccount, paymentDetails in
                    guard let paymentMethodParams = linkAccount.makePaymentMethodParams(from: paymentDetails) else {
                        let error = PaymentSheetError.payingWithoutValidLinkSession
                        completion(.failed(error: error), nil)
                        return
                    }

                    confirmWithPaymentMethodParams(paymentMethodParams)
                }

            let createPaymentDetailsAndConfirm:
                (
                    PaymentSheetLinkAccount,
                    STPPaymentMethodParams
                ) -> Void = { linkAccount, paymentMethodParams in
                    guard linkAccount.sessionState == .verified else {
                        // We don't support 2FA in the native mobile Link flow, so if 2FA is required then this is a no-op.
                        // Just fall through and don't save the card details to Link.
                        STPAnalyticsClient.sharedClient.logLinkPopupSkipped()

                        // Attempt to confirm directly with params
                        confirmWithPaymentMethodParams(paymentMethodParams)
                        return
                    }

                    linkAccount.createPaymentDetails(with: paymentMethodParams) { result in
                        switch result {
                        case .success(let paymentDetails):
                            confirmWithPaymentDetails(linkAccount, paymentDetails)
                        case .failure:
                            assertionFailure("Failed to create payment details")
                            // Attempt to confirm directly with params
                            confirmWithPaymentMethodParams(paymentMethodParams)
                        }
                    }
                }

            switch confirmOption {
            case .wallet:
                let linkController = PayWithLinkController(intent: intent, configuration: configuration)
                linkController.present(completion: completion)
            case .signUp(let linkAccount, let phoneNumber, let legalName, let paymentMethodParams):
                linkAccount.signUp(with: phoneNumber, legalName: legalName, consentAction: .checkbox) { result in
                    switch result {
                    case .success:
                        STPAnalyticsClient.sharedClient.logLinkSignupComplete()

                        // Store the payment details to display on the button:
                        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient)
                        linkAccountService.setLastPMDetails(params: paymentMethodParams)

                        createPaymentDetailsAndConfirm(linkAccount, paymentMethodParams)
                    case .failure(let error as NSError):
                        STPAnalyticsClient.sharedClient.logLinkSignupFailure()

                        let isUserInputError =
                            (error.domain == STPError.stripeDomain
                                && error.code == STPErrorCode.invalidRequestError.rawValue)

                        if isUserInputError {
                            // The request failed because invalid info was provided. In this case
                            // we should surface the error and let the user correct the information
                            // and try again.
                            completion(.failed(error: error), nil)
                        } else {
                            // Attempt to confirm directly with params as a fallback.
                            confirmWithPaymentMethodParams(paymentMethodParams)
                        }
                    }
                }
            case .withPaymentDetails(let linkAccount, let paymentDetails):
                confirmWithPaymentDetails(linkAccount, paymentDetails)
            case .withPaymentMethodParams(let linkAccount, let paymentMethodParams):
                createPaymentDetailsAndConfirm(linkAccount, paymentMethodParams)
            case .withPaymentMethod(let paymentMethod):
                confirmWithPaymentMethod(paymentMethod)
            }
        case .externalPayPal(let confirmParams):
            guard let confirmHandler = configuration.externalPaymentMethodConfiguration?.externalPaymentMethodConfirmHandler else {
                assertionFailure("Attempting to confirm an external payment method, but externalPaymentMethodConfirmhandler isn't set!")
                completion(.canceled, nil)
                return
            }
            Task { @MainActor in
                do {
                    // Call confirmHandler so that the merchant completes the payment
                    let result = await confirmHandler("external_paypal", confirmParams.paymentMethodParams.nonnil_billingDetails)
                    completion(result, nil)
                }
            }
        }
    }

    // MARK: - Helper methods

    static func makeShippingParams(for paymentIntent: STPPaymentIntent, configuration: PaymentSheet.Configuration)
        -> STPPaymentIntentShippingDetailsParams?
    {
        let params = STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration)
        // If a merchant attaches shipping to the PI on their server, the /confirm endpoint will error if we update shipping with a “requires secret key” error message.
        // To accommodate this, don't attach if our shipping is the same as the PI's shipping
        guard !isEqual(paymentIntent.shipping, params) else {
            return nil
        }
        return params
    }

    enum ConfirmPaymentMethodType {
        case saved(STPPaymentMethod)
        /// - paymentMethod: Pass this if you created a PaymentMethod already (e.g. for the deferred flow).
        case new(params: STPPaymentMethodParams, paymentOptions: STPConfirmPaymentMethodOptions, paymentMethod: STPPaymentMethod? = nil, shouldSave: Bool)
        var shouldSave: Bool {
            switch self {
            case .saved:
                return false
            case .new(_, _, _, let shouldSave):
                return shouldSave
            }
        }
    }

    static func makePaymentIntentParams(
        confirmPaymentMethodType: ConfirmPaymentMethodType,
        paymentIntent: STPPaymentIntent,
        configuration: PaymentSheet.Configuration,
        mandateData: STPMandateDataParams? = nil
    ) -> STPPaymentIntentParams {
        let params: STPPaymentIntentParams
        let shouldSave: Bool
        let paymentMethodType: STPPaymentMethodType
        switch confirmPaymentMethodType {
        case .saved(let paymentMethod):
            shouldSave = false
            paymentMethodType = paymentMethod.type
            params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
            params.paymentMethodId = paymentMethod.stripeId
        case let .new(paymentMethodParams, paymentMethodoptions, paymentMethod, _shouldSave):
            shouldSave = _shouldSave
            if let paymentMethod = paymentMethod {
                paymentMethodType = paymentMethod.type
                params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
                params.paymentMethodId = paymentMethod.stripeId
                params.paymentMethodOptions = paymentMethodoptions
            } else {
                params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
                params.paymentMethodOptions = paymentMethodoptions
                paymentMethodType = paymentMethodParams.type
            }

            // Paypal requires mandate_data if setting up
            if params.paymentMethodType == .payPal
                && paymentIntent.setupFutureUsage == .offSession
            {
                params.mandateData = .makeWithInferredValues()
            }
        }

        let paymentOptions = params.paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
        paymentOptions.setSetupFutureUsageIfNecessary(shouldSave, paymentMethodType: paymentMethodType, customer: configuration.customer)
        if let mandateData = mandateData {
            params.mandateData = mandateData
        }
        params.paymentMethodOptions = paymentOptions
        params.returnURL = configuration.returnURL
        params.shipping = makeShippingParams(for: paymentIntent, configuration: configuration)
        return params
    }

    static func makeSetupIntentParams(
        confirmPaymentMethodType: ConfirmPaymentMethodType,
        setupIntent: STPSetupIntent,
        configuration: PaymentSheet.Configuration,
        mandateData: STPMandateDataParams? = nil
    ) -> STPSetupIntentConfirmParams {
        let params: STPSetupIntentConfirmParams
        switch confirmPaymentMethodType {
        case let .saved(paymentMethod):
            params = STPSetupIntentConfirmParams(
                clientSecret: setupIntent.clientSecret,
                paymentMethodType: paymentMethod.type
            )
            params.paymentMethodID = paymentMethod.stripeId

        case let .new(paymentMethodParams, _, paymentMethod, _):
            if let paymentMethod {
                params = STPSetupIntentConfirmParams(
                    clientSecret: setupIntent.clientSecret,
                    paymentMethodType: paymentMethod.type
                )
                params.paymentMethodID = paymentMethod.stripeId
            } else {
                params = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                params.paymentMethodParams = paymentMethodParams
            }
            // Paypal requires mandate_data if setting up
            if params.paymentMethodType == .payPal {
                params.mandateData = .makeWithInferredValues()
            }
        }
        if let mandateData = mandateData {
            params.mandateData = mandateData
        }
        params.returnURL = configuration.returnURL
        return params
    }
}

/// A helper method to compare shipping details
private func isEqual(_ lhs: STPPaymentIntentShippingDetails?, _ rhs: STPPaymentIntentShippingDetailsParams?) -> Bool {
    guard let lhs = lhs, let rhs = rhs else {
        // One or both are nil, so they're only equal if they're both nil
        return lhs == nil && rhs == nil
    }
    // Convert lhs to a STPPaymentIntentShippingDetailsAddressParams for ease of comparison
    let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: lhs.address?.line1 ?? "")
    addressParams.line2 = lhs.address?.line2
    addressParams.city = lhs.address?.city
    addressParams.state = lhs.address?.state
    addressParams.postalCode = lhs.address?.postalCode
    addressParams.country = lhs.address?.country

    let lhsConverted = STPPaymentIntentShippingDetailsParams(address: addressParams, name: lhs.name ?? "")
    lhsConverted.phone = lhs.phone

    return rhs == lhsConverted
}

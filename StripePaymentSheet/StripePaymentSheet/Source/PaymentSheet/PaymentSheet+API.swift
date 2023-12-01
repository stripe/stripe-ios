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
import SwiftUI
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
        performLocalActionsIfNeededAndConfirm(configuration: configuration, authenticationContext: authenticationContext, intent: intent, paymentOption: paymentOption, paymentHandler: paymentHandler, completion: completion)
    }

    /// Perform PaymentSheet-specific local actions before confirming.
    /// These actions are not represented in the PaymentIntent state and are specific to
    /// Payment Element (not the API bindings), so we need to handle them here.
    static fileprivate func performLocalActionsIfNeededAndConfirm(
        configuration: PaymentSheet.Configuration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool = false,
        paymentMethodID: String? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        // First, handle any client-side required actions:
        if case let .new(confirmParams) = paymentOption,
           confirmParams.paymentMethodType == .stripe(.bacsDebit) {
            // MARK: - Bacs Debit
            // Display the Bacs Debit mandate view
            let mandateView = BacsDDMandateView(email: confirmParams.paymentMethodParams.billingDetails?.email ?? "",
                                                name: confirmParams.paymentMethodParams.billingDetails?.name ?? "",
                                                sortCode: confirmParams.paymentMethodParams.bacsDebit?.sortCode ?? "",
                                                accountNumber: confirmParams.paymentMethodParams.bacsDebit?.accountNumber ?? "",
                                                confirmAction: {
                // If confirmed, dismiss the MandateView and complete the transaction:
                authenticationContext.authenticationPresentingViewController().dismiss(animated: true)
                confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, paymentOption: paymentOption, intentConfirmParams: nil, paymentHandler: paymentHandler, completion: completion)
            }, cancelAction: {
                // Dismiss the MandateView and return to PaymentSheet
                authenticationContext.authenticationPresentingViewController().dismiss(animated: true)
                completion(.canceled, nil)
            })

            let hostingController = UIHostingController(rootView: mandateView)
            hostingController.isModalInPresentation = true
            authenticationContext.authenticationPresentingViewController().present(hostingController, animated: true)
        } else if case let .saved(paymentMethod) = paymentOption,
                  paymentMethod.type == .card,
                  let isCVCRecollectionEnabledCallback = intent.intentConfig?.isCVCRecollectionEnabledCallback,
                  isCVCRecollectionEnabledCallback() {
            let presentingViewController = authenticationContext.authenticationPresentingViewController()

            guard presentingViewController.presentedViewController == nil else {
                assertionFailure("presentingViewController is already presenting a view controller")
                completion(.failed(error: PaymentSheetError.alreadyPresented), nil)
                return
            }
            let preConfirmationViewController = PreConfirmationViewController(
                paymentMethod: paymentMethod,
                intent: intent,
                configuration: configuration,
                onCompletion: { vc, intentConfirmParams in
                    vc.dismiss(animated: true)
                    confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, paymentOption: paymentOption, intentConfirmParams: intentConfirmParams, paymentHandler: paymentHandler, completion: completion)
                },
                onCancel: { vc in
                    vc.dismiss(animated: true)
                    DispatchQueue.main.async {
                        completion(.canceled, nil)
                    }
                })

            let presentPreConfirmationViewController: () -> Void = {
                // Set the PaymentSheetViewController as the content of our bottom sheet
                let bottomSheetVC = FlowController.makeBottomSheetViewController(
                    preConfirmationViewController,
                    configuration: configuration,
                    didCancelNative3DS2: {
                        paymentHandler.cancel3DS2ChallengeFlow()
                    }
                )
                presentingViewController.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance) {
                    preConfirmationViewController.didFinishPresenting()
                }
            }
            presentPreConfirmationViewController()

        } else {
            // MARK: - No local actions
            confirmAfterHandlingLocalActions(configuration: configuration, authenticationContext: authenticationContext, intent: intent, paymentOption: paymentOption, intentConfirmParams: nil, paymentHandler: paymentHandler, completion: completion)
        }
    }

    static fileprivate func confirmAfterHandlingLocalActions(
        configuration: PaymentSheet.Configuration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
        intentConfirmParams: IntentConfirmParams?,
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
            case .paymentIntent(_, let paymentIntent):
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
                    completion: { actionStatus, paymentIntent, error in
                        if let paymentIntent {
                            setDefaultPaymentMethodIfNecessary(actionStatus: actionStatus, intent: .paymentIntent(paymentIntent), configuration: configuration)
                        }
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(_, let setupIntent):
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
                    completion: { actionStatus, setupIntent, error in
                        if let setupIntent {
                            setDefaultPaymentMethodIfNecessary(actionStatus: actionStatus, intent: .setupIntent(setupIntent), configuration: configuration)
                        }
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
            case .paymentIntent(_, let paymentIntent):
                let paymentIntentParams = makePaymentIntentParams(confirmPaymentMethodType: .saved(paymentMethod, paymentOptions: nil), paymentIntent: paymentIntent, configuration: configuration)

                paymentHandler.confirmPayment(
                    paymentIntentParams,
                    with: authenticationContext,
                    completion: { actionStatus, _, error in
                        paymentHandlerCompletion(actionStatus, error)
                    }
                )
            // MARK: ↪ SetupIntent
            case .setupIntent(_, let setupIntent):
                let setupIntentParams = makeSetupIntentParams(
                    confirmPaymentMethodType: .saved(paymentMethod, paymentOptions: nil),
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
                    confirmType: .saved(paymentMethod, paymentOptions: intentConfirmParams?.confirmPaymentMethodOptions),
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
            // This is called when the customer pays in the sheet (as opposed to the Link webview) and agreed to sign up for Link
            let confirmWithPaymentMethodParams: (STPPaymentMethodParams) -> Void = { paymentMethodParams in
                switch intent {
                case .paymentIntent(_, let paymentIntent):
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
                case .setupIntent(_, let setupIntent):
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
                case .paymentIntent(_, let paymentIntent):
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
                case .setupIntent(_, let setupIntent):
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
                        confirmType: .saved(paymentMethod, paymentOptions: nil),
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
        case let .external(paymentMethod, billingDetails):
            guard let confirmHandler = configuration.externalPaymentMethodConfiguration?.externalPaymentMethodConfirmHandler else {
                assertionFailure("Attempting to confirm an external payment method, but externalPaymentMethodConfirmhandler isn't set!")
                completion(.canceled, nil)
                return
            }
            DispatchQueue.main.async {
                // Call confirmHandler so that the merchant completes the payment
                confirmHandler(paymentMethod.type, billingDetails) { result in
                    // This closure is invoked by the merchant when payment is finished
                    completion(result, nil)
                }
            }
        }
    }

    // MARK: - Helper methods

    enum PaymentOrSetupIntent {
        case paymentIntent(STPPaymentIntent)
        case setupIntent(STPSetupIntent)

        var isSetupFutureUsageSet: Bool {
            switch self {
            case .paymentIntent(let paymentIntent):
                return paymentIntent.setupFutureUsage != .none || (paymentIntent.paymentMethodOptions?.allResponseFields.values.contains(where: {
                    if let value = $0 as? [String: Any] {
                        return value["setup_future_usage"] != nil
                    }
                    return false
                }) ?? false)
            case .setupIntent:
                return true
            }
        }

        var paymentMethod: STPPaymentMethod? {
            switch self {
            case .paymentIntent(let paymentIntent):
                return paymentIntent.paymentMethod
            case .setupIntent(let setupIntent):
                return setupIntent.paymentMethod
            }
        }
    }

    /// A helper method that sets the Customer's default payment method if necessary.
    /// - Parameter actionStatus: The final status returned by `STPPaymentHandler`'s completion block.
    static func setDefaultPaymentMethodIfNecessary(actionStatus: STPPaymentHandlerActionStatus, intent: PaymentOrSetupIntent, configuration: Configuration) {

        guard
            // Did we successfully save this payment method?
            actionStatus == .succeeded,
            let customer = configuration.customer?.id,
            intent.isSetupFutureUsageSet,
            let paymentMethod = intent.paymentMethod,
            // Can it appear in the list of saved PMs?
            PaymentSheetLoader.savedPaymentMethodTypes.contains(paymentMethod.type)
        else {
            return
        }
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(paymentMethod.stripeId), forCustomer: customer)
    }

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
        case saved(STPPaymentMethod, paymentOptions: STPConfirmPaymentMethodOptions?)
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
        case .saved(let paymentMethod, let paymentMethodOptions):
            shouldSave = false
            paymentMethodType = paymentMethod.type
            params = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
            params.paymentMethodOptions = paymentMethodOptions
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

            // Paypal and Cash App Pay require mandate_data if setting up
            if (params.paymentMethodType == .payPal || params.paymentMethodType == .cashApp || params.paymentMethodType == .revolutPay)
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
        case let .saved(paymentMethod, _):
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
            // Paypal & revolut requires mandate_data if setting up
            if params.paymentMethodType == .payPal || params.paymentMethodType == .revolutPay {
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

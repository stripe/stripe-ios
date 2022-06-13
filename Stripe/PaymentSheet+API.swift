//
//  PaymentSheet+API.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
    /// `PaymentSheet.load()` result.
    enum LoadingResult {
        case success(
            intent: Intent,
            savedPaymentMethods: [STPPaymentMethod],
            isLinkEnabled: Bool,
            linkAccount: PaymentSheetLinkAccount?
        )
        case failure(Error)
    }

    /// Confirms a PaymentIntent with the given PaymentOption and returns a PaymentResult
    static func confirm(
        configuration: PaymentSheet.Configuration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
        paymentHandler: STPPaymentHandler,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        // Translates a STPPaymentHandler result to a PaymentResult
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSObject?, NSError?) -> Void =
            {
                (status, _, error) in
                switch status {
                case .canceled:
                    completion(.canceled)
                case .failed:
                    // Hold a strong reference to paymentHandler
                    let unknownError = PaymentSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                case .succeeded:
                    completion(.completed)
                }
            }

        switch paymentOption {
        // MARK: Apple Pay
        case .applePay:
            guard let applePayConfiguration = configuration.applePay,
                let applePayContext = STPApplePayContext.create(
                    intent: intent,
                    merchantName: configuration.merchantDisplayName,
                    configuration: applePayConfiguration,
                    completion: completion)
            else {
                let message =
                    "Attempted Apple Pay but it's not supported by the device, not configured, or missing a presenter"
                assertionFailure(message)
                completion(.failed(error: PaymentSheetError.unknown(debugDescription: message)))
                return
            }
            applePayContext.presentApplePay()

        // MARK: New Payment Method
        case let .new(confirmParams):
            switch intent {
            // MARK: PaymentIntent
            case .paymentIntent(let paymentIntent):
                // The Dashboard app's user key (uk_) cannot pass `paymenMethodParams` ie payment_method_data
                if configuration.apiClient.publishableKey?.hasPrefix("uk_") ?? false {
                    configuration.apiClient.createPaymentMethod(with: confirmParams.paymentMethodParams) {
                        paymentMethod, error in
                        if let error = error {
                            completion(.failed(error: error))
                            return
                        }
                        let paymentIntentParams = confirmParams.makeDashboardParams(
                            paymentIntentClientSecret: paymentIntent.clientSecret,
                            paymentMethodID: paymentMethod?.stripeId ?? ""
                        )
                        paymentHandler.confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext,
                            completion: paymentHandlerCompletion)
                    }
                } else {
                    let paymentIntentParams = confirmParams.makeParams(paymentIntentClientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentHandler.confirmPayment(paymentIntentParams,
                                                  with: authenticationContext,
                                                  completion: paymentHandlerCompletion)
                }
            // MARK: SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = confirmParams.makeParams(setupIntentClientSecret: setupIntent.clientSecret)
                setupIntentParams.returnURL = configuration.returnURL
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion)
            }

        // MARK: Saved Payment Method
        case let .saved(paymentMethod):
            switch intent {
            // MARK: PaymentIntent
            case .paymentIntent(let paymentIntent):
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret, paymentMethodType: paymentMethod.type)
                paymentIntentParams.returnURL = configuration.returnURL
                paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                // Overwrite in case payment_method_options was set previously - we don't want to save an already-saved payment method
                paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
                paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(false, paymentMethodType: paymentMethod.type)
                
                paymentHandler.confirmPayment(
                    paymentIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion)
            // MARK: SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = STPSetupIntentConfirmParams(
                    clientSecret: setupIntent.clientSecret, paymentMethodType: paymentMethod.type)
                setupIntentParams.returnURL = configuration.returnURL
                setupIntentParams.paymentMethodID = paymentMethod.stripeId
                paymentHandler.confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion)

            }
            
        case .link(let linkAccount, let confirmOption):
            let confirmWithPaymentMethodParams: (STPPaymentMethodParams) -> Void = { paymentMethodParams in
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.paymentMethodParams = paymentMethodParams
                    paymentIntentParams.returnURL = configuration.returnURL
                    paymentHandler.confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.paymentMethodParams = paymentMethodParams
                    setupIntentParams.returnURL = configuration.returnURL
                    paymentHandler.confirmSetupIntent(
                        setupIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion
                    )
                }
            }

            let confirmWithPaymentDetails: (ConsumerPaymentDetails) -> Void = { paymentDetails in
                guard let paymentMethodParams = linkAccount.makePaymentMethodParams(from: paymentDetails) else {
                    let error = PaymentSheetError.unknown(debugDescription: "Paying with Link without valid session")
                    completion(.failed(error: error))
                    return
                }

                confirmWithPaymentMethodParams(paymentMethodParams)
            }

            let createPaymentDetailsAndConfirm: (STPPaymentMethodParams) -> Void = { paymentMethodParams in
                guard linkAccount.sessionState == .verified else {
                    assertionFailure("Creating payment details without a verified session")
                    // Attempt to confirm directly with params
                    confirmWithPaymentMethodParams(paymentMethodParams)
                    return
                }

                linkAccount.createPaymentDetails(with: paymentMethodParams) { result in
                    switch result {
                    case .success(let paymentDetails):
                        confirmWithPaymentDetails(paymentDetails)
                    case .failure(_):
                        assertionFailure("Failed to create payment details")
                        // Attempt to confirm directly with params
                        confirmWithPaymentMethodParams(paymentMethodParams)
                    }
                }
            }

            switch confirmOption {
            case .forNewAccount(let phoneNumber, let legalName, let paymentMethodParams):
                linkAccount.signUp(with: phoneNumber, legalName: legalName) { result in
                    switch result {
                    case .success():
                        STPAnalyticsClient.sharedClient.logLinkSignupComplete()
                        createPaymentDetailsAndConfirm(paymentMethodParams)
                    case .failure(_):
                        STPAnalyticsClient.sharedClient.logLinkSignupFailure()
                        // Attempt to confirm directly with params
                        confirmWithPaymentMethodParams(paymentMethodParams)
                    }
                }
            case .withPaymentDetails(paymentDetails: let paymentDetails):
                confirmWithPaymentDetails(paymentDetails)
            case .withPaymentMethodParams(let paymentMethodParams):
                createPaymentDetailsAndConfirm(paymentMethodParams)
            }
        }
    }

    /// Fetches the PaymentIntent or SetupIntent and Customer's saved PaymentMethods
    static func load(
        clientSecret: IntentClientSecret,
        configuration: Configuration,
        completion: @escaping (LoadingResult) -> Void
    ) {
        let intentPromise = Promise<Intent>()
        let paymentMethodsPromise = Promise<[STPPaymentMethod]>()
        let loadSpecsPromise = Promise<Void>()
        
        intentPromise.observe { result in
            switch result {
            case .success(let intent):
                paymentMethodsPromise.observe { result in
                    switch result {
                    case .success(let paymentMethods):
                        // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
                        let savedPaymentMethods = paymentMethods
                            .filter { intent.recommendedPaymentMethodTypes.contains($0.type) }
                            .filter { PaymentSheet.supportsSaveAndReuse(paymentMethod: $0.type, configuration: configuration, intent: intent) }
                        warnUnactivatedIfNeeded(unactivatedPaymentMethodTypes: intent.unactivatedPaymentMethodTypes)

                        let linkAccountPromise = PaymentSheet.lookupLinkAccount(
                            intent: intent,
                            configuration: configuration
                        )

                        loadSpecsPromise.observe { _ in
                            linkAccountPromise.observe { linkAccountResult in
                                switch linkAccountResult {
                                case .success(let linkAccount):
                                    completion(.success(
                                        intent: intent,
                                        savedPaymentMethods: savedPaymentMethods,
                                        isLinkEnabled: intent.supportsLink,
                                        linkAccount: linkAccount
                                    ))
                                case .failure(_):
                                    // Move forward without Link
                                    completion(.success(
                                        intent: intent,
                                        savedPaymentMethods: savedPaymentMethods,
                                        isLinkEnabled: false,
                                        linkAccount: nil
                                    ))
                                }
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

        // Fetch PaymentIntent or SetupIntent
        switch clientSecret {
        case .paymentIntent(let clientSecret):
            let paymentIntentHandlerCompletionBlock: ((STPPaymentIntent) -> Void) = { paymentIntent in
                guard ![.succeeded, .canceled, .requiresCapture].contains(paymentIntent.status) else {
                    // Error if the PaymentIntent is in a terminal state
                    let message = "PaymentSheet received a PaymentIntent in a terminal state: \(paymentIntent.status)"
                    completion(.failure(PaymentSheetError.unknown(debugDescription: message)))
                    return
                }
                intentPromise.resolve(with: .paymentIntent(paymentIntent))
            }

            configuration.apiClient.retrievePaymentIntentWithPreferences(withClientSecret: clientSecret) { result in
                switch result {
                case .success(let paymentIntent):
                    paymentIntentHandlerCompletionBlock(paymentIntent)
                case .failure(_):
                    // Fallback to regular retrieve PI when retrieve PI with preferences fails
                    configuration.apiClient.retrievePaymentIntent(withClientSecret: clientSecret) {
                        paymentIntent, error in
                        guard let paymentIntent = paymentIntent, error == nil else {
                            let error =
                                error
                                ?? PaymentSheetError.unknown(
                                    debugDescription: "Failed to retrieve PaymentIntent")
                            intentPromise.reject(with: error)
                            return
                        }

                        paymentIntentHandlerCompletionBlock(paymentIntent)
                    }
                }
            }
        case .setupIntent(let clientSecret):
            let setupIntentHandlerCompletionBlock: ((STPSetupIntent) -> Void) = { setupIntent in
                guard ![.succeeded, .canceled].contains(setupIntent.status) else {
                    // Error if the SetupIntent is in a terminal state
                    let message = "PaymentSheet received a SetupIntent in a terminal state: \(setupIntent.status)"
                    completion(.failure(PaymentSheetError.unknown(debugDescription: message)))
                    return
                }
                intentPromise.resolve(with: .setupIntent(setupIntent))
            }

            configuration.apiClient.retrieveSetupIntentWithPreferences(withClientSecret: clientSecret) { result in
                switch result {
                case .success(let setupIntent):
                    setupIntentHandlerCompletionBlock(setupIntent)
                case .failure(_):
                    // Fallback to regular retrieve SI when retrieve SI with preferences fails
                    configuration.apiClient.retrieveSetupIntent(withClientSecret: clientSecret) { setupIntent, error in
                        guard let setupIntent = setupIntent, error == nil else {
                            let error =
                                error
                                ?? PaymentSheetError.unknown(
                                    debugDescription: "Failed to retrieve SetupIntent")
                            intentPromise.reject(with: error)
                            return
                        }

                        setupIntentHandlerCompletionBlock(setupIntent)
                    }
                }
            }
        }

        // List the Customer's saved PaymentMethods
        let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount] // hardcoded for now
        if let customerID = configuration.customer?.id, let ephemeralKey = configuration.customer?.ephemeralKeySecret {
            configuration.apiClient.listPaymentMethods(
                forCustomer: customerID,
                using: ephemeralKey,
                types: savedPaymentMethodTypes
            ) { paymentMethods, error in
                guard let paymentMethods = paymentMethods, error == nil else {
                    let error = error ?? PaymentSheetError.unknown(
                        debugDescription: "Failed to retrieve PaymentMethods for the customer"
                    )
                    paymentMethodsPromise.reject(with: error)
                    return
                }
                paymentMethodsPromise.resolve(with: paymentMethods)
            }
        } else {
            paymentMethodsPromise.resolve(with: [])
        }
        
        // Load configuration
        AddressSpecProvider.shared.loadAddressSpecs {
            // Load form specs
            FormSpecProvider.shared.load { _ in
                //Load BSB data
                BSBNumberProvider.shared.loadBSBData {
                    loadSpecsPromise.resolve(with: ())
                }
            }
        }
    }

    static func lookupLinkAccount(
        intent: Intent,
        configuration: Configuration
    ) -> Promise<PaymentSheetLinkAccount?> {
        // Only lookup the consumer account if Link is supported
        guard intent.supportsLink else {
            return .init(value: nil)
        }

        let promise = Promise<PaymentSheetLinkAccount?>()

        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient)

        let consumerSessionLookupBlock: (String?) -> Void = { email in
            if let email = email, linkAccountService.hasEmailLoggedOut(email: email) {
                promise.resolve(with: nil)
                return
            }

            linkAccountService.lookupAccount(withEmail: email) { result in
                switch result {
                case .success(let linkAccount):
                    promise.resolve(with: linkAccount)
                case .failure(let error):
                    promise.reject(with: error)
                }
            }
        }

        if linkAccountService.hasSessionCookie {
            consumerSessionLookupBlock(nil)
        } else if let email = configuration.defaultBillingDetails.email {
            consumerSessionLookupBlock(email)
        } else if let customerID = configuration.customer?.id, let ephemeralKey = configuration.customer?.ephemeralKeySecret {
            configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey) { customer, _ in
                // If there's an error in this call we can just ignore it
                consumerSessionLookupBlock(customer?.email)
            }
        } else {
            promise.resolve(with: nil)
        }

        return promise
    }
    
    private static func warnUnactivatedIfNeeded(unactivatedPaymentMethodTypes: [STPPaymentMethodType]) {
        guard !unactivatedPaymentMethodTypes.isEmpty else { return }
        
        let message = """
            [Stripe SDK] Warning: Your Intent contains the following payment method types which are activated for test mode but not activated for live mode: \(unactivatedPaymentMethodTypes.map({$0.displayName}).joined(separator: ",")). These payment method types will not be displayed in live mode until they are activated. To activate these payment method types visit your Stripe dashboard.
            More information: https://support.stripe.com/questions/activate-a-new-payment-method
            """
        print(message)
    }
}

/// Internal authentication context for PaymentSheet magic
protocol PaymentSheetAuthenticationContext: STPAuthenticationContext {
    func present(_ threeDS2ChallengeViewController: UIViewController, completion: @escaping () -> Void)
    func dismiss(_ threeDS2ChallengeViewController: UIViewController)
}

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
    /// Confirms a PaymentIntent with the given PaymentOption and returns a PaymentResult
    static func confirm(
        configuration: PaymentSheet.Configuration,
        authenticationContext: STPAuthenticationContext,
        intent: Intent,
        paymentOption: PaymentOption,
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
                    let error: Error =
                        error
                        ?? PaymentSheetError.unknown(
                            debugDescription: "STPPaymentHandler failed without an error")
                    completion(.failed(error: error))
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
                        STPPaymentHandler.shared().confirmPayment(
                            paymentIntentParams,
                            with: authenticationContext,
                            completion: paymentHandlerCompletion)
                    }
                } else {
                    let paymentIntentParams = confirmParams.makeParams(paymentIntentClientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.returnURL = configuration.returnURL
                    STPPaymentHandler.shared().confirmPayment(
                        paymentIntentParams,
                        with: authenticationContext,
                        completion: paymentHandlerCompletion)
                }
            // MARK: SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = confirmParams.makeParams(setupIntentClientSecret: setupIntent.clientSecret)
                setupIntentParams.returnURL = configuration.returnURL
                STPPaymentHandler.shared().confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion)
            }

        // MARK: Saved Payment Method
        case let .saved(paymentMethod):
            switch intent {
            // MARK: PaymentIntent
            case .paymentIntent(let paymentIntent):
                let paymentIntentParams = STPPaymentIntentParams(
                    clientSecret: paymentIntent.clientSecret)
                paymentIntentParams.returnURL = configuration.returnURL
                paymentIntentParams.paymentMethodId = paymentMethod.stripeId
                STPPaymentHandler.shared().confirmPayment(
                    paymentIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion)
            // MARK: SetupIntent
            case .setupIntent(let setupIntent):
                let setupIntentParams = STPSetupIntentConfirmParams(
                    clientSecret: setupIntent.clientSecret)
                setupIntentParams.returnURL = configuration.returnURL
                setupIntentParams.paymentMethodID = paymentMethod.stripeId
                STPPaymentHandler.shared().confirmSetupIntent(
                    setupIntentParams,
                    with: authenticationContext,
                    completion: paymentHandlerCompletion)

            }
        }
    }

    /// Fetches the PaymentIntent or SetupIntent and Customer's saved PaymentMethods
    static func load(
        clientSecret: IntentClientSecret,
        configuration: Configuration,
        completion: @escaping ((Result<(Intent, [STPPaymentMethod]), Error>) -> Void)
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
                        loadSpecsPromise.observe { _ in
                            completion(.success((intent, savedPaymentMethods)))
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
                guard paymentIntent.status == .requiresPaymentMethod else {
                    let message =
                        paymentIntent.status == .succeeded
                        ? "PaymentSheet received a PaymentIntent that is already completed!"
                        : "PaymentSheet received a PaymentIntent in an unexpected state: \(paymentIntent.status)"
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
                guard setupIntent.status == .requiresPaymentMethod else {
                    let message =
                        setupIntent.status == .succeeded
                        ? "PaymentSheet received SetupIntent that is already completed!"
                        : "PaymentSheet received a SetupIntent in an unexpected state: \(setupIntent.status)"
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
        let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card] // hardcoded for now
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
            loadSpecsPromise.resolve(with: ())
        }
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

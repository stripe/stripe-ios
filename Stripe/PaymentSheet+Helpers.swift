//
//  PaymentSheet+Helpers.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

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
                if STPAPIClient.shared.publishableKey?.hasPrefix("uk_") ?? false {
                    STPAPIClient.shared.createPaymentMethod(with: confirmParams.paymentMethodParams) {
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
        apiClient: STPAPIClient,
        clientSecret: IntentClientSecret,
        ephemeralKey: String? = nil,
        customerID: String? = nil,
        completion: @escaping ((Result<(Intent, [STPPaymentMethod]), Error>) -> Void)
    ) {
        let intentPromise = Promise<Intent>()
        let paymentMethodsPromise = Promise<[STPPaymentMethod]>()
        intentPromise.observe { result in
            switch result {
            case .success(let intent):
                paymentMethodsPromise.observe { result in
                    switch result {
                    case .success(let paymentMethods):
                        let savedPaymentMethods = paymentMethods.filter {
                            // Filter out payment methods that the PI/SI or PaymentSheet doesn't support
                            let isSupportedByIntent = intent.paymentMethodTypes.contains($0.type)
                            let isSupportedByPaymentSheet = PaymentSheet.supportedPaymentMethods
                                .contains($0.type)
                            return isSupportedByIntent && isSupportedByPaymentSheet
                        }

                        completion(.success((intent, savedPaymentMethods)))
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
            apiClient.retrievePaymentIntentWithPreferences(withClientSecret: clientSecret) { result in
                switch result {
                case .success(let paymentIntent):
                    guard paymentIntent.status == .requiresPaymentMethod else {
                        let message =
                            paymentIntent.status == .succeeded
                            ? "PaymentSheet received a PaymentIntent that is already completed!"
                            : "PaymentSheet received a PaymentIntent in an unexpected state: \(paymentIntent.status)"
                        completion(.failure(PaymentSheetError.unknown(debugDescription: message)))
                        return
                    }
                    intentPromise.resolve(with: .paymentIntent(paymentIntent))
                case .failure(let error):
                    intentPromise.reject(with: error)
                }
            }
        case .setupIntent(let clientSecret):
            apiClient.retrieveSetupIntentWithPreferences(withClientSecret: clientSecret) { result in
                switch result {
                case .success(let setupIntent):
                    guard setupIntent.status == .requiresPaymentMethod else {
                        let message =
                            setupIntent.status == .succeeded
                            ? "PaymentSheet received SetupIntent that is already completed!"
                            : "PaymentSheet received a SetupIntent in an unexpected state: \(setupIntent.status)"
                        completion(.failure(PaymentSheetError.unknown(debugDescription: message)))
                        return
                    }
                    intentPromise.resolve(with: .setupIntent(setupIntent))
                case .failure(let error):
                    intentPromise.reject(with: error)
                }
            }
        }

        // List the Customer's saved PaymentMethods
        let savedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .SEPADebit] // hardcoded for now
        if let customerID = customerID, let ephemeralKey = ephemeralKey {
            apiClient.listPaymentMethods(
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
    }
}

extension PaymentSheet {
    /// Returns a list of payment method types supported by PaymentSheet ordered from most recommended to least
    static func paymentMethodTypes(for intent: Intent, customerID: String?)
        -> [STPPaymentMethodType]
    {
        // TODO: Use the customer's last used PaymentMethod type
        switch intent {
        case .paymentIntent:
            return intent.orderedPaymentMethodTypes.filter {
                supportedPaymentMethods.contains($0)
            }
        case .setupIntent:
            return intent.orderedPaymentMethodTypes.filter {
                supportedPaymentMethodsForReuse.contains($0)
            }
        }
    }
}

//
//  STPAPIClient+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 9/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAPIClient {
    typealias STPIntentCompletionBlock = ((Result<Intent, Error>) -> Void)

    func makeElementsSessionsParams(mode: PaymentSheet.InitializationMode, epmConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration?) -> [String: Any] {
        var parameters: [String: Any] = [
            "locale": Locale.current.toLanguageTag(),
            "external_payment_methods": epmConfiguration?.externalPaymentMethods.compactMap { $0.lowercased() } ?? [],
        ]
        switch mode {
        case .deferredIntent(let intentConfig):
            parameters["type"] = "deferred_intent"
            parameters["key"] = publishableKey
            parameters["deferred_intent"] = {
                var deferredIntent = [String: Any]()
                deferredIntent["payment_method_types"] = intentConfig.paymentMethodTypes
                deferredIntent["on_behalf_of"] = intentConfig.onBehalfOf
                switch intentConfig.mode {
                case .payment(let amount, let currency, let setupFutureUsage, let captureMethod):
                    deferredIntent["mode"] = "payment"
                    deferredIntent["amount"] = amount
                    deferredIntent["currency"] = currency
                    deferredIntent["setup_future_usage"] = setupFutureUsage?.rawValue
                    deferredIntent["capture_method"] = captureMethod.rawValue
                case .setup(let currency, let setupFutureUsage):
                    deferredIntent["mode"] = "setup"
                    deferredIntent["currency"] = currency
                    deferredIntent["setup_future_usage"] = setupFutureUsage.rawValue
                }
                return deferredIntent
            }()
        case .paymentIntentClientSecret(let clientSecret):
            parameters["type"] = "payment_intent"
            parameters["client_secret"] = clientSecret
            parameters["expand"] = ["payment_method_preference.payment_intent.payment_method"]
        case .setupIntentClientSecret(let clientSecret):
            parameters["type"] = "setup_intent"
            parameters["client_secret"] = clientSecret
            parameters["expand"] = ["payment_method_preference.setup_intent.payment_method"]
        }
        return parameters
    }

    func retrieveElementsSession(
        paymentIntentClientSecret: String,
        configuration: PaymentSheet.Configuration
    ) async throws -> (STPPaymentIntent, STPElementsSession) {
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: makeElementsSessionsParams(mode: .paymentIntentClientSecret(paymentIntentClientSecret), epmConfiguration: configuration.externalPaymentMethodConfiguration)
        )
        // The v1/elements/sessions response contains a PaymentIntent hash that we parse out into a PaymentIntent
        guard
            let paymentIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "payment_intent"],
            let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)
        else {
            throw PaymentSheetError.unknown(debugDescription: "PaymentIntent missing from v1/elements/sessions response")
        }
        return (paymentIntent, elementsSession)
    }

    func retrieveElementsSession(
        setupIntentClientSecret: String,
        configuration: PaymentSheet.Configuration
    ) async throws -> (STPSetupIntent, STPElementsSession) {
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: makeElementsSessionsParams(mode: .setupIntentClientSecret(setupIntentClientSecret), epmConfiguration: configuration.externalPaymentMethodConfiguration)
        )
        // The v1/elements/sessions response contains a SetupIntent hash that we parse out into a SetupIntent
        guard
            let setupIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "setup_intent"],
            let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentJSON)
        else {
            throw PaymentSheetError.unknown(debugDescription: "SetupIntent missing from v1/elements/sessions response")
        }
        return (setupIntent, elementsSession)
    }

    func retrieveElementsSession(
        withIntentConfig intentConfig: PaymentSheet.IntentConfiguration,
        configuration: PaymentSheet.Configuration
    ) async throws -> STPElementsSession {
        let parameters = makeElementsSessionsParams(mode: .deferredIntent(intentConfig), epmConfiguration: configuration.externalPaymentMethodConfiguration)
        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
    }

    func retrieveElementsSessionForCustomerSheet() async throws -> STPElementsSession {
        var parameters: [String: Any] = [:]
        parameters["type"] = "deferred_intent"
        parameters["locale"] = Locale.current.toLanguageTag()

        var deferredIntent = [String: Any]()
        deferredIntent["mode"] = "setup"
        parameters["deferred_intent"] = deferredIntent

        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
    }
}

private let APIEndpointElementsSessions = "elements/sessions"

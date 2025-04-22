//
//  STPAPIClient+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 9/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(CustomerSessionBetaAccess) @_spi(STP) import StripePayments

extension STPAPIClient {
    typealias STPIntentCompletionBlock = ((Result<Intent, Error>) -> Void)

    func makeElementsSessionsParams(mode: PaymentSheet.InitializationMode,
                                    epmConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration?,
                                    cpmConfiguration: PaymentSheet.CustomPaymentMethodConfiguration?,
                                    clientDefaultPaymentMethod: String?,
                                    customerAccessProvider: PaymentSheet.CustomerAccessProvider?) -> [String: Any] {
        var parameters: [String: Any] = [
            "locale": Locale.current.toLanguageTag(),
            "external_payment_methods": epmConfiguration?.externalPaymentMethods.compactMap { $0.lowercased() } ?? [],
            "custom_payment_methods": cpmConfiguration?.customPaymentMethods.compactMap { $0.id } ?? [],
        ]
        if let appId = Bundle.main.bundleIdentifier {
            parameters["mobile_app_id"] = appId
        }
        if case .customerSession(let clientSecret) = customerAccessProvider {
            parameters["customer_session_client_secret"] = clientSecret
        }
        if let clientDefaultPaymentMethod {
            parameters["client_default_payment_method"] = clientDefaultPaymentMethod
        }
        switch mode {
        case .deferredIntent(let intentConfig):
            parameters["type"] = "deferred_intent"
            parameters["key"] = publishableKey
            parameters["deferred_intent"] = {
                var deferredIntent = [String: Any]()
                deferredIntent["payment_method_types"] = intentConfig.paymentMethodTypes
                deferredIntent["on_behalf_of"] = intentConfig.onBehalfOf
                if let paymentMethodConfigurationId = intentConfig.paymentMethodConfigurationId {
                    deferredIntent["payment_method_configuration"] = ["id": paymentMethodConfigurationId]
                }
                switch intentConfig.mode {
                case .payment(let amount, let currency, let setupFutureUsage, let captureMethod, _):
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
        clientDefaultPaymentMethod: String?,
        configuration: PaymentElementConfiguration
    ) async throws -> (STPPaymentIntent, STPElementsSession) {
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: makeElementsSessionsParams(mode: .paymentIntentClientSecret(paymentIntentClientSecret),
                                                   epmConfiguration: configuration.externalPaymentMethodConfiguration,
                                                   cpmConfiguration: configuration.customPaymentMethodConfiguration,
                                                   clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                   customerAccessProvider: configuration.customer?.customerAccessProvider)
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
        clientDefaultPaymentMethod: String?,
        configuration: PaymentElementConfiguration
    ) async throws -> (STPSetupIntent, STPElementsSession) {
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: makeElementsSessionsParams(mode: .setupIntentClientSecret(setupIntentClientSecret),
                                                   epmConfiguration: configuration.externalPaymentMethodConfiguration,
                                                   cpmConfiguration: configuration.customPaymentMethodConfiguration,
                                                   clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                   customerAccessProvider: configuration.customer?.customerAccessProvider)
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

    func retrieveDeferredElementsSession(
        withIntentConfig intentConfig: PaymentSheet.IntentConfiguration,
        clientDefaultPaymentMethod: String?,
        configuration: PaymentElementConfiguration
    ) async throws -> STPElementsSession {
        let parameters = makeElementsSessionsParams(mode: .deferredIntent(intentConfig),
                                                    epmConfiguration: configuration.externalPaymentMethodConfiguration,
                                                    cpmConfiguration: configuration.customPaymentMethodConfiguration,
                                                    clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                    customerAccessProvider: configuration.customer?.customerAccessProvider)
        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
    }

    func retrieveDeferredElementsSessionForCustomerSheet(paymentMethodTypes: [String]?,
                                                         clientDefaultPaymentMethod: String?,
                                                         customerSessionClientSecret: CustomerSessionClientSecret?) async throws -> STPElementsSession {

        let parameters = makeDeferredElementsSessionsParamsForCustomerSheet(paymentMethodTypes: paymentMethodTypes,
                                                                            clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                            customerSessionClientSecret: customerSessionClientSecret)
        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
    }

    func makeDeferredElementsSessionsParamsForCustomerSheet(paymentMethodTypes: [String]?,
                                                            clientDefaultPaymentMethod: String?,
                                                            customerSessionClientSecret: CustomerSessionClientSecret?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["type"] = "deferred_intent"
        parameters["locale"] = Locale.current.toLanguageTag()

        if let customerSessionClientSecret {
            parameters["customer_session_client_secret"] = customerSessionClientSecret.clientSecret
        }

        if let clientDefaultPaymentMethod {
            parameters["client_default_payment_method"] = clientDefaultPaymentMethod
        }

        var deferredIntent = [String: Any]()
        deferredIntent["mode"] = "setup"
        if let paymentMethodTypes {
            deferredIntent["payment_method_types"] = paymentMethodTypes
        }
        parameters["deferred_intent"] = deferredIntent
        return parameters
    }

    func retrieveElementsSessionForCustomerSheet(setupIntentClientSecret: String,
                                                 clientDefaultPaymentMethod: String?,
                                                 customerSessionClientSecret: CustomerSessionClientSecret?) async throws -> STPElementsSession {
        let parameters = makeElementsSessionsParamsForCustomerSheet(setupIntentClientSecret: setupIntentClientSecret,
                                                                    clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                    customerSessionClientSecret: customerSessionClientSecret)
        return try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
    }

    func makeElementsSessionsParamsForCustomerSheet(setupIntentClientSecret: String,
                                                    clientDefaultPaymentMethod: String?,
                                                    customerSessionClientSecret: CustomerSessionClientSecret?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["type"] = "setup_intent"
        parameters["client_secret"] = setupIntentClientSecret
        parameters["expand"] = ["payment_method_preference.setup_intent.payment_method"]

        parameters["locale"] = Locale.current.toLanguageTag()

        if let customerSessionClientSecret {
            parameters["customer_session_client_secret"] = customerSessionClientSecret.clientSecret
        }

        if let clientDefaultPaymentMethod {
            parameters["client_default_payment_method"] = clientDefaultPaymentMethod
        }
        return parameters
    }
}

private let APIEndpointElementsSessions = "elements/sessions"

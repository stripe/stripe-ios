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

    func makeElementsSessionsParams(
        mode: PaymentSheet.InitializationMode,
        epmConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration?,
        cpmConfiguration: PaymentSheet.CustomPaymentMethodConfiguration?,
        clientDefaultPaymentMethod: String?,
        customerAccessProvider: PaymentSheet.CustomerAccessProvider?,
        linkDisallowFundingSourceCreation: Set<String>,
        userOverrideCountry: String? = nil
    ) -> [String: Any] {
        var parameters: [String: Any] = [
            "locale": Locale.current.toLanguageTag(),
            "external_payment_methods": epmConfiguration?.externalPaymentMethods.compactMap { $0.lowercased() } ?? [],
            "custom_payment_methods": cpmConfiguration?.customPaymentMethods.compactMap { $0.id } ?? [],
        ]
        if !linkDisallowFundingSourceCreation.isEmpty {
            parameters["link"] = [
                "disallow_funding_source_creation": Array(linkDisallowFundingSourceCreation),
            ]
        }
        if let userOverrideCountry {
            parameters["country_override"] = userOverrideCountry
        }
        if let sessionId = AnalyticsHelper.shared.sessionID {
            parameters["mobile_session_id"] = sessionId
        }
        if let appId = Bundle.main.bundleIdentifier {
            parameters["mobile_app_id"] = appId
        }
        if case .customerSession(let clientSecret) = customerAccessProvider {
            parameters["customer_session_client_secret"] = clientSecret
        } else if case .legacyCustomerEphemeralKey(let ephemeralKey) = customerAccessProvider {
            parameters["legacy_customer_ephemeral_key"] = ephemeralKey
        }
        if let clientDefaultPaymentMethod {
            parameters["client_default_payment_method"] = clientDefaultPaymentMethod
        }
        switch mode {
        case .deferredIntent(let intentConfig):
            parameters["type"] = "deferred_intent"
            parameters["key"] = publishableKey
            if let sellerDetails = intentConfig.sellerDetails {
                parameters["seller_details"] = [
                    "network_id": sellerDetails.networkId,
                    "external_id": sellerDetails.externalId,
                ]
            }
            parameters["deferred_intent"] = {
                var deferredIntent = [String: Any]()
                deferredIntent["payment_method_types"] = intentConfig.paymentMethodTypes
                deferredIntent["on_behalf_of"] = intentConfig.onBehalfOf
                if let paymentMethodConfigurationId = intentConfig.paymentMethodConfigurationId {
                    deferredIntent["payment_method_configuration"] = ["id": paymentMethodConfigurationId]
                }
                switch intentConfig.mode {
                case .payment(let amount, let currency, let setupFutureUsage, let captureMethod, let paymentMethodOptions):
                    deferredIntent["mode"] = "payment"
                    deferredIntent["amount"] = amount
                    deferredIntent["currency"] = currency
                    deferredIntent["setup_future_usage"] = setupFutureUsage?.rawValue
                    deferredIntent["capture_method"] = captureMethod.rawValue
                    if let paymentMethodOptions,
                       let setupFutureUsageValues = paymentMethodOptions.setupFutureUsageValues {
                        var paymentMethodOptionsDict = [String: Any]()
                        for (paymentMethodType, setupFutureUsageValue) in setupFutureUsageValues {
                            paymentMethodOptionsDict[paymentMethodType.identifier] = [
                                "setup_future_usage": setupFutureUsageValue.rawValue
                            ]
                        }
                        deferredIntent["payment_method_options"] = paymentMethodOptionsDict
                    }
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
            parameters: makeElementsSessionsParams(
                mode: .paymentIntentClientSecret(paymentIntentClientSecret),
                epmConfiguration: configuration.externalPaymentMethodConfiguration,
                cpmConfiguration: configuration.customPaymentMethodConfiguration,
                clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                customerAccessProvider: configuration.customer?.customerAccessProvider,
                linkDisallowFundingSourceCreation: configuration.link.disallowFundingSourceCreation,
                userOverrideCountry: configuration.userOverrideCountry
            )
        )
        // The v1/elements/sessions response contains a PaymentIntent hash that we parse out into a PaymentIntent
        guard
            let paymentIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "payment_intent"],
            let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)
        else {
            throw PaymentSheetError.unknown(debugDescription: "PaymentIntent missing from v1/elements/sessions response")
        }
        try verifyCustomerSessionForPaymentSheet(configuration: configuration, elementsSession: elementsSession)
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
            parameters: makeElementsSessionsParams(
                mode: .setupIntentClientSecret(setupIntentClientSecret),
                epmConfiguration: configuration.externalPaymentMethodConfiguration,
                cpmConfiguration: configuration.customPaymentMethodConfiguration,
                clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                customerAccessProvider: configuration.customer?.customerAccessProvider,
                linkDisallowFundingSourceCreation: configuration.link.disallowFundingSourceCreation,
                userOverrideCountry: configuration.userOverrideCountry
            )
        )
        // The v1/elements/sessions response contains a SetupIntent hash that we parse out into a SetupIntent
        guard
            let setupIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "setup_intent"],
            let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentJSON)
        else {
            throw PaymentSheetError.unknown(debugDescription: "SetupIntent missing from v1/elements/sessions response")
        }
        try verifyCustomerSessionForPaymentSheet(configuration: configuration, elementsSession: elementsSession)
        return (setupIntent, elementsSession)
    }

    func retrieveDeferredElementsSession(
        withIntentConfig intentConfig: PaymentSheet.IntentConfiguration,
        clientDefaultPaymentMethod: String?,
        configuration: PaymentElementConfiguration
    ) async throws -> STPElementsSession {
        let parameters = makeElementsSessionsParams(
            mode: .deferredIntent(intentConfig),
            epmConfiguration: configuration.externalPaymentMethodConfiguration,
            cpmConfiguration: configuration.customPaymentMethodConfiguration,
            clientDefaultPaymentMethod: clientDefaultPaymentMethod,
            customerAccessProvider: configuration.customer?.customerAccessProvider,
            linkDisallowFundingSourceCreation: configuration.link.disallowFundingSourceCreation,
            userOverrideCountry: configuration.userOverrideCountry
        )
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
        try verifyCustomerSessionForPaymentSheet(configuration: configuration, elementsSession: elementsSession)
        return elementsSession
    }

    func verifyCustomerSessionForPaymentSheet(configuration: PaymentElementConfiguration, elementsSession: STPElementsSession) throws {
        if case .customerSession = configuration.customer?.customerAccessProvider {
            // User passed in a customerSessionClient secret
            if let customer = elementsSession.customer {
                // If claimed, customer will be not nil.
                // Verify that it was created specifically for `mobile_payment_element`, or fail loudly
                if !customer.customerSession.mobilePaymentElementComponent.enabled {
                    stpAssertionFailure("Integration Error: Attempting to use a customerSession with MobilePaymentElement that does not have `mobile_payment_element` component enabled")
                    throw PaymentSheetError.unknown(debugDescription: "Attempting to use customerSession without `mobile_payment_element` component enabled")
                }
            } else {
                // If customer does not exist: backend issue or failure in deserialization, fail.
                throw PaymentSheetError.unknown(debugDescription: "Failed to claim customerSession")
            }
        }
    }

    func retrieveDeferredElementsSessionForCustomerSheet(paymentMethodTypes: [String]?,
                                                         onBehalfOf: String?,
                                                         clientDefaultPaymentMethod: String?,
                                                         customerSessionClientSecret: CustomerSessionClientSecret?) async throws -> STPElementsSession {

        let parameters = makeDeferredElementsSessionsParamsForCustomerSheet(paymentMethodTypes: paymentMethodTypes,
                                                                            onBehalfOf: onBehalfOf,
                                                                            clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                            customerSessionClientSecret: customerSessionClientSecret)
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
        try verifyCustomerSessionForCustomerSheet(customerSessionClientSecret: customerSessionClientSecret, elementsSession: elementsSession)
        return elementsSession
    }

    func makeDeferredElementsSessionsParamsForCustomerSheet(paymentMethodTypes: [String]?,
                                                            onBehalfOf: String?,
                                                            clientDefaultPaymentMethod: String?,
                                                            customerSessionClientSecret: CustomerSessionClientSecret?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["type"] = "deferred_intent"
        parameters["locale"] = Locale.current.toLanguageTag()

        if let sessionId = AnalyticsHelper.shared.sessionID {
            parameters["mobile_session_id"] = sessionId
        }

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
        deferredIntent["on_behalf_of"] = onBehalfOf
        parameters["deferred_intent"] = deferredIntent
        return parameters
    }

    func retrieveElementsSessionForCustomerSheet(setupIntentClientSecret: String,
                                                 clientDefaultPaymentMethod: String?,
                                                 customerSessionClientSecret: CustomerSessionClientSecret?) async throws -> STPElementsSession {
        let parameters = makeElementsSessionsParamsForCustomerSheet(setupIntentClientSecret: setupIntentClientSecret,
                                                                    clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                                                                    customerSessionClientSecret: customerSessionClientSecret)
        let elementsSession = try await APIRequest<STPElementsSession>.getWith(
            self,
            endpoint: APIEndpointElementsSessions,
            parameters: parameters
        )
        try verifyCustomerSessionForCustomerSheet(customerSessionClientSecret: customerSessionClientSecret, elementsSession: elementsSession)
        return elementsSession
    }

    func makeElementsSessionsParamsForCustomerSheet(setupIntentClientSecret: String,
                                                    clientDefaultPaymentMethod: String?,
                                                    customerSessionClientSecret: CustomerSessionClientSecret?) -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["type"] = "setup_intent"
        parameters["client_secret"] = setupIntentClientSecret
        parameters["expand"] = ["payment_method_preference.setup_intent.payment_method"]

        parameters["locale"] = Locale.current.toLanguageTag()

        if let sessionId = AnalyticsHelper.shared.sessionID {
            parameters["mobile_session_id"] = sessionId
        }

        if let customerSessionClientSecret {
            parameters["customer_session_client_secret"] = customerSessionClientSecret.clientSecret
        }

        if let clientDefaultPaymentMethod {
            parameters["client_default_payment_method"] = clientDefaultPaymentMethod
        }
        return parameters
    }
    func verifyCustomerSessionForCustomerSheet(customerSessionClientSecret: CustomerSessionClientSecret?, elementsSession: STPElementsSession) throws {
        if customerSessionClientSecret != nil {
            // User passed in a customerSessionClient secret
            if let customer = elementsSession.customer {
                // If claimed, customer will be not nil.
                // Verify that it was created specifically for `customer_sheet`, or fail loudly
                if !customer.customerSession.customerSheetComponent.enabled {
                    stpAssertionFailure("Integration Error: Attempting to use a customerSession with CustomerSheet that does not have `customer_sheet` component enabled")
                    throw PaymentSheetError.unknown(debugDescription: "Attempting to use customerSession without `customer_sheet` component enabled")
                }
            } else {
                // If customer does not exist: backend issue or failure in deserialization, fail.
                throw PaymentSheetError.unknown(debugDescription: "Failed to claim customerSession")
            }
        }
    }
}

private let APIEndpointElementsSessions = "elements/sessions"

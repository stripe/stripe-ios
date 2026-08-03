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

enum MobileSessionContractError: Error, AnalyticLoggableError, LocalizedError {
    case missingResponseHeader
    case malformedResponseHeader
    case missingPayload
    case decodeFailure
    case unsupportedContractMajor(Int)
    case invalidContractRevision
    case responseHeaderBodyMismatch
    case requestFailed(Error)

    var analyticsErrorType: String {
        "mobile_session_contract_error"
    }

    var analyticsErrorCode: String {
        switch self {
        case .missingResponseHeader: return "missing_response_header"
        case .malformedResponseHeader: return "malformed_response_header"
        case .missingPayload: return "missing_payload"
        case .decodeFailure: return "decode_failure"
        case .unsupportedContractMajor: return "unsupported_contract_major"
        case .invalidContractRevision: return "invalid_contract_revision"
        case .responseHeaderBodyMismatch: return "response_header_body_mismatch"
        case .requestFailed: return "request_failed"
        }
    }

    var errorDescription: String? {
        "The server returned an invalid Mobile Session response (\(analyticsErrorCode))."
    }
}

extension STPAPIClient {
    typealias STPIntentCompletionBlock = ((Result<Intent, Error>) -> Void)

    static let mobileSessionContractHeader = "Stripe-Mobile-Session-Contract"
    static var mobileSessionContractHeaderValue: String {
        "major=\(MobileSessionContractV1.contractMajor); revision=\(MobileSessionContractV1.contractRevision)"
    }

    var mobileSessionContractHeaders: [String: String] {
        [Self.mobileSessionContractHeader: Self.mobileSessionContractHeaderValue]
    }

    static func validateMobileSessionContractResponse(
        _ responseJSON: [AnyHashable: Any],
        _ response: HTTPURLResponse
    ) throws {
        guard let responseHeader = response.value(forHTTPHeaderField: mobileSessionContractHeader) else {
            throw MobileSessionContractError.missingResponseHeader
        }
        let headerContract = try parseMobileSessionContractHeader(responseHeader)
        guard let mobilePaymentElementJSON = responseJSON["mobile_payment_element"] as? [AnyHashable: Any] else {
            throw MobileSessionContractError.missingPayload
        }
        guard JSONSerialization.isValidJSONObject(mobilePaymentElementJSON) else {
            throw MobileSessionContractError.decodeFailure
        }

        let mobilePaymentElement: MobilePaymentElementV1
        do {
            let data = try JSONSerialization.data(withJSONObject: mobilePaymentElementJSON)
            mobilePaymentElement = try StripeJSONDecoder().decode(MobilePaymentElementV1.self, from: data)
        } catch {
            throw MobileSessionContractError.decodeFailure
        }
        guard mobilePaymentElement.contract.major == MobileSessionContractV1.contractMajor else {
            throw MobileSessionContractError.unsupportedContractMajor(mobilePaymentElement.contract.major)
        }
        guard isValidMobileSessionContractRevision(mobilePaymentElement.contract.revision) else {
            throw MobileSessionContractError.invalidContractRevision
        }
        guard headerContract.major == mobilePaymentElement.contract.major,
              headerContract.revision == mobilePaymentElement.contract.revision
        else {
            throw MobileSessionContractError.responseHeaderBodyMismatch
        }
    }

    private static func parseMobileSessionContractHeader(_ value: String) throws -> (major: Int, revision: String) {
        let components = value.components(separatedBy: "; ")
        guard components.count == 2,
              components[0].hasPrefix("major="),
              components[1].hasPrefix("revision=")
        else {
            throw MobileSessionContractError.malformedResponseHeader
        }
        let majorString = String(components[0].dropFirst("major=".count))
        let revision = String(components[1].dropFirst("revision=".count))
        guard let major = Int(majorString),
              String(major) == majorString,
              isValidMobileSessionContractRevision(revision)
        else {
            throw MobileSessionContractError.malformedResponseHeader
        }
        return (major, revision)
    }

    private static func isValidMobileSessionContractRevision(_ value: String) -> Bool {
        value.range(of: "^[0-9a-f]{16}$", options: .regularExpression) != nil
    }

    private func retrieveMobileSessionElementsSession(parameters: [String: Any]) async throws -> STPElementsSession {
        do {
            return try await APIRequest<STPElementsSession>.getWith(
                self,
                endpoint: APIEndpointElementsSessions,
                additionalHeaders: mobileSessionContractHeaders,
                parameters: parameters,
                responseValidator: Self.validateMobileSessionContractResponse
            )
        } catch let error as MobileSessionContractError {
            throw error
        } catch {
            throw MobileSessionContractError.requestFailed(error)
        }
    }

    func makeElementsSessionsParams(
        mode: PaymentSheet.InitializationMode,
        epmConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration?,
        cpmConfiguration: PaymentSheet.CustomPaymentMethodConfiguration?,
        clientDefaultPaymentMethod: String?,
        customerAccessProvider: PaymentSheet.CustomerAccessProvider?,
        linkDisallowFundingSourceCreation: Set<String>,
        paymentSheetConfig: PaymentSheetConfigV1? = nil,
        userOverrideCountry: String? = nil
    ) throws -> [String: Any] {
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
        if let paymentSheetConfig {
            parameters["payment_sheet_config"] = try paymentSheetConfig.encodeJSONDictionary()
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
        case .checkoutSession:
            assertionFailure("CheckoutSession mode should not use makeElementsSessionsParams")
        }
        return parameters
    }

    func retrieveElementsSession(
        paymentIntentClientSecret: String,
        clientDefaultPaymentMethod: String?,
        configuration: PaymentElementConfiguration
    ) async throws -> (STPPaymentIntent, STPElementsSession) {
        let elementsSession = try await retrieveMobileSessionElementsSession(
            parameters: try makeElementsSessionsParams(
                mode: .paymentIntentClientSecret(paymentIntentClientSecret),
                epmConfiguration: configuration.externalPaymentMethodConfiguration,
                cpmConfiguration: configuration.customPaymentMethodConfiguration,
                clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                customerAccessProvider: configuration.customer?.customerAccessProvider,
                linkDisallowFundingSourceCreation: configuration.link.disallowFundingSourceCreation,
                paymentSheetConfig: configuration.paymentSheetConfig,
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
        let elementsSession = try await retrieveMobileSessionElementsSession(
            parameters: try makeElementsSessionsParams(
                mode: .setupIntentClientSecret(setupIntentClientSecret),
                epmConfiguration: configuration.externalPaymentMethodConfiguration,
                cpmConfiguration: configuration.customPaymentMethodConfiguration,
                clientDefaultPaymentMethod: clientDefaultPaymentMethod,
                customerAccessProvider: configuration.customer?.customerAccessProvider,
                linkDisallowFundingSourceCreation: configuration.link.disallowFundingSourceCreation,
                paymentSheetConfig: configuration.paymentSheetConfig,
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
        let parameters = try makeElementsSessionsParams(
            mode: .deferredIntent(intentConfig),
            epmConfiguration: configuration.externalPaymentMethodConfiguration,
            cpmConfiguration: configuration.customPaymentMethodConfiguration,
            clientDefaultPaymentMethod: clientDefaultPaymentMethod,
            customerAccessProvider: configuration.customer?.customerAccessProvider,
            linkDisallowFundingSourceCreation: configuration.link.disallowFundingSourceCreation,
            paymentSheetConfig: configuration.paymentSheetConfig,
            userOverrideCountry: configuration.userOverrideCountry
        )
        let elementsSession = try await retrieveMobileSessionElementsSession(parameters: parameters)
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
                    stpAssertionFailure("Integration Error: Attempting to use a customerSession with MobilePaymentElementV1 that does not have `mobile_payment_element` component enabled")
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

extension PaymentElementConfiguration {
    var paymentSheetConfig: PaymentSheetConfigV1 {
        let billingAddress = defaultBillingDetails.address
        let hasBillingAddress = billingAddress.city != nil
            || billingAddress.country != nil
            || billingAddress.line1 != nil
            || billingAddress.line2 != nil
            || billingAddress.postalCode != nil
            || billingAddress.state != nil
        let paymentSheetConfiguration = self as? PaymentSheet.Configuration
        let customPaymentMethods = customPaymentMethodConfiguration?.customPaymentMethods ?? []

        return PaymentSheetConfigV1(
            merchantCountryCode: applePay?.merchantCountryCode,
            allowsDelayedPaymentMethods: allowsDelayedPaymentMethods,
            allowsPaymentMethodsRequiringShippingAddress: allowsPaymentMethodsRequiringShippingAddress,
            applePay: applePay.map {
                ApplePayConfigV1(
                    merchantCountryCode: $0.merchantCountryCode,
                    merchantId: $0.merchantId,
                    buttonType: $0.buttonType.mobileSessionValue,
                    paymentSummaryItemsProvided: $0.paymentSummaryItems != nil,
                    paymentRequestHandlerProvided: $0.customHandlers?.paymentRequestHandler != nil,
                    authorizationResultHandlerProvided: $0.customHandlers?.authorizationResultHandler != nil,
                    shippingMethodUpdateHandlerProvided: $0.customHandlers?.shippingMethodUpdateHandler != nil,
                    shippingContactUpdateHandlerProvided: $0.customHandlers?.shippingContactUpdateHandler != nil
                )
            },
            googlePay: nil,
            link: LinkConfigV1(
                display: link.display.rawValue,
                brand: link.brand?.rawValue,
                disabledFundingSources: link.disallowFundingSourceCreation.sorted(),
                collectMissingBillingDetailsForExistingPaymentMethods: link.collectMissingBillingDetailsForExistingPaymentMethods
            ),
            shopPay: shopPay.map {
                ShopPayConfigV1(
                    billingAddressRequired: $0.billingAddressRequired,
                    emailRequired: $0.emailRequired,
                    shippingAddressRequired: $0.shippingAddressRequired,
                    allowedShippingCountries: $0.allowedShippingCountries.sorted(),
                    lineItemsProvided: !$0.lineItems.isEmpty,
                    shippingRatesProvided: !$0.shippingRates.isEmpty,
                    shippingMethodUpdateHandlerProvided: $0.handlers?.shippingMethodUpdateHandler != nil,
                    shippingContactUpdateHandlerProvided: $0.handlers?.shippingContactUpdateHandler != nil
                )
            },
            returnUrlProvided: returnURL != nil,
            merchantDisplayNameProvided: !merchantDisplayName.isEmpty,
            customerConfigured: customer != nil,
            customerAccessType: customer?.customerAccessProvider.analyticValue,
            customApiClient: apiClient !== STPAPIClient.shared,
            defaultBillingDetails: BillingDetailsPresenceV1(
                name: defaultBillingDetails.name != nil,
                email: defaultBillingDetails.email != nil,
                phone: defaultBillingDetails.phone != nil,
                address: hasBillingAddress,
                addressCity: billingAddress.city != nil,
                addressLine1: billingAddress.line1 != nil,
                addressLine2: billingAddress.line2 != nil,
                addressPostalCode: billingAddress.postalCode != nil,
                addressState: billingAddress.state != nil,
                addressCountryCode: billingAddress.country
            ),
            shippingDetailsProvided: shippingDetails() != nil,
            savePaymentMethodOptInBehavior: savePaymentMethodOptInBehavior.description,
            primaryButtonLabelProvided: primaryButtonLabel != nil,
            appearanceCustomized: appearance != .default,
            userInterfaceStyle: style.mobileSessionValue,
            preferredNetworks: preferredNetworks?.map(STPCardBrandUtilities.apiValue(from:)) ?? [],
            billingDetailsCollectionConfiguration: BillingDetailsCollectionConfigV1(
                name: billingDetailsCollectionConfiguration.name.rawValue,
                phone: billingDetailsCollectionConfiguration.phone.rawValue,
                email: billingDetailsCollectionConfiguration.email.rawValue,
                address: billingDetailsCollectionConfiguration.address.rawValue,
                attachDefaultsToPaymentMethod: billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod,
                allowedCountries: billingDetailsCollectionConfiguration.allowedCountries.sorted()
            ),
            externalPaymentMethods: externalPaymentMethodConfiguration?.externalPaymentMethods ?? [],
            customPaymentMethodIds: customPaymentMethods.map(\.id),
            customPaymentMethods: customPaymentMethods.map {
                CustomPaymentMethodConfigV1(
                    id: $0.id,
                    subtitleProvided: $0.subtitle != nil,
                    disableBillingDetailCollection: $0.disableBillingDetailCollection
                )
            },
            externalPaymentMethodHandlerProvided: externalPaymentMethodConfiguration != nil,
            customPaymentMethodHandlerProvided: customPaymentMethodConfiguration != nil,
            paymentMethodOrder: paymentMethodOrder ?? [],
            paymentMethodLayout: paymentMethodLayout.analyticValue,
            cardBrandAcceptance: cardBrandAcceptance.mobileSessionValue,
            allowedCardFundingTypes: allowedCardFundingTypes.mobileSessionValues,
            termsDisplay: Dictionary(
                uniqueKeysWithValues: termsDisplay.map { ($0.key.identifier, $0.value.analyticValue) }
            ),
            allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
            removeSavedPaymentMethodMessageProvided: removeSavedPaymentMethodMessage != nil,
            opensCardScannerAutomatically: opensCardScannerAutomatically,
            disableWalletPaymentMethodFiltering: disableWalletPaymentMethodFiltering,
            linkPaymentMethodsOnly: linkPaymentMethodsOnly,
            walletButtons: WalletButtonsConfigV1(
                willDisplayExternally: paymentSheetConfiguration?.willUseWalletButtonsView ?? false,
                paymentElement: paymentSheetConfiguration?.walletButtonsVisibility.paymentElement.mobileSessionValues ?? [:],
                walletButtonsView: paymentSheetConfiguration?.walletButtonsVisibility.walletButtonsView.mobileSessionValues ?? [:]
            ),
            googlePlacesApiKeyProvided: false,
            userOverrideCountry: userOverrideCountry
        )
    }
}

private extension PKPaymentButtonType {
    var mobileSessionValue: String {
        switch rawValue {
        case 0: return "plain"
        case 1: return "buy"
        case 2: return "set_up"
        case 3: return "in_store"
        case 4: return "donate"
        case 5: return "checkout"
        case 6: return "book"
        case 7: return "subscribe"
        case 8: return "reload"
        case 9: return "add_money"
        case 10: return "top_up"
        case 11: return "order"
        case 12: return "rent"
        case 13: return "support"
        case 14: return "contribute"
        case 15: return "tip"
        case 16: return "continue"
        default: return "unknown"
        }
    }
}

private extension PaymentSheet.UserInterfaceStyle {
    var mobileSessionValue: String {
        switch self {
        case .automatic: return "automatic"
        case .alwaysLight: return "light"
        case .alwaysDark: return "dark"
        }
    }
}

private extension Dictionary where Key == PaymentSheet.WalletButtonsVisibility.ExpressType, Value == PaymentSheet.WalletButtonsVisibility.PaymentElementVisibility {
    var mobileSessionValues: [String: String] {
        mapValues { visibility in
            switch visibility {
            case .automatic: return "automatic"
            case .always: return "always"
            case .never: return "never"
            }
        }.reduce(into: [:]) { result, entry in
            result[entry.key.rawValue] = entry.value
        }
    }
}

private extension Dictionary where Key == PaymentSheet.WalletButtonsVisibility.ExpressType, Value == PaymentSheet.WalletButtonsVisibility.WalletButtonsViewVisibility {
    var mobileSessionValues: [String: String] {
        mapValues { visibility in
            switch visibility {
            case .automatic: return "automatic"
            case .never: return "never"
            }
        }.reduce(into: [:]) { result, entry in
            result[entry.key.rawValue] = entry.value
        }
    }
}

private extension PaymentSheet.CardBrandAcceptance {
    var mobileSessionValue: CardBrandAcceptanceV1 {
        switch self {
        case .all:
            return CardBrandAcceptanceV1()
        case .allowed(let brands):
            return CardBrandAcceptanceV1(filter: "allowed", brands: brands.map(\.mobileSessionValue))
        case .disallowed(let brands):
            return CardBrandAcceptanceV1(filter: "disallowed", brands: brands.map(\.mobileSessionValue))
        }
    }
}

private extension PaymentSheet.CardBrandAcceptance.BrandCategory {
    var mobileSessionValue: String {
        switch self {
        case .visa: return "visa"
        case .mastercard: return "mastercard"
        case .amex: return "amex"
        case .discover: return "discover"
        }
    }
}

private extension PaymentSheet.CardFundingType {
    var mobileSessionValues: [String] {
        [
            contains(.credit) ? "credit" : nil,
            contains(.debit) ? "debit" : nil,
            contains(.prepaid) ? "prepaid" : nil,
            contains(.unknown) ? "unknown" : nil,
        ].compactMap { $0 }
    }
}

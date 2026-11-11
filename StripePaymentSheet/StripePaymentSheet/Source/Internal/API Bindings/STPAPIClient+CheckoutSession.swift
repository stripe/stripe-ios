//
//  STPAPIClient+CheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/15/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// The parameters sent to the Checkout Session `/confirm` endpoint.
struct CheckoutSessionConfirmationRequestParameters {
    /// Legacy customer information sent when confirming without a PaymentMethod.
    /// TODO: Remove this once the server can construct no-PaymentMethod CustomerInfo from
    /// fixed and independently collected information.
    struct CustomerData {
        let email: String?
    }

    struct CollectedInformation {
        let email: String?

        var parameters: [String: Any] {
            var parameters: [String: Any] = [:]
            if let email {
                parameters["email"] = email
            }
            return parameters
        }
    }

    /// The ID of the Checkout Session (e.g., `cs_test_xxx`).
    let sessionId: String

    /// The full client secret supplied by the merchant for this Checkout Session.
    let clientSecret: String

    private enum ConfirmationInput {
        case withoutPaymentMethod(customerData: CustomerData)
        case withPaymentMethodID(id: String, expectedType: String, details: PaymentMethodConfirmationDetails)
        case withPaymentMethodData(data: STPPaymentMethodParams, details: PaymentMethodConfirmationDetails)
    }

    private struct PaymentMethodConfirmationDetails {
        /// Omit when no save checkbox is shown; false represents an explicit choice not to save.
        let savePaymentMethod: Bool?
        let paymentMethodOptions: STPConfirmPaymentMethodOptions?
        /// Email collected independently of PaymentMethod billing details.
        let collectedInformation: CollectedInformation

        var parameters: [String: Any] {
            var parameters: [String: Any] = [:]
            // TODO(porter) BLIK: CheckoutClient /confirm does not support BLIK's blik_code yet.
            if let blikCode = paymentMethodOptions?.blikOptions?.code {
                parameters["blik_code"] = blikCode
            }
            var collectedInformation = collectedInformation.parameters
            if let savePaymentMethod {
                collectedInformation["save_payment_method"] = savePaymentMethod
            }
            if !collectedInformation.isEmpty {
                parameters["collected_information"] = collectedInformation
            }
            return parameters
        }
    }

    private let input: ConfirmationInput

    /// The data used to create a new PaymentMethod during confirmation, instead of a PaymentMethod ID.
    var paymentMethodData: STPPaymentMethodParams? {
        guard case .withPaymentMethodData(let data, _) = input else { return nil }
        return data
    }

    var inputParameters: [String: Any] {
        switch input {
        case .withoutPaymentMethod(let customerData):
            return customerData.email.map { ["customer_data": ["email": $0]] } ?? [:]
        case .withPaymentMethodID(let id, let expectedType, let details):
            var parameters = details.parameters
            parameters["payment_method"] = id
            parameters["expected_payment_method_type"] = expectedType
            return parameters
        case .withPaymentMethodData(let paymentMethodData, let details):
            var parameters = details.parameters
            var data = STPFormEncoder.dictionary(forObject: paymentMethodData)
            // Build payment_user_agent fresh for the confirming Checkout Elements component,
            // rather than inheriting identifiers from unrelated SDK components.
            data["payment_user_agent"] = confirmationSource.paymentUserAgent
            STPTelemetryClient.shared.addTelemetryFields(toParams: &data)
            parameters["payment_method_data"] = data
            parameters["expected_payment_method_type"] = paymentMethodData.rawTypeString
            return parameters
        }
    }

    /// The Checkout Elements component confirming. Used to tag
    /// `payment_method_data[payment_user_agent]` for payment/attribution purposes. Required on
    /// every factory so all Checkout confirmation paths identify their confirming element.
    let confirmationSource: CheckoutElementsController.ConfirmingElement

    /// The expected amount for validation. `nil` for setup-style Sessions.
    let expectedAmount: Int?

    /// CheckoutClient requires a return URL for confirmation.
    let returnURL: String

    /// The optional shipping details.
    let shipping: STPPaymentIntentShippingDetailsParams?

    /// The client attribution metadata for analytics.
    let clientAttributionMetadata: STPClientAttributionMetadata

    static func createWithoutPaymentMethod(
        sessionId: String,
        clientSecret: String,
        confirmationSource: CheckoutElementsController.ConfirmingElement,
        expectedAmount: Int?,
        returnURL: String,
        shipping: STPPaymentIntentShippingDetailsParams?,
        clientAttributionMetadata: STPClientAttributionMetadata,
        customerData: CustomerData
    ) -> Self {
        Self(
            sessionId: sessionId,
            clientSecret: clientSecret,
            input: .withoutPaymentMethod(customerData: customerData),
            confirmationSource: confirmationSource,
            expectedAmount: expectedAmount,
            returnURL: returnURL,
            shipping: shipping,
            clientAttributionMetadata: clientAttributionMetadata
        )
    }

    static func createWithPaymentMethodID(
        sessionId: String,
        clientSecret: String,
        paymentMethodId: String,
        confirmationSource: CheckoutElementsController.ConfirmingElement,
        expectedAmount: Int?,
        expectedPaymentMethodType: String,
        savePaymentMethod: Bool?,
        returnURL: String,
        shipping: STPPaymentIntentShippingDetailsParams?,
        paymentMethodOptions: STPConfirmPaymentMethodOptions?,
        clientAttributionMetadata: STPClientAttributionMetadata,
        collectedInformation: CollectedInformation
    ) -> Self {
        Self(
            sessionId: sessionId,
            clientSecret: clientSecret,
            input: .withPaymentMethodID(
                id: paymentMethodId,
                expectedType: expectedPaymentMethodType,
                details: .init(
                    savePaymentMethod: savePaymentMethod,
                    paymentMethodOptions: paymentMethodOptions,
                    collectedInformation: collectedInformation
                )
            ),
            confirmationSource: confirmationSource,
            expectedAmount: expectedAmount,
            returnURL: returnURL,
            shipping: shipping,
            clientAttributionMetadata: clientAttributionMetadata
        )
    }

    static func createWithPaymentMethodData(
        sessionId: String,
        clientSecret: String,
        paymentMethodData: STPPaymentMethodParams,
        confirmationSource: CheckoutElementsController.ConfirmingElement,
        expectedAmount: Int?,
        savePaymentMethod: Bool?,
        returnURL: String,
        shipping: STPPaymentIntentShippingDetailsParams?,
        paymentMethodOptions: STPConfirmPaymentMethodOptions?,
        clientAttributionMetadata: STPClientAttributionMetadata,
        collectedInformation: CollectedInformation
    ) -> Self {
        Self(
            sessionId: sessionId,
            clientSecret: clientSecret,
            input: .withPaymentMethodData(
                data: paymentMethodData,
                details: .init(
                    savePaymentMethod: savePaymentMethod,
                    paymentMethodOptions: paymentMethodOptions,
                    collectedInformation: collectedInformation
                )
            ),
            confirmationSource: confirmationSource,
            expectedAmount: expectedAmount,
            returnURL: returnURL,
            shipping: shipping,
            clientAttributionMetadata: clientAttributionMetadata
        )
    }
}

extension STPAPIClient {

    /// Initializes a CheckoutSession, fetching payment configuration data.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - adaptivePricingAllowed: Whether the integration allows adaptive pricing for this session.
    /// - Returns: Internal Checkout response for the checkout session.
    func initCheckoutSession(
        checkoutSessionId: String,
        clientSecret: String,
        adaptivePricingAllowed: Bool
    ) async throws -> CheckoutClientAPIResponse {
        var parameters = Self.checkoutClientParameters(clientSecret: clientSecret)
        parameters["adaptive_pricing"] = ["allowed": adaptivePricingAllowed]

        return try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/init",
            parameters: parameters
        )
    }

    /// Updates a CheckoutSession with the provided parameters.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - parameters: The update parameters (e.g., promotion_code)
    /// - Returns: The updated Checkout response.
    func updateCheckoutSession(
        checkoutSessionId: String,
        clientSecret: String,
        parameters: [String: Any]
    ) async throws -> CheckoutClientAPIResponse {
        // TODO(porter) promo codes: CheckoutClient update does not support promotion codes yet.
        var params = Self.checkoutClientParameters(clientSecret: clientSecret)
        params.merge(parameters) { _, value in value }
        return try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/update",
            parameters: params
        )
    }

    /// Retrieves the latest full Checkout Session.
    func retrieveCheckoutSession(
        checkoutSessionId: String,
        clientSecret: String,
        timeout: TimeInterval? = nil,
        retriesEnabled: Bool = true
    ) async throws -> CheckoutClientAPIResponse {
        return try await get(
            endpoint: "checkout_client/\(checkoutSessionId)/retrieve",
            parameters: Self.checkoutClientParameters(clientSecret: clientSecret),
            timeout: timeout,
            retriesEnabled: retriesEnabled,
            useServerErrorMessage: true
        )
    }

    /// Retrieves the small state object used to determine whether a Checkout
    /// Session transition is still in progress.
    func pollCheckoutSession(
        checkoutSessionId: String,
        clientSecret: String,
        timeout: TimeInterval
    ) async throws -> CheckoutClientPollResponse {
        return try await get(
            endpoint: "checkout_client/\(checkoutSessionId)/poll",
            parameters: ["client_secret": clientSecret],
            timeout: timeout,
            retriesEnabled: false
        )
    }

    func detachPaymentMethod(
        _ paymentMethodId: String,
        fromCheckoutSession checkoutSessionId: String,
        clientSecret: String
    ) async throws {
        var params = Self.checkoutClientParameters(clientSecret: clientSecret)
        params["payment_method_to_detach"] = paymentMethodId
        let _: CheckoutClientAPIResponse = try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/update",
            parameters: params
        )
    }

    /// Updates a saved payment method's billing details and/or card expiry on a Checkout Session.
    /// - Parameters:
    ///   - paymentMethodId: The ID of the payment method to update (e.g., "pm_xxx").
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx").
    ///   - billingDetails: Optional billing details to update (name, email, phone, address).
    ///   - expiryDetails: Optional card expiry to update (month and year).
    /// - Returns: The updated Checkout response.
    func updatePaymentMethod(
        _ paymentMethodId: String,
        inCheckoutSession checkoutSessionId: String,
        clientSecret: String,
        billingDetails: CheckoutElementsController.PaymentMethodBillingDetails? = nil,
        expiryDetails: CheckoutElementsController.PaymentMethodExpiryDetails? = nil
    ) async throws -> CheckoutClientAPIResponse {
        var params = Self.updatePaymentMethodParameters(
            paymentMethodId: paymentMethodId,
            billingDetails: billingDetails,
            expiryDetails: expiryDetails
        )
        params.merge(Self.checkoutClientParameters(clientSecret: clientSecret)) { current, _ in current }
        return try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/update",
            parameters: params
        )
    }

    static func updatePaymentMethodParameters(
        paymentMethodId: String,
        billingDetails: CheckoutElementsController.PaymentMethodBillingDetails?,
        expiryDetails: CheckoutElementsController.PaymentMethodExpiryDetails?
    ) -> [String: Any] {
        var params: [String: Any] = [
            "payment_method_to_update[payment_method_id]": paymentMethodId,
        ]
        if let billing = billingDetails {
            let billingPrefix = "payment_method_to_update[billing_details]"
            if let name = billing.name { params["\(billingPrefix)[name]"] = name }
            if let email = billing.email { params["\(billingPrefix)[email]"] = email }
            if let phone = billing.phone { params["\(billingPrefix)[phone]"] = phone }
            if let address = billing.address {
                let addressPrefix = "\(billingPrefix)[address]"
                if let line1 = address.line1 { params["\(addressPrefix)[line1]"] = line1 }
                if let line2 = address.line2 { params["\(addressPrefix)[line2]"] = line2 }
                if let city = address.city { params["\(addressPrefix)[city]"] = city }
                if let state = address.state { params["\(addressPrefix)[state]"] = state }
                if let postalCode = address.postalCode { params["\(addressPrefix)[postal_code]"] = postalCode }
                if let country = address.country { params["\(addressPrefix)[country]"] = country }
            }
        }
        if let expiry = expiryDetails {
            let expiryPrefix = "payment_method_to_update[expiry_details]"
            params["\(expiryPrefix)[exp_month]"] = expiry.expMonth
            params["\(expiryPrefix)[exp_year]"] = expiry.expYear
        }
        return params
    }

    /// Confirms a Checkout Session with the provided request parameters.
    /// - Returns: The full confirmed session with expanded intents.
    func confirmCheckoutSession(
        with requestParameters: CheckoutSessionConfirmationRequestParameters
    ) async throws -> CheckoutClientAPIResponse {
        var parameters = Self.checkoutClientParameters(clientSecret: requestParameters.clientSecret)
        parameters.removeValue(forKey: "timezone")

        parameters.merge(requestParameters.inputParameters) { _, value in value }

        if let expectedAmount = requestParameters.expectedAmount {
            parameters["expected_amount"] = expectedAmount
        }

        parameters["return_url"] = requestParameters.returnURL

        if let shipping = requestParameters.shipping {
            parameters["shipping"] = STPFormEncoder.dictionary(forObject: shipping)
        }

        parameters["client_attribution_metadata"] = try requestParameters.clientAttributionMetadata.encodeJSONDictionary()
        // STPPaymentHandler requires the Intent's PaymentMethod to be expanded to handle next actions.
        parameters["expand"] = [
            "payment_response.payment_intent.payment_method",
            "payment_response.setup_intent.payment_method",
        ]

        return try await post(
            endpoint: "checkout_client/\(requestParameters.sessionId)/confirm",
            parameters: parameters
        )
    }

    private func post(
        endpoint: String,
        parameters: [String: Any]
    ) async throws -> CheckoutClientAPIResponse {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                post(resource: endpoint, parameters: parameters) { result in
                    continuation.resume(with: result)
                }
            }
        } catch StripeError.apiError(let apiError) {
            throw checkoutSessionError(from: apiError)
        } catch {
            if error is DecodingError {
                reportUnexpectedCheckoutClientParsingError(error, apiClient: self)
            }
            throw error
        }
    }

    private static func checkoutClientParameters(clientSecret: String) -> [String: Any] {
        var parameters: [String: Any] = [
            "client_secret": clientSecret,
            "locale": Locale.current.toLanguageTag(),
            "timezone": TimeZone.current.identifier,
        ]
        if let sessionId = AnalyticsHelper.shared.sessionID {
            parameters["mobile_session_id"] = sessionId
        }
        if let appId = Bundle.main.bundleIdentifier {
            parameters["mobile_app_id"] = appId
        }
        return parameters
    }

    private func get<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        timeout: TimeInterval? = nil,
        retriesEnabled: Bool = true,
        useServerErrorMessage: Bool = false
    ) async throws -> T {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                get(
                    resource: endpoint,
                    parameters: parameters,
                    timeout: timeout,
                    retriesEnabled: retriesEnabled
                ) { (result: Result<T, Error>) in
                    continuation.resume(with: result)
                }
            }
        } catch StripeError.apiError(let apiError) where useServerErrorMessage {
            throw checkoutSessionError(from: apiError)
        } catch {
            if error is DecodingError {
                reportUnexpectedCheckoutClientParsingError(error, apiClient: self)
            }
            throw error
        }
    }

    private func checkoutSessionError(from apiError: StripeAPIError) -> StripeError {
        // During private preview, Checkout cannot distinguish buyer-actionable API errors.
        // Let the shared formatter expose the server's message, or a generic fallback, for every error type.
        var apiError = apiError
        apiError.useServerErrorMessage = true
        // Keep the original error so analytics and other internal consumers retain all API data.
        return .apiError(apiError)
    }
}

extension STPAPIClient: CheckoutSessionPollingAPIClient {}

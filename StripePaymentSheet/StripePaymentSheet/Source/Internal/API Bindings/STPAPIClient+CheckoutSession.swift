//
//  STPAPIClient+CheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/15/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The parameters sent to the Checkout Session `/confirm` endpoint.
struct CheckoutSessionConfirmationRequestParameters {
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

    private enum PaymentMethod {
        case id(String)
        case data(STPPaymentMethodParams)
    }

    private let paymentMethod: PaymentMethod?

    /// The ID of the PaymentMethod to use for confirmation.
    var paymentMethodId: String? {
        guard case .id(let id) = paymentMethod else { return nil }
        return id
    }

    /// The data used to create a new PaymentMethod during confirmation, instead of a PaymentMethod ID.
    var paymentMethodData: STPPaymentMethodParams? {
        guard case .data(let data) = paymentMethod else { return nil }
        return data
    }

    /// The expected amount for validation. `nil` for setup-style Sessions.
    let expectedAmount: Int?

    /// The expected PaymentMethod type (e.g., `card`).
    let expectedPaymentMethodType: String?

    /// The optional buyer save-checkbox choice, sent as `collected_information[save_payment_method]`.
    /// Omit it when no checkbox is shown; the server applies merchant-configured saving separately.
    let savePaymentMethod: Bool?

    /// CheckoutClient requires a return URL for confirmation.
    let returnURL: String?

    /// The optional shipping details.
    let shipping: STPPaymentIntentShippingDetailsParams?

    /// The optional PaymentMethod options. The BLIK code is extracted and passed as the
    /// top-level `blik_code` parameter.
    let paymentMethodOptions: STPConfirmPaymentMethodOptions?

    /// The optional client attribution metadata for analytics.
    let clientAttributionMetadata: STPClientAttributionMetadata?

    /// The optional hCaptcha challenge response token.
    var passiveCaptchaToken: String?

    /// Customer information collected independently of PaymentMethod billing details.
    let collectedInformation: CollectedInformation?

    /// Legacy customer information required today when confirming without a PaymentMethod.
    /// TODO: Remove this once the server can construct no-PaymentMethod `CustomerInfo` entirely
    /// from fixed and independently collected information.
    let customerData: [String: Any]?

    static func createWithoutPaymentMethod(
        sessionId: String,
        expectedAmount: Int?,
        returnURL: String? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil,
        customerData: [String: Any]? = nil
    ) -> Self {
        Self(
            sessionId: sessionId,
            paymentMethod: nil,
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: nil,
            savePaymentMethod: nil,
            returnURL: returnURL,
            shipping: nil,
            paymentMethodOptions: nil,
            clientAttributionMetadata: clientAttributionMetadata,
            passiveCaptchaToken: nil,
            collectedInformation: nil,
            customerData: customerData
        )
    }

    static func createWithPaymentMethodID(
        sessionId: String,
        paymentMethodId: String,
        expectedAmount: Int?,
        expectedPaymentMethodType: String,
        savePaymentMethod: Bool? = nil,
        returnURL: String? = nil,
        shipping: STPPaymentIntentShippingDetailsParams? = nil,
        paymentMethodOptions: STPConfirmPaymentMethodOptions? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil,
        passiveCaptchaToken: String? = nil,
        collectedInformation: CollectedInformation? = nil
    ) -> Self {
        Self(
            sessionId: sessionId,
            paymentMethod: .id(paymentMethodId),
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: expectedPaymentMethodType,
            savePaymentMethod: savePaymentMethod,
            returnURL: returnURL,
            shipping: shipping,
            paymentMethodOptions: paymentMethodOptions,
            clientAttributionMetadata: clientAttributionMetadata,
            passiveCaptchaToken: passiveCaptchaToken,
            collectedInformation: collectedInformation,
            customerData: nil
        )
    }

    static func createWithPaymentMethodData(
        sessionId: String,
        paymentMethodData: STPPaymentMethodParams,
        expectedAmount: Int?,
        savePaymentMethod: Bool? = nil,
        returnURL: String? = nil,
        shipping: STPPaymentIntentShippingDetailsParams? = nil,
        paymentMethodOptions: STPConfirmPaymentMethodOptions? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil,
        collectedInformation: CollectedInformation? = nil
    ) -> Self {
        Self(
            sessionId: sessionId,
            paymentMethod: .data(paymentMethodData),
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: paymentMethodData.rawTypeString,
            savePaymentMethod: savePaymentMethod,
            returnURL: returnURL,
            shipping: shipping,
            paymentMethodOptions: paymentMethodOptions,
            clientAttributionMetadata: clientAttributionMetadata,
            passiveCaptchaToken: nil,
            collectedInformation: collectedInformation,
            customerData: nil
        )
    }
}

extension STPAPIClient {

    /// Initializes a CheckoutSession, fetching payment configuration data.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - adaptivePricingAllowed: Whether the integration allows adaptive pricing for this session.
    /// - Returns: Internal Payment Pages API response for the checkout session.
    func initCheckoutSession(
        checkoutSessionId: String,
        adaptivePricingAllowed: Bool
    ) async throws -> PaymentPagesAPIResponse {
        var parameters = Self.checkoutClientParameters()
        parameters["adaptive_pricing"] = ["allowed": adaptivePricingAllowed]

        let checkoutClient: CheckoutClientAPIResponse = try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/init",
            parameters: parameters
        )

        return try checkoutClient.paymentPagesResponse()
    }

    /// Updates a CheckoutSession with the provided parameters.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - parameters: The update parameters (e.g., promotion_code)
    /// - Returns: The updated Payment Pages API response.
    func updateCheckoutSession(
        checkoutSessionId: String,
        parameters: [String: Any]
    ) async throws -> PaymentPagesAPIResponse {
        // TODO: CheckoutClient /update currently rejects promotion_code.
        var params = Self.checkoutClientParameters()
        for (key, value) in parameters {
            if key == "updated_currency" {
                params["adaptive_pricing[currency]"] = value
            } else {
                params[key] = value
            }
        }
        let checkoutClient: CheckoutClientAPIResponse = try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/update",
            parameters: params
        )
        return try checkoutClient.paymentPagesResponse()
    }

    /// Retrieves the latest full Checkout Session.
    func retrieveCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagesAPIResponse {
        let checkoutClient: CheckoutClientAPIResponse = try await get(
            endpoint: "checkout_client/\(checkoutSessionId)/retrieve",
            parameters: Self.checkoutClientParameters()
        )
        return try await checkoutClientSessionResponse(checkoutClient)
    }

    /// Retrieves the small state object used to determine whether a Checkout
    /// Session transition is still in progress.
    func pollCheckoutSession(
        checkoutSessionId: String,
        timeout: TimeInterval
    ) async throws -> PaymentPagePollResponse {
        return try await get(
            endpoint: "payment_pages/\(checkoutSessionId)/poll",
            parameters: [:],
            timeout: timeout,
            retriesEnabled: false
        )
    }

    func detachPaymentMethod(
        _ paymentMethodId: String,
        fromCheckoutSession checkoutSessionId: String
    ) async throws {
        var params = Self.checkoutClientParameters()
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
    /// - Returns: The updated Payment Pages API response.
    func updatePaymentMethod(
        _ paymentMethodId: String,
        inCheckoutSession checkoutSessionId: String,
        billingDetails: CheckoutController.PaymentMethodBillingDetails? = nil,
        expiryDetails: CheckoutController.PaymentMethodExpiryDetails? = nil
    ) async throws -> PaymentPagesAPIResponse {
        var params = Self.updatePaymentMethodParameters(
            paymentMethodId: paymentMethodId,
            billingDetails: billingDetails,
            expiryDetails: expiryDetails
        )
        params.merge(Self.checkoutClientParameters()) { current, _ in current }
        let checkoutClient: CheckoutClientAPIResponse = try await post(
            endpoint: "checkout_client/\(checkoutSessionId)/update",
            parameters: params
        )
        return try checkoutClient.paymentPagesResponse()
    }

    static func updatePaymentMethodParameters(
        paymentMethodId: String,
        billingDetails: CheckoutController.PaymentMethodBillingDetails?,
        expiryDetails: CheckoutController.PaymentMethodExpiryDetails?
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
    ) async throws -> PaymentPagesAPIResponse {
        guard let returnURL = requestParameters.returnURL else {
            throw CheckoutError.unknown(debugDescription: "CheckoutClient confirmation requires a return URL.")
        }
        var parameters = Self.checkoutClientParameters()
        parameters.removeValue(forKey: "timezone")

        if let paymentMethodId = requestParameters.paymentMethodId {
            parameters["payment_method"] = paymentMethodId
        }

        if let paymentMethodData = requestParameters.paymentMethodData {
            if paymentMethodData.type == .vipps {
                // TODO: CheckoutClient rejects inline Vipps data, even with vipps_preview=v1.
                // Use its supported PaymentMethod ID path until the backend accepts inline data.
                let paymentMethod = try await createPaymentMethod(with: paymentMethodData)
                parameters["payment_method"] = paymentMethod.stripeId
            } else {
                var data = STPFormEncoder.dictionary(forObject: paymentMethodData)
                data = Self.paramsAddingPaymentUserAgent(data)
                STPTelemetryClient.shared.addTelemetryFields(toParams: &data)
                parameters["payment_method_data"] = data
            }
        }

        if let expectedPaymentMethodType = requestParameters.expectedPaymentMethodType {
            parameters["expected_payment_method_type"] = expectedPaymentMethodType
        }

        if let expectedAmount = requestParameters.expectedAmount {
            parameters["expected_amount"] = expectedAmount
        }

        parameters["return_url"] = returnURL

        if let shipping = requestParameters.shipping {
            parameters["shipping"] = STPFormEncoder.dictionary(forObject: shipping)
        }

        // TODO: CheckoutClient /confirm does not support BLIK's blik_code yet.
        if let blikCode = requestParameters.paymentMethodOptions?.blikOptions?.code {
            parameters["blik_code"] = blikCode
        }

        if let clientAttributionMetadata = requestParameters.clientAttributionMetadata {
            parameters["client_attribution_metadata"] = try clientAttributionMetadata.encodeJSONDictionary()
        }

        if let passiveCaptchaToken = requestParameters.passiveCaptchaToken {
            parameters["passive_captcha_token"] = passiveCaptchaToken
        }

        if let collectedInformation = requestParameters.collectedInformation?.parameters,
           !collectedInformation.isEmpty {
            parameters["collected_information"] = collectedInformation
        }

        if let savePaymentMethod = requestParameters.savePaymentMethod {
            var collectedInformation = parameters["collected_information"] as? [String: Any] ?? [:]
            collectedInformation["save_payment_method"] = savePaymentMethod
            parameters["collected_information"] = collectedInformation
        }

        if let customerData = requestParameters.customerData {
            parameters["customer_data"] = customerData
        }

        let checkoutClient: CheckoutClientAPIResponse = try await post(
            endpoint: "checkout_client/\(requestParameters.sessionId)/confirm",
            parameters: parameters
        )
        return try await checkoutClientSessionResponse(checkoutClient)
    }

    /// CheckoutClient returns Intent references. Retrieve the Intent to preserve the full session used by confirmation.
    private func checkoutClientSessionResponse(
        _ checkoutClient: CheckoutClientAPIResponse
    ) async throws -> PaymentPagesAPIResponse {
        let paymentResponse = checkoutClient.fields["payment_response"] as? [String: Any]
        let paymentIntent: STPPaymentIntent?
        if let reference = paymentResponse?["payment_intent"] as? [String: Any] {
            guard let clientSecret = reference["client_secret"] as? String else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "CheckoutClient PaymentIntent is missing its client secret")
                )
            }
            paymentIntent = try await retrievePaymentIntent(clientSecret: clientSecret, expand: ["payment_method"])
        } else {
            paymentIntent = nil
        }
        let setupIntent: STPSetupIntent?
        if let reference = paymentResponse?["setup_intent"] as? [String: Any] {
            guard let clientSecret = reference["client_secret"] as? String else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "CheckoutClient SetupIntent is missing its client secret")
                )
            }
            setupIntent = try await retrieveSetupIntent(clientSecret: clientSecret, expand: ["payment_method"])
        } else {
            setupIntent = nil
        }
        return try checkoutClient.paymentPagesResponse(
            paymentIntent: paymentIntent,
            setupIntent: setupIntent
        )
    }

    private func post<Response: Decodable>(
        endpoint: String,
        parameters: [String: Any]
    ) async throws -> Response {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                post(resource: endpoint, parameters: parameters) { (result: Result<Response, Error>) in
                    continuation.resume(with: result)
                }
            }
        } catch {
            if error is DecodingError {
                reportUnexpectedPaymentPagesParsingError(error, apiClient: self)
            }
            throw error
        }
    }

    private static func checkoutClientParameters() -> [String: Any] {
        var parameters: [String: Any] = [
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
        retriesEnabled: Bool = true
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
        } catch {
            if error is DecodingError {
                reportUnexpectedPaymentPagesParsingError(error, apiClient: self)
            }
            throw error
        }
    }
}

extension STPAPIClient: CheckoutSessionPollingAPIClient {}

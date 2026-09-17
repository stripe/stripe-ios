//
//  STPTestingAPIClient+Swift.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 6/25/23.
//

import Foundation
@_exported import StripePaymentsObjcTestUtils

extension STPTestingAPIClient {
    static let STPTestingBackendURL = "https://stp-mobile-ci-test-backend-e1b3.stripedemos.com/"
    static let STPTestingPlaygroundBackendURL = "https://stp-mobile-playground-backend-v7.stripedemos.com/"
    static let checkoutMobileElementsAPISettings = "2026-08-26.preview"
    public static var shared: STPTestingAPIClient {
        return .shared()
    }

    func fetchPaymentIntent(
        types: [String],
        currency: String = "eur",
        amount: Int? = nil,
        merchantCountry: String? = "us",
        paymentMethodID: String? = nil,
        shouldSavePM: Bool = false,
        customerID: String? = nil,
        confirm: Bool = false,
        paymentMethodOptions: [String: Any]? = nil,
        otherParams: [String: Any] = [:],
        completion: @escaping (Result<(String), Error>) -> Void
    ) {
        var params = [String: Any]()
        params["amount"] = amount ?? 5050
        params["currency"] = currency
        params["payment_method_types"] = types
        params["confirm"] = confirm
        if let paymentMethodID {
            params["payment_method"] = paymentMethodID
        }
        if let paymentMethodOptions {
            params["payment_method_options"] = paymentMethodOptions
        }
        if shouldSavePM {
            var existingPaymentMethodOptions: [String: Any] = params["payment_method_options"] as? [String: Any] ?? [:]
            var cardPaymentMethodOptions: [String: Any] = existingPaymentMethodOptions["card"] as? [String: Any] ?? [:]
            cardPaymentMethodOptions["setup_future_usage"] = "off_session"
            existingPaymentMethodOptions["card"] = cardPaymentMethodOptions
            params["payment_method_options"] = existingPaymentMethodOptions
        }
        if let customerID {
            params["customer"] = customerID
        }
        params.merge(otherParams) { _, b in b }

        createPaymentIntent(
            withParams: params,
            account: merchantCountry,
            apiVersion: types.contains("vipps") ? "\(STPAPIClient.apiVersion); vipps_preview=v1" : nil
        ) { clientSecret, error in
            guard let clientSecret = clientSecret,
                  error == nil
            else {
                completion(.failure(error!))
                return
            }

            completion(.success(clientSecret))
        }
    }

    func fetchPaymentIntent(
        types: [String],
        currency: String = "eur",
        amount: Int? = nil,
        merchantCountry: String? = "us",
        paymentMethodID: String? = nil,
        shouldSavePM: Bool = false,
        customerID: String? = nil,
        confirm: Bool = false,
        paymentMethodOptions: [String: Any]? = nil,
        otherParams: [String: Any] = [:]
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            fetchPaymentIntent(
                types: types,
                currency: currency,
                amount: amount,
                merchantCountry: merchantCountry,
                paymentMethodID: paymentMethodID,
                shouldSavePM: shouldSavePM,
                customerID: customerID,
                confirm: confirm,
                paymentMethodOptions: paymentMethodOptions,
                otherParams: otherParams
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchSetupIntent(
        types: [String],
        merchantCountry: String? = "us",
        paymentMethodID: String? = nil,
        customerID: String? = nil,
        confirm: Bool = false,
        otherParams: [String: Any] = [:]
    ) async throws -> String {
        var params = [String: Any]()
        params["payment_method_types"] = types
        params["confirm"] = confirm
        if let paymentMethodID {
            params["payment_method"] = paymentMethodID
        }
        if let customerID {
            params["customer"] = customerID
        }
        params.merge(otherParams) { _, b in b }
        return try await withCheckedThrowingContinuation { continuation in
            createSetupIntent(withParams: params,
                              account: merchantCountry) { clientSecret, error in
                guard let clientSecret = clientSecret,
                      error == nil
                else {
                    continuation.resume(throwing: error!)
                    return
                }
                continuation.resume(returning: clientSecret)
            }
        }
    }

    // MARK: - /create_ephemeral_key

    struct CreateEphemeralKeyResponse: Decodable {
        let ephemeralKeySecret: String
        let customer: String
    }

    struct CreateCustomerSessionResponse: Decodable {
        let customerSessionClientSecret: String
        let customer: String
    }

    func fetchCustomerAndEphemeralKey(
        customerID: String? = nil,
        merchantCountry: String? = "us"
    ) async throws -> CreateEphemeralKeyResponse {
        let params = [
            "customer_id": customerID,
            "account": merchantCountry,
        ]
        return try await makeRequest(endpoint: "create_ephemeral_key", params: params)
    }

    func fetchCustomerAndCustomerSessionClientSecret(
        customerID: String? = nil,
        merchantCountry: String? = "us",
        paymentMethodSave: Bool = true,
        paymentMethodRemove: Bool = true,
        paymentMethodSetAsDefault: Bool = false
    ) async throws -> CreateCustomerSessionResponse {
        let params: [String: Any?] = [
            "component_name": "mobile_payment_element",
            "customer_id": customerID,
            "account": merchantCountry,
            "features": [
                "payment_method_save": paymentMethodSave ? "enabled" : "disabled",
                "payment_method_remove": paymentMethodRemove ? "enabled" : "disabled",
                "payment_method_set_as_default": paymentMethodSetAsDefault ? "enabled" : "disabled",
            ],
        ]
        return try await makeRequest(endpoint: "create_customer_session_cs", params: params)
    }
    func fetchCustomerAndCustomerSessionClientSecretCustomerSheet(
        customerID: String? = nil,
        merchantCountry: String? = "us",
        paymentMethodSave: Bool = true,
        paymentMethodRemove: Bool = true,
        paymentMethodSetAsDefault: Bool = false
    ) async throws -> CreateCustomerSessionResponse {
        let params: [String: Any?] = [
            "component_name": "customer_sheet",
            "customer_id": customerID,
            "account": merchantCountry,
            "features": [
                "payment_method_remove": paymentMethodRemove ? "enabled" : "disabled",
                "payment_method_sync_default": paymentMethodSetAsDefault ? "enabled" : "disabled",
            ],
        ]
        return try await makeRequest(endpoint: "create_customer_session_cs", params: params)
    }
    // MARK: - /create_checkout_session

    struct CreateCheckoutSessionResponse: Decodable {
        let id: String
        let clientSecret: String
        let publishableKey: String
    }

    // This helper is used by tests, which Periphery excludes from its scan.
    // periphery:ignore
    func createCheckoutCustomer(
        email: String,
        merchantCountry: String? = "us"
    ) async throws -> String {
        let response: PlaygroundCustomerResponse = try await makePlaygroundRequest(
            endpoint: "create_customer",
            method: "POST",
            params: [
                "merchant": playgroundMerchant(for: merchantCountry),
                "request_params": ["email": email],
            ]
        )
        return response.id
    }

    // This helper is used by tests, which Periphery excludes from its scan.
    // periphery:ignore
    func attachCheckoutPaymentMethod(
        _ paymentMethodID: String,
        to customerID: String,
        merchantCountry: String? = "us"
    ) async throws {
        let _: PlaygroundPaymentMethodResponse = try await makePlaygroundRequest(
            endpoint: "attach_payment_method",
            method: "POST",
            params: [
                "merchant": playgroundMerchant(for: merchantCountry),
                "payment_method_id": paymentMethodID,
                "request_params": ["customer": customerID],
            ]
        )
    }

    // This helper is used by tests, which Periphery excludes from its scan.
    // periphery:ignore
    /// Creates a Mobile Elements Checkout Session using the playground's raw API proxy.
    func createCheckoutSession(
        types: [String] = ["card"],
        currency: String = "usd",
        amount: Int? = nil,
        merchantCountry: String? = "us",
        customerID: String? = nil,
        collectBillingAddress: Bool = false,
        automaticTax: Bool = false,
        customerEmailLocation: String? = nil,
        returnURL: String? = nil,
        allowPromotionCodes: Bool = false,
        allowedShippingCountries: [String]? = nil,
        customerEmail: String? = nil
    ) async throws -> CreateCheckoutSessionResponse {
        let playgroundMerchant = playgroundMerchant(for: merchantCountry)
        var sessionParameters: [String: Any] = [
            "ui_mode": "mobile_elements",
            "currency": currency,
            "payment_method_types": types,
            "items": [
                [
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "price_data": [
                                    "currency": currency,
                                    "unit_amount": amount ?? 2000,
                                    "product_data": [
                                        "name": "Test",
                                        "tax_code": "txcd_99999999",
                                    ],
                                    "tax_behavior": "exclusive",
                                ],
                                "quantity": 1,
                            ],
                        ],
                    ],
                ],
            ],
        ]
        if collectBillingAddress {
            sessionParameters["billing_address_collection"] = "required"
        }
        if automaticTax {
            sessionParameters["automatic_tax"] = ["enabled": true]
        }
        if allowPromotionCodes {
            sessionParameters["allow_promotion_codes"] = true
        }
        if let allowedShippingCountries {
            sessionParameters["shipping_address_collection"] = [
                "allowed_countries": allowedShippingCountries,
            ]
        }
        if let customerEmail {
            sessionParameters["customer_email"] = customerEmail
        }
        if let customerEmailLocation {
            sessionParameters["customer_email"] = "test+location_\(customerEmailLocation)@example.com"
        }
        if let customerID {
            sessionParameters["customer"] = customerID
        }

        let checkoutSession: PlaygroundCheckoutSessionResponse = try await makePlaygroundRequest(
            endpoint: "create_checkout_session",
            method: "POST",
            params: [
                "merchant": playgroundMerchant,
                // Checkout retains the creation API version for the underlying PaymentIntent.
                "stripe_version": types.contains("vipps")
                    ? "\(Self.checkoutMobileElementsAPISettings); vipps_preview=v1"
                    : Self.checkoutMobileElementsAPISettings,
                "request_params": sessionParameters,
            ]
        )
        let publishableKeyResponse: PlaygroundPublishableKeyResponse = try await makePlaygroundRequest(
            endpoint: "publishable_key?merchant=\(playgroundMerchant)",
            method: "GET"
        )
        return CreateCheckoutSessionResponse(
            id: checkoutSession.id,
            clientSecret: checkoutSession.clientSecret,
            publishableKey: publishableKeyResponse.publishableKey
        )
    }

    // This helper is used by tests, which Periphery excludes from its scan.
    // periphery:ignore
    /// Creates legacy Checkout Sessions on the CI backend for tests that have not migrated yet.
    func createLegacyCheckoutSession(
        types: [String] = ["card"],
        currency: String = "usd",
        amount: Int? = nil,
        merchantCountry: String? = "us",
        customerID: String? = nil,
        collectBillingAddress: Bool = false,
        automaticTax: Bool = false,
        customerEmailLocation: String? = nil,
        returnURL: String? = nil,
        useOneTimePrice: Bool = true,
        additionalParameters: [String: Any] = [:]
    ) async throws -> CreateCheckoutSessionResponse {
        var mergedParameters: [String: Any] = [:]
        if collectBillingAddress {
            mergedParameters["billing_address_collection"] = "required"
        }
        if automaticTax {
            mergedParameters["automatic_tax"] = ["enabled": true]
        }
        if let customerEmailLocation {
            mergedParameters["customer_email"] = "test+location_\(customerEmailLocation)@example.com"
        }
        mergedParameters.merge(additionalParameters) { _, override in override }

        let params: [String: Any?] = [
            "account": merchantCountry,
            "payment_method_types": types,
            "currency": currency,
            "amount": amount,
            "customer": customerID,
            "return_url": returnURL,
            "use_one_time_price": useOneTimePrice ? true : nil,
            "additional_parameters": mergedParameters.isEmpty ? nil : mergedParameters,
        ]
        return try await makeRequest(endpoint: "create_checkout_session_unified", params: params)
    }

    // MARK: - Helpers

    fileprivate func makeRequest<ResponseType: Decodable>(
        endpoint: String,
        params: [String: Any?]
    ) async throws -> ResponseType {
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string: STPTestingAPIClient.STPTestingBackendURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: params)
        let (data, _) = try await session.data(for: request)
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try jsonDecoder.decode(ResponseType.self, from: data)
        } catch {
            let rawDataString = String(data: data, encoding: .utf8)
            print("Error decoding to \(ResponseType.self). Raw data: \(rawDataString ?? "nil")")
            throw error
        }
    }

    private struct PlaygroundCheckoutSessionResponse: Decodable {
        let id: String
        let clientSecret: String
    }

    // This response is used by a test helper, which Periphery excludes from its scan.
    // periphery:ignore
    private struct PlaygroundCustomerResponse: Decodable {
        let id: String
    }

    private struct PlaygroundPublishableKeyResponse: Decodable {
        let publishableKey: String
    }

    // This response is used by a test helper, which Periphery excludes from its scan.
    // periphery:ignore
    private struct PlaygroundPaymentMethodResponse: Decodable {
        let id: String
    }

    private struct PlaygroundErrorResponse: Decodable {
        let error: String
        let requestID: String?
    }

    private struct TestingBackendError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private func playgroundMerchant(for merchantCountry: String?) -> String {
        let playgroundMerchant = merchantCountry ?? "us"
        // The CI backend uses "mex" for Mexico, but the playground has its own mapping and expects "MX".
        if playgroundMerchant.lowercased() == "mex" {
            return "MX"
        }
        return playgroundMerchant.count == 2 ? playgroundMerchant.uppercased() : playgroundMerchant
    }

    private func makePlaygroundRequest<ResponseType: Decodable>(
        endpoint: String,
        method: String,
        params: [String: Any]? = nil
    ) async throws -> ResponseType {
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string: Self.STPTestingPlaygroundBackendURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let params {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        }

        let (data, response) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let backendError = try? decoder.decode(PlaygroundErrorResponse.self, from: data)
            let requestID = backendError?.requestID.map { " (request_id: \($0))" } ?? ""
            throw TestingBackendError(
                message: (backendError?.error ?? "Playground backend request failed") + requestID
            )
        }
        return try decoder.decode(ResponseType.self, from: data)
    }
}

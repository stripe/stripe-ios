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
        if shouldSavePM {
            params["payment_method_options"] = ["card": ["setup_future_usage": "off_session"]]
        }
        if let customerID {
            params["customer"] = customerID
        }
        params.merge(otherParams) { _, b in b }

        createPaymentIntent(
            withParams: params,
            account: merchantCountry
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
        merchantCountry: String? = "us"
    ) async throws -> CreateCustomerSessionResponse {
        let params = [
            "component_name": "mobile_payment_element",
            "customer_id": customerID,
            "account": merchantCountry,
        ]
        return try await makeRequest(endpoint: "create_customer_session_cs", params: params)
    }

    // MARK: - Helpers

    fileprivate func makeRequest<ResponseType: Decodable>(
        endpoint: String,
        params: [String: String?]
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
        return try jsonDecoder.decode(ResponseType.self, from: data)
    }
}

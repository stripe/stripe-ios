//
//  LinkControllerDemoBackendClient.swift
//  PaymentSheet Example
//

import Foundation

enum LinkControllerDemoBackendClient {

    static let baseURL = URL(string: "https://link-controller-preview-demo.stripedemos.com")!

    // MARK: - Config

    struct Config: Decodable {
        let publishableKey: String
    }

    static func fetchConfig() async throws -> Config {
        try await get("config")
    }

    // MARK: - Customers

    struct CustomerResponse: Decodable {
        let customerId: String
    }

    static func fetchOrCreateCustomer(email: String) async throws -> String {
        let response: CustomerResponse = try await post("customers", body: ["email": email])
        return response.customerId
    }

    // MARK: - Payment Methods

    struct PaymentMethodInfo: Decodable, Identifiable {
        let id: String
        let type: String

        struct Card: Decodable {
            let brand: String
            let last4: String
        }
        struct UsBankAccount: Decodable {
            let bankName: String
            let last4: String
        }

        let card: Card?
        let usBankAccount: UsBankAccount?
        let metadata: [String: String]?

        var mandateId: String? { metadata?["mandate_id"] }

        var displayLabel: String {
            if let card { return "\(card.brand.capitalized) •••• \(card.last4)" }
            if let bank = usBankAccount { return "\(bank.bankName.capitalized) •••• \(bank.last4)" }
            return type
        }
    }

    struct PaymentMethodsResponse: Decodable {
        let paymentMethods: [PaymentMethodInfo]
    }

    static func attachPaymentMethod(_ pmId: String, toCustomer customerId: String) async throws {
        let _: EmptyResponse = try await post(
            "payment-methods/attach",
            body: ["paymentMethodId": pmId, "customerId": customerId]
        )
    }

    static func listPaymentMethods(for customerId: String) async throws -> [PaymentMethodInfo] {
        let response: PaymentMethodsResponse = try await get(
            "payment-methods",
            query: ["customerId": customerId]
        )
        return response.paymentMethods
    }

    static func detachPaymentMethod(_ pmId: String) async throws {
        let _: EmptyResponse = try await delete("payment-methods/\(pmId)")
    }

    // MARK: - Charging

    struct PaymentIntentResponse: Decodable {
        let status: String
        let paymentIntentId: String
        let clientSecret: String?
        let code: String?
    }

    static func charge(
        paymentMethodId: String,
        customerId: String,
        amount: Int = 1099,
        currency: String = "usd"
    ) async throws -> PaymentIntentResponse {
        let body: [String: Any] = [
            "paymentMethodId": paymentMethodId,
            "customerId": customerId,
            "amount": amount,
            "currency": currency,
        ]
        do {
            return try await post("payment-intents", body: body)
        } catch let err as HTTPError where err.statusCode == 402 {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(PaymentIntentResponse.self, from: err.data)
        }
    }

    static func fetchPaymentIntentStatus(piId: String) async throws -> PaymentIntentResponse {
        try await get("payment-intents/\(piId)")
    }

    // MARK: - HTTP helpers

    private struct EmptyResponse: Decodable {}
    private struct BackendError: Decodable { let error: String }

    struct HTTPError: Error, LocalizedError {
        let statusCode: Int
        let data: Data
        var errorDescription: String? {
            let err = try? JSONDecoder().decode(BackendError.self, from: data)
            return err?.error ?? "HTTP \(statusCode)"
        }
    }

    private static func get<T: Decodable>(
        _ path: String,
        query: [String: String] = [:]
    ) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: true
        )!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    private static func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path), cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    private static func delete<T: Decodable>(_ path: String) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path), cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "DELETE"
        return try await perform(request)
    }

    private static func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as! HTTPURLResponse
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError(statusCode: http.statusCode, data: data)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

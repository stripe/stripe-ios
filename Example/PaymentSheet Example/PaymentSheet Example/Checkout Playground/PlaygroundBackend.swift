//
//  PlaygroundBackend.swift
//  PaymentSheet Example
//

import Foundation

struct PlaygroundBackend {
    // MARK: - Types

    private enum Endpoint: String {
        case createCheckoutSession = "create_checkout_session"
        case createCustomer = "create_customer"
        case attachPaymentMethod = "attach_payment_method"
    }

    // MARK: - Configuration

    let baseURL: URL
    var merchant = "us_tax"
    var urlSession = URLSession.shared

    // MARK: - Endpoints

    func fetchPublishableKey() async throws -> String {
        let url = baseURL.appendingPathComponent("publishable_key")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "merchant", value: merchant)]
        let json = try await send(URLRequest(url: components.url!))
        return json["publishable_key"] as! String
    }

    func createCustomer(requestParams: [String: Any]) async throws -> String {
        let customer = try await post(.createCustomer, requestParams: requestParams)
        return customer["id"] as! String
    }

    func attachPaymentMethod(_ paymentMethodID: String, to customerID: String) async throws {
        _ = try await post(
            .attachPaymentMethod,
            requestParams: ["customer": customerID],
            additionalFields: ["payment_method_id": paymentMethodID]
        )
    }

    func createCheckoutSession(
        stripeVersion: String,
        requestParams: [String: Any]
    ) async throws -> String {
        let session = try await post(
            .createCheckoutSession,
            requestParams: requestParams,
            stripeVersion: stripeVersion
        )
        return session["client_secret"] as! String
    }

    // MARK: - Networking

    private func post(
        _ endpoint: Endpoint,
        requestParams: [String: Any],
        stripeVersion: String? = nil,
        additionalFields: [String: Any] = [:]
    ) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var body: [String: Any] = [
            "merchant": merchant,
            "request_params": requestParams,
        ]
        if let stripeVersion {
            body["stripe_version"] = stripeVersion
        }
        body.merge(additionalFields) { _, newValue in newValue }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: body)
        return try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        guard (200..<300).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "(not utf8)"
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = json?["error"] as? String ?? "Backend request failed: \(responseBody)"
            throw Error(message)
        }
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    // MARK: - Errors

    struct Error: LocalizedError {
        let message: String

        init(_ message: String) {
            self.message = message
        }

        var errorDescription: String? { message }
    }
}

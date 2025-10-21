//
//  APIClient.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

/// Client API for an example merchant backend.
final class APIClient {
    private enum DefaultsKeys {
        static let authTokenWithLAI = "authTokenWithLAI"
        static let email = "email"
    }

    static let shared = APIClient()

    private let session: URLSession
    private let baseURL = URL(string: "https://crypto-onramp-example.stripedemos.com")
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private(set) var authToken: String?
    private(set) var authTokenWithLAI = UserDefaults.standard.string(forKey: DefaultsKeys.authTokenWithLAI)
    private(set) var email = UserDefaults.standard.string(forKey: DefaultsKeys.email)

    private init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        self.jsonDecoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        self.jsonEncoder = encoder
    }

    enum HTTPMethod: String {
        case GET
        case POST
    }

    enum APIError: Error, LocalizedError {
        case httpError(status: Int, message: String)
        case missingAuthToken
        case missingAuthTokenWithLAI

        var errorDescription: String? {
            switch self {
            case .httpError(let status, let message):
                return "HTTP \(status): \(message)"
            case .missingAuthToken:
                return "Missing Authorization token"
            case .missingAuthTokenWithLAI:
                return "Missing Authorization token with LAI"
            }
        }
    }

    func setAuthToken(_ token: String, email: String) {
        self.authToken = token
        self.email = email
        UserDefaults.standard.set(email, forKey: DefaultsKeys.email)
    }

    func setAuthTokenWithLAI(_ token: String) {
        self.authTokenWithLAI = token
        UserDefaults.standard.set(token, forKey: DefaultsKeys.authTokenWithLAI)
    }

    func clearAuthTokens() {
        self.authToken = nil
        self.authTokenWithLAI = nil
        self.email = nil
    }

    func request<T: Decodable, Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .GET,
        body: Body? = nil,
        bearerToken: String? = nil,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try body.map { try jsonEncoder.encode($0) }
        return try await performRequest(
            path,
            method: method,
            bodyData: data,
            bearerToken: bearerToken,
            headers: headers,
            queryItems: queryItems
        )
    }

    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .GET,
        bearerToken: String? = nil,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        try await performRequest(
            path,
            method: method,
            bodyData: nil,
            bearerToken: bearerToken,
            headers: headers,
            queryItems: queryItems
        )
    }

    private func performRequest<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        bodyData: Data?,
        bearerToken: String?,
        headers: [String: String],
        queryItems: [URLQueryItem]?
    ) async throws -> T {
        guard let baseURL = baseURL, var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        if let queryItems {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        if let bodyData {
            urlRequest.httpBody = bodyData
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        headers.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        if let bearerToken {
            urlRequest.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(status: httpResponse.statusCode, message: message)
        }

        return try jsonDecoder.decode(T.self, from: data)
    }
}

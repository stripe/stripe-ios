//
//  APIClient.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL = URL(string: "https://crypto-onramp-example.stripedemos.com")!

    let jsonDecoder: JSONDecoder
    let jsonEncoder: JSONEncoder

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

    enum HTTPMethod: String { case GET, POST, PUT, DELETE, PATCH }

    enum APIError: Error, LocalizedError {
        case httpError(status: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .httpError(let status, let message):
                return "HTTP \(status): \(message)"
            }
        }
    }

    func request<T: Decodable, Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .GET,
        body: Body? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            urlRequest.httpBody = try jsonEncoder.encode(body)
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        headers.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
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

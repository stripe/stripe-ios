//
//  APIClient.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

/// Client API for an example merchant backend.
@MainActor
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL = URL(string: "https://crypto-onramp-example.stripedemos.com")
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private(set) var authToken: String?
    private(set) var authTokenWithLAI: String?
    private var email: String?
    private var authorizedScopes: [OAuthScopes]?
    private var sessionID = UUID()
    private var linkAuthorizationCounter = 0
    private var reauthorizationTask: Task<Void, Error>?

    var authorizeLink: (([OAuthScopes], Bool) async throws -> Void)?
    var onLinkAuthorizationLost: ((Error) -> Void)?

    var reauthorizationEmail: String? {
        guard authToken != nil, authorizedScopes != nil else { return nil }
        return email
    }

    private var persistedSeamlessSignInDetails: SeamlessSignInDetails? {
        // Note that `UserDefaults` are used here in this example app for simplicity.
        // In a real app, more secure storage mechanisms should be used, such as the Keychain.
        guard let seamlessSignInData = UserDefaults.standard.data(forKey: DefaultsKeys.seamlessSignInDetails) else {
            return nil
        }

        return try? jsonDecoder.decode(SeamlessSignInDetails.self, from: seamlessSignInData)
    }

    /// Persisted email address to use for seamless sign-in.
    var seamlessSignInEmail: String? {
        return persistedSeamlessSignInDetails?.email
    }

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

        if ProcessInfo.processInfo.environment["UITesting"] != nil {
            // When UI testing, start with a clean auth state.
            clearAuthState()
        } else if let seamlessSignInDetails = persistedSeamlessSignInDetails {
            self.authTokenWithLAI = seamlessSignInDetails.token
            self.email = seamlessSignInDetails.email
            self.authorizedScopes = seamlessSignInDetails.scopes
        }
    }

    enum HTTPMethod: String {
        case GET
        case POST
    }

    enum APIError: Error, LocalizedError {
        case httpError(status: Int, message: String, code: String?)
        case demoBackendSignInRequired
        case missingAuthTokenWithLAI
        case linkVerificationRequired
        case linkReauthorizationDeclined
        case retryActionAfterLinkVerification

        var requiresLinkReauthorization: Bool {
            if case .httpError(403, _, "link_reauthorization_required") = self {
                return true
            }
            return false
        }

        var errorDescription: String? {
            switch self {
            case .httpError(let status, let message, let code):
                return "HTTP \(status), code: \(code ?? "unknown"), message: \(message)"
            case .demoBackendSignInRequired:
                return "Sign in again to continue."
            case .missingAuthTokenWithLAI:
                return "Missing Authorization token with LAI"
            case .linkVerificationRequired, .linkReauthorizationDeclined:
                return "Verify with Link to continue."
            case .retryActionAfterLinkVerification:
                return "Link verification completed. Please try this action again."
            }
        }
    }

    func setAuthToken(_ token: String, email: String) {
        clearAuthState()
        self.authToken = token
        self.email = email
    }

    func saveAuthorizedUser(
        cryptoCustomerId: String,
        intent: CreateAuthIntentResponse,
        scopes: [OAuthScopes]
    ) async throws {
        try Task.checkCancellation()
        let sessionID = self.sessionID
        let response = try await saveUser(cryptoCustomerId: cryptoCustomerId, bearerToken: intent.token)
        guard sessionID == self.sessionID else { throw CancellationError() }
        try Task.checkCancellation()
        guard response.success else { throw URLError(.badServerResponse) }
        authTokenWithLAI = intent.token
        authorizedScopes = scopes
        linkAuthorizationCounter += 1
        persistSeamlessSignInDetails()
    }

    func clearAuthState() {
        sessionID = UUID()
        reauthorizationTask?.cancel()
        reauthorizationTask = nil
        authToken = nil
        email = nil
        authorizedScopes = nil
        clearLinkAuthorization()
    }

    private func clearLinkAuthorization() {
        authTokenWithLAI = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKeys.seamlessSignInDetails)
    }

    func reauthorizeLink(requiresConfirmation: Bool = true) async throws {
        if let reauthorizationTask {
            try await reauthorizationTask.value
            return
        }

        let sessionID = self.sessionID
        clearLinkAuthorization()

        let task = Task {
            defer {
                if sessionID == self.sessionID {
                    reauthorizationTask = nil
                }
            }
            do {
                guard let authorizeLink, let authorizedScopes, authToken != nil else {
                    throw APIError.demoBackendSignInRequired
                }
                try await authorizeLink(authorizedScopes, requiresConfirmation)
                guard sessionID == self.sessionID else { throw CancellationError() }
            } catch {
                guard sessionID == self.sessionID else { throw CancellationError() }
                switch error {
                case APIError.demoBackendSignInRequired, APIError.linkReauthorizationDeclined:
                    clearAuthState()
                default:
                    break
                }
                onLinkAuthorizationLost?(error)
                throw APIError.linkVerificationRequired
            }
        }
        reauthorizationTask = task
        try await task.value
    }

    func withLinkAuthorization<T>(
        retryAfterReauthorization: Bool = true,
        _ operation: (String) async throws -> T
    ) async throws -> T {
        let sessionID = self.sessionID
        try await reauthorizationTask?.value
        guard sessionID == self.sessionID else { throw CancellationError() }
        try Task.checkCancellation()
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        let authorizationCounter = linkAuthorizationCounter
        let response: T
        do {
            response = try await operation(token)
        } catch let error as APIError where error.requiresLinkReauthorization {
            guard sessionID == self.sessionID else { throw CancellationError() }
            if let reauthorizationTask {
                try await reauthorizationTask.value
            } else if authTokenWithLAI != nil, linkAuthorizationCounter == authorizationCounter {
                // Another request may already have renewed the authorization that failed.
                try await reauthorizeLink()
            }

            guard sessionID == self.sessionID else { throw CancellationError() }

            try Task.checkCancellation()

            guard let renewedToken = authTokenWithLAI else { throw APIError.linkVerificationRequired }
            guard retryAfterReauthorization else { throw APIError.retryActionAfterLinkVerification }

            let renewedCounter = linkAuthorizationCounter
            do {
                response = try await operation(renewedToken)
            } catch let error as APIError where error.requiresLinkReauthorization {
                if sessionID == self.sessionID, authTokenWithLAI != nil, linkAuthorizationCounter == renewedCounter {
                    clearLinkAuthorization()
                    onLinkAuthorizationLost?(error)
                }
                throw APIError.linkVerificationRequired
            }
        }
        guard sessionID == self.sessionID else { throw CancellationError() }
        return response
    }

    private func persistSeamlessSignInDetails() {
        // Note that `UserDefaults` are used here in this example app for simplicity.
        // In a real app, more secure storage mechanisms should be used, such as the Keychain.
        guard let email = email, let token = authTokenWithLAI else { return }
        let details = SeamlessSignInDetails(email: email, token: token, scopes: authorizedScopes)
        if let data = try? jsonEncoder.encode(details) {
            UserDefaults.standard.set(data, forKey: DefaultsKeys.seamlessSignInDetails)
        } else {
            UserDefaults.standard.removeObject(forKey: DefaultsKeys.seamlessSignInDetails)
        }
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
            if let apiErrorBody = try? jsonDecoder.decode(APIErrorBody.self, from: data) {
                throw APIError.httpError(
                    status: httpResponse.statusCode,
                    message: apiErrorBody.details.error.message ?? apiErrorBody.error,
                    code: apiErrorBody.details.error.code
                )
            } else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.httpError(status: httpResponse.statusCode, message: message, code: nil)
            }
        }

        return try jsonDecoder.decode(T.self, from: data)
    }
}

/// Decodable structure for parsing demo-backend errors in their expected format.
private struct APIErrorBody: Decodable {
    struct Details: Decodable {
        struct StripeError: Decodable {
            let code: String?
            let message: String?
            let requestLogURL: URL?
            let type: String?
        }

        let error: StripeError
    }

    let error: String
    let details: Details
}

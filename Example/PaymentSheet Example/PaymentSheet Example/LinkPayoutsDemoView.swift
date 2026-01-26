//
//  LinkPayoutsDemoView.swift
//  PaymentSheet Example
//

import SwiftUI
@preconcurrency import WebKit

@available(iOS 26.0, *)
struct LinkPayoutsDemoView: View {
    @State private var result: LinkPayoutsResult?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var testResult: TestResult = .none
    @State private var webViewURL: URL?

    private let callbackHost = "example.com"
    private let callbackPath = "/link-onboarding"
    private let callbackURL = "https://example.com/link-onboarding"
    private let publishableKey = "pk_test_51StuO5CqcrH2jR0P8OuJZOsflWbkXwGjlJO2T8VL2jhNwVQphlGLqn1YONtqHnNJcqNHuHCQx0IMvFyxGXYf0P2l00w8PDVPMN"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Link Payouts Demo")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                Text("Test Result:")
                Picker("Test Result", selection: $testResult) {
                    ForEach(TestResult.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 32)

            Button {
                launchFlow()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Launch flow")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal, 32)

            if let result {
                resultView(for: result)
                    .padding(.horizontal, 16)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .navigationTitle("Link Payouts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $webViewURL) { url in
            LinkPayoutsWebViewSheet(
                url: url,
                callbackHost: callbackHost,
                callbackPath: callbackPath,
                onCallback: { callbackURL in
                    webViewURL = nil
                    isLoading = false
                    result = LinkPayoutsResult(from: callbackURL)
                },
                onDismiss: {
                    webViewURL = nil
                    isLoading = false
                    errorMessage = "Flow was cancelled"
                }
            )
        }
    }

    @ViewBuilder
    private func resultView(for result: LinkPayoutsResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.status == .success ? .green : .red)
                Text(result.status == .success ? "Success" : "Error")
                    .font(.headline)
            }

            if let payoutMethod = result.payoutMethod {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payout Method:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(payoutMethod)
                        .font(.system(.body, design: .monospaced))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Callback URL:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(result.rawURL.absoluteString)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }

    private func launchFlow() {
        result = nil
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let connectionSession = try await LinkPayoutsAPIClient.getConnectionSession()
                await MainActor.run {
                    presentWebView(clientSecret: connectionSession.clientSecret)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    @MainActor
    private func presentWebView(clientSecret: String) {
        var components = URLComponents(string: "https://onboarding.link.com/onboard")!
        var queryItems = [
            URLQueryItem(name: "publishable_key", value: publishableKey),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "callback_url", value: callbackURL),
        ]

        if let testResultValue = testResult.parameterValue {
            queryItems.append(URLQueryItem(name: "test_result", value: testResultValue))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            isLoading = false
            errorMessage = "Failed to construct URL"
            return
        }

        webViewURL = url
    }
}

// MARK: - WebView Sheet

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

@available(iOS 26.0, *)
struct LinkPayoutsWebViewSheet: View {
    let url: URL
    let callbackHost: String
    let callbackPath: String
    let onCallback: (URL) -> Void
    let onDismiss: () -> Void

    @State private var webPage: WebPage?
    @State private var navigationDecider: LinkPayoutsNavigationDecider?

    var body: some View {
        NavigationStack {
            Group {
                if let webPage {
                    WebView(webPage)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Demo Webview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            let decider = LinkPayoutsNavigationDecider(
                callbackHost: callbackHost,
                callbackPath: callbackPath,
                onCallback: onCallback
            )
            navigationDecider = decider
            let page = WebPage(configuration: .init(), navigationDecider: decider)
            webPage = page

            Task {
                for try await event in page.load(URLRequest(url: url)) {
                    print("[LinkPayoutsDemo] Navigation event: \(event)")
                }
            }
        }
    }
}

// MARK: - Navigation Decider

@available(iOS 26.0, *)
@MainActor
final class LinkPayoutsNavigationDecider: WebPage.NavigationDeciding {
    let callbackHost: String
    let callbackPath: String
    let onCallback: (URL) -> Void

    init(callbackHost: String, callbackPath: String, onCallback: @escaping (URL) -> Void) {
        self.callbackHost = callbackHost
        self.callbackPath = callbackPath
        self.onCallback = onCallback
    }

    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        let url = action.request.url

        print("[LinkPayoutsDemo] Navigation: \(url?.absoluteString ?? "nil")")

        if let url, url.host() == callbackHost, url.path() == callbackPath {
            print("[LinkPayoutsDemo] Callback URL detected: \(url.absoluteString)")
            onCallback(url)
            return .cancel
        }

        return .allow
    }
}

// MARK: - Test Result Option

enum TestResult: CaseIterable {
    case none
    case success
    case error

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .success:
            return "Success"
        case .error:
            return "Error"
        }
    }

    var parameterValue: String? {
        switch self {
        case .none:
            return nil
        case .success:
            return "success"
        case .error:
            return "error"
        }
    }
}

// MARK: - Result Parsing

struct LinkPayoutsResult {
    enum Status: String {
        case success
        case error
    }

    let status: Status
    let payoutMethod: String?
    let nonce: String?
    let rawURL: URL

    init?(from url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })

        guard let statusString = params["status"],
              let status = Status(rawValue: statusString) else {
            return nil
        }

        self.status = status
        self.payoutMethod = params["payout_method"]
        self.nonce = params["nonce"]
        self.rawURL = url
    }
}

// MARK: - API Client

enum LinkPayoutsAPIClient {
    private static let baseURL = URL(string: "https://link-payouts-demo.stripedemos.com")!

    /// Client secret expires after 2 minutes, use 90 seconds to be safe
    private static let cacheValidityDuration: TimeInterval = 90

    private static var cachedSession: CachedConnectionSession?

    private struct CachedConnectionSession {
        let session: ConnectionSession
        let createdAt: Date

        var isValid: Bool {
            Date().timeIntervalSince(createdAt) < cacheValidityDuration
        }
    }

    static func getConnectionSession() async throws -> ConnectionSession {
        if let cached = cachedSession, cached.isValid {
            print("[LinkPayoutsDemo] Using cached connection session (age: \(Int(Date().timeIntervalSince(cached.createdAt)))s)")
            return cached.session
        }

        print("[LinkPayoutsDemo] Fetching new connection session...")
        let session = try await fetchConnectionSession()
        cachedSession = CachedConnectionSession(session: session, createdAt: Date())
        return session
    }

    static func clearCache() {
        cachedSession = nil
        print("[LinkPayoutsDemo] Connection session cache cleared")
    }

    private static func fetchConnectionSession() async throws -> ConnectionSession {
        let url = baseURL.appendingPathComponent("connection_session")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinkPayoutsAPIError.invalidResponse
        }

        let requestId = httpResponse.value(forHTTPHeaderField: "Stripe-Request-Id")
        if let requestId {
            print("[LinkPayoutsDemo] Stripe-Request-Id: \(requestId)")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseErrorMessage(from: data)
            throw LinkPayoutsAPIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage,
                requestId: requestId
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ConnectionSession.self, from: data)
    }

    private static func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let error: String?
            let stripeRequestId: String?
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.error
    }
}

struct ConnectionSession: Decodable {
    let id: String
    let clientSecret: String
}

enum LinkPayoutsAPIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String?, requestId: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message, let requestId):
            var description = "HTTP \(statusCode)"
            if let message {
                description += ": \(message)"
            }
            if let requestId {
                description += "\n(Request ID: \(requestId))"
            }
            return description
        }
    }
}

@available(iOS 26.0, *)
struct LinkPayoutsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LinkPayoutsDemoView()
        }
    }
}

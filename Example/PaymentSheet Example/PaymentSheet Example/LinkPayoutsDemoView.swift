//
//  LinkPayoutsDemoView.swift
//  PaymentSheet Example
//

import AuthenticationServices
import SwiftUI

@available(iOS 15.0, *)
struct LinkPayoutsDemoView: View {
    @State private var result: LinkPayoutsResult?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var testResult: TestResult = .none

    private let callbackScheme = "stripe-auth"
    private let callbackURL = "stripe-auth://callback"
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
                    .padding(.horizontal, 32)
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
                let connectionSession = try await LinkPayoutsAPIClient.createConnectionSession()
                presentWebAuth(clientSecret: connectionSession.clientSecret)
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    @MainActor
    private func presentWebAuth(clientSecret: String) {
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

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { url, error in
            isLoading = false

            if let error = error as? ASWebAuthenticationSessionError,
               error.code == .canceledLogin {
                errorMessage = "Flow was cancelled"
                return
            }

            if let error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }

            if let url {
                result = LinkPayoutsResult(from: url)
            }
        }

        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = WebAuthPresentationContextProvider.shared

        session.start()
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

    static func createConnectionSession() async throws -> ConnectionSession {
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

private class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow ?? ASPresentationAnchor()
    }
}

@available(iOS 15.0, *)
struct LinkPayoutsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LinkPayoutsDemoView()
        }
    }
}

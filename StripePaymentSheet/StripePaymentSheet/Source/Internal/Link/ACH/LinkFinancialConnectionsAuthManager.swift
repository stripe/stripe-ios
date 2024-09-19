//
//  LinkFinancialConnectionsAuthManager.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 5/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
import UIKit

@_spi(STP) import StripeCore

/// For internal SDK use only
@objc(STP_Internal_LinkFinancialConnectionsAuthManager)
final class LinkFinancialConnectionsAuthManager: NSObject {
    struct Constants {
        static let linkedAccountIDQueryParameterName = "linked_account"
    }

    enum Error: Swift.Error, LocalizedError {
        case canceled
        case failedToStart
        case noLinkedAccountID
        case noURL
        case unexpectedURL

        var errorDescription: String? {
            return NSError.stp_unexpectedErrorMessage()
        }
    }

    struct Manifest: Decodable {
        let hostedAuthURL: URL
        let successURL: URL
        let cancelURL: URL

        enum CodingKeys: String, CodingKey {
            case hostedAuthURL = "hosted_auth_url"
            case successURL = "success_url"
            case cancelURL = "cancel_url"
        }
    }

    let linkAccount: PaymentSheetLinkAccount
    let window: UIWindow?

    init(linkAccount: PaymentSheetLinkAccount, window: UIWindow?) {
        self.linkAccount = linkAccount
        self.window = window
    }

    /// Initiate a Financial Connections session for Link Instant Debits.
    /// - Parameter clientSecret: The client secret of the consumer's Link account session.
    /// - Returns: The ID for the newly linked account.
    /// - Throws: Either `Error.canceled`, meaning the user canceled the flow, or an error describing what went wrong.
    func start(clientSecret: String) async throws -> String {
        let manifest = try await generateHostedURL(withClientSecret: clientSecret)
        return try await authenticate(withManifest: manifest)
    }

}

extension LinkFinancialConnectionsAuthManager {

    private func generateHostedURL(withClientSecret clientSecret: String) async throws -> Manifest {
        return try await withCheckedThrowingContinuation { continuation in
            linkAccount.apiClient.post(
                resource: "link_account_sessions/generate_hosted_url",
                parameters: [
                    "client_secret": clientSecret,
                    "fullscreen": true,
                    "hide_close_button": true,
                ],
                ephemeralKeySecret: linkAccount.publishableKey
            ).observe { result in
                continuation.resume(with: result)
            }
        }
    }

    private func authenticate(withManifest manifest: Manifest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(
                url: manifest.hostedAuthURL,
                callbackURLScheme: manifest.successURL.scheme,
                completionHandler: { url, error in
                    if let error = error {
                        if let authenticationSessionError = error as? ASWebAuthenticationSessionError,
                            authenticationSessionError.code == .canceledLogin
                        {
                            return continuation.resume(throwing: Error.canceled)
                        }
                        return continuation.resume(throwing: error)
                    }

                    guard let url = url else {
                        return continuation.resume(throwing: Error.noURL)
                    }

                    if url.matchesSchemeHostAndPath(of: manifest.successURL) {
                        if let linkedAccountID = Self.extractLinkedAccountID(from: url) {
                            return continuation.resume(returning: linkedAccountID)
                        } else {
                            return continuation.resume(throwing: Error.noLinkedAccountID)
                        }
                    } else if url.matchesSchemeHostAndPath(of: manifest.cancelURL) {
                        return continuation.resume(throwing: Error.canceled)
                    } else {
                        return continuation.resume(throwing: Error.unexpectedURL)
                    }
                }
            )

            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true

            if #available(iOS 13.4, *) {
                guard authSession.canStart else {
                    return continuation.resume(throwing: Error.failedToStart)
                }
            }

            authSession.start()
        }
    }

}

// MARK: - Presentation context

@available(iOS 13, *)
extension LinkFinancialConnectionsAuthManager: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.window ?? ASPresentationAnchor()
    }

}

// MARK: - Utils

extension LinkFinancialConnectionsAuthManager {

    private static func extractLinkedAccountID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            assertionFailure("Invalid URL")
            return nil
        }

        return components
            .queryItems?
            .first(where: { $0.name == Constants.linkedAccountIDQueryParameterName })?
            .value
    }

}

private extension URL {

    func matchesSchemeHostAndPath(of otherURL: URL) -> Bool {
        return (
            self.scheme == otherURL.scheme &&
            self.host == otherURL.host &&
            self.path == otherURL.path
        )
    }

}

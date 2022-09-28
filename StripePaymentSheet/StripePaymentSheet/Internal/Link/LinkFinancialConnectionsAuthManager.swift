//
//  LinkFinancialConnectionsAuthManager.swift
//  StripeiOS
//
//  Created by Ramon Torres on 5/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import AuthenticationServices

@_spi(STP) import StripeCore

/// For internal SDK use only
@objc(STP_Internal_LinkFinancialConnectionsAuthManager)
final class LinkFinancialConnectionsAuthManager: NSObject {
    struct Constants {
        static let linkedAccountIDQueryParameterName = "linked_account"
    }

    enum AuthenticationResult {
        case success(linkedAccountID: String)
        case canceled
        case failure(Error)
    }

    enum AuthenticationError: Error, LocalizedError {
        case unknown(_ debugDescription: String)

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

    typealias CompletionBlock = (AuthenticationResult) -> Void

    let linkAccount: PaymentSheetLinkAccount
    let window: UIWindow?

    init(linkAccount: PaymentSheetLinkAccount, window: UIWindow?) {
        self.linkAccount = linkAccount
        self.window = window
    }

    func start(
        clientSecret: String,
        completion: @escaping CompletionBlock
    ) {
        generateHostedURL(withClientSecret: clientSecret).observe { [weak self] result in
            switch result {
            case .success(let manifest):
                self?.authenticate(withManifest: manifest, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}

extension LinkFinancialConnectionsAuthManager {

    private func generateHostedURL(withClientSecret clientSecret: String) -> Promise<Manifest> {
        return linkAccount.apiClient.post(
            resource: "link_account_sessions/generate_hosted_url",
            parameters: [
                "client_secret": clientSecret,
                "fullscreen": true,
                "hide_close_button": true
            ],
            ephemeralKeySecret: linkAccount.publishableKey
        )
    }

    private func authenticate(
        withManifest manifest: Manifest,
        completion: @escaping CompletionBlock
    ) {
        let authSession = ASWebAuthenticationSession(
            url: manifest.hostedAuthURL,
            callbackURLScheme: manifest.successURL.scheme,
            completionHandler: { url, error in
                if let error = error {
                    if let authenticationSessionError = error as? ASWebAuthenticationSessionError {
                        switch authenticationSessionError.code {
                        case .canceledLogin:
                            completion(.canceled)
                        default:
                            completion(.failure(authenticationSessionError))
                        }
                    } else {
                        completion(.failure(error))
                    }
                    return
                }

                guard let url = url else {
                    completion(.failure(
                        AuthenticationError.unknown("Unexpected `nil` URL")
                    ))
                    return
                }

                if url.matchesSchemeHostAndPath(of: manifest.successURL) {
                    if let linkedAccountID = Self.extractLinkedAccountID(from: url) {
                        completion(.success(linkedAccountID: linkedAccountID))
                    } else {
                        completion(.failure(
                            AuthenticationError.unknown("URL is missing the linked account ID")
                        ))
                    }
                } else if url.matchesSchemeHostAndPath(of: manifest.cancelURL) {
                    completion(.canceled)
                } else {
                    completion(.failure(
                        AuthenticationError.unknown("Unexpected URL")
                    ))
                }
            }
        )

        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
        }

        if #available(iOS 13.4, *) {
            guard authSession.canStart else {
                completion(.failure(
                    AuthenticationError.unknown("Failed to start session")
                ))
                return
            }
        }

        authSession.start()
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

//
//  InstantDebitsOnlyFinancialConnectionsAuthManager.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/12/23.
//

import AuthenticationServices
import UIKit

@_spi(STP) import StripeCore

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

/// For internal SDK use only
final class InstantDebitsOnlyAuthenticationSessionManager: NSObject {

    // MARK: - Types

    enum Result {
        case success(paymentMethodID: String)
        case canceled
    }

    enum Error: Swift.Error, LocalizedError {
        case failedToStart
        case noURL
        case unexpectedURL
        case noPaymentDetailsID
        case canceled

        var errorDescription: String? {
            return NSError.stp_unexpectedErrorMessage()
        }
    }

    // MARK: - Properties

    private var authSession: ASWebAuthenticationSession?
    private var window: UIWindow?

    // MARK: - Init

    init(window: UIWindow?) {
        self.window = window
    }

    // MARK: - Public

    private func hostedAuthURL(for manifest: Manifest) -> URL {
        return URL(string: manifest.hostedAuthURL.absoluteString + "&return_payment_method=true")!
    }

    func start(manifest: Manifest) -> Promise<InstantDebitsOnlyAuthenticationSessionManager.Result> {
        let promise = Promise<InstantDebitsOnlyAuthenticationSessionManager.Result>()

        let authSession = ASWebAuthenticationSession(
            url: hostedAuthURL(for: manifest),
            callbackURLScheme: manifest.successURL.scheme,
            completionHandler: { returnUrl, error in

                if let error = error {
                    if let authenticationSessionError = error as? ASWebAuthenticationSessionError {
                        switch authenticationSessionError.code {
                        case .canceledLogin:
                            promise.resolve(with: .canceled)
                        default:
                            promise.reject(with: authenticationSessionError)
                        }
                    } else {
                        promise.reject(with: error)
                    }
                    return
                }

                guard let returnUrl = returnUrl else {
                    promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.noURL)
                    return
                }

                if returnUrl.matchesSchemeHostAndPath(of: manifest.successURL) {
                    if let paymentMethodID = Self.extractPaymentMethodID(from: returnUrl) {
                        promise.fullfill(with: .success(.success(paymentMethodID: paymentMethodID)))
                    } else {
                        promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.noPaymentDetailsID)
                    }
                } else {
                    // more error handling needed
                    promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.canceled)
                }
            }
        )
        authSession.presentationContextProvider = self
        authSession.prefersEphemeralWebBrowserSession = true

        self.authSession = authSession
        if #available(iOS 13.4, *) {
            if !authSession.canStart {
                promise.reject(
                    with: InstantDebitsOnlyAuthenticationSessionManager.Error.failedToStart
                )
                return promise
            }
        }

        if !authSession.start() {
            promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.failedToStart)
            return promise
        }

        return promise
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

/// :nodoc:

extension InstantDebitsOnlyAuthenticationSessionManager: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.window ?? ASPresentationAnchor()
    }
}


// MARK: - Utils

extension InstantDebitsOnlyAuthenticationSessionManager {

    private static func extractPaymentMethodID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            assertionFailure("Invalid URL")
            return nil
        }

        return components
            .queryItems?
            .first(where: { $0.name == "payment_method_id" })?
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

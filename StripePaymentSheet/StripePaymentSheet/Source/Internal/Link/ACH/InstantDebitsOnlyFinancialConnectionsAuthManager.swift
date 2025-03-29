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

    struct RedactedPaymentDetails {
        let paymentMethodID: String
        let bankName: String?
        let bankIconCode: String?
        let last4: String?
    }

    enum Result {
        case success(details: RedactedPaymentDetails)
        case canceled
    }

    enum Error: Swift.Error, LocalizedError {
        case failedToStart
        case noURL
        case unexpectedURL
        case noPaymentMethodID
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
        // Adds a parameter for the flow to return payment method id
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
                    if let paymentMethodID = Self.extractValue(from: returnUrl, key: "payment_method_id") {
                        let details = RedactedPaymentDetails(paymentMethodID: paymentMethodID,
                                                             bankName: Self.extractValue(from: returnUrl, key: "bank_name")?.replacingOccurrences(of: "+", with: " "),
                                                             bankIconCode: Self.extractValue(from: returnUrl, key: "bank_icon_code"),
                                                             last4: Self.extractValue(from: returnUrl, key: "last4"))
                        promise.fullfill(with: .success(.success(details: details)))
                    } else {
                        promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.noPaymentMethodID)
                    }
                } else if returnUrl.matchesSchemeHostAndPath(of: manifest.cancelURL) {
                    promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.canceled)
                } else {
                    promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.noURL)
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

    func cancel() {
        authSession?.cancel()
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

    private static func extractValue(from url: URL, key: String) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            assertionFailure("Invalid URL")
            return nil
        }

        return components
            .queryItems?
            .first(where: { $0.name == key })?
            .value?.removingPercentEncoding
    }
}

//
//  InstantDebitsOnlyFinancialConnectionsAuthManager.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/12/23.
//

import AuthenticationServices
import UIKit

@_spi(STP) import StripeCore

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

    func start(hostedURL: URL, configuredReturnedURL: URL) -> Promise<InstantDebitsOnlyAuthenticationSessionManager.Result> {
        let promise = Promise<InstantDebitsOnlyAuthenticationSessionManager.Result>()

        let authSession = ASWebAuthenticationSession(
            url: hostedURL,
            callbackURLScheme: configuredReturnedURL.scheme,
            completionHandler: { returnUrl, error in
                print("DONE \(returnUrl?.absoluteString ?? "asdf")")

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

                if returnUrl.matchesSchemeHostAndPath(of: configuredReturnedURL) {
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

        /**
         This terribly hacky animation disabling is needed to control the presentation of ASWebAuthenticationSession underlying view controller.
         Since we present a modal already that itself presents ASWebAuthenticationSession, the double modal animation is jarring and a bad UX.
         We disable animations for a second. Sometimes there is a delay in creating the ASWebAuthenticationSession underlying view controller
         to be safe, I made the delay a full second. I didn't find a good way to make this approach less clowny.
         PresentedViewController is not KVO compliant and the notifications sent by presentation view controller that could help with knowing when
         ASWebAuthenticationSession underlying view controller finished presenting are considered private API.
         */
        let animationsEnabledOriginalValue = UIView.areAnimationsEnabled
        if #available(iOS 13, *) {
            UIView.setAnimationsEnabled(false)
        }

        if !authSession.start() {
            if #available(iOS 13, *) {
                UIView.setAnimationsEnabled(animationsEnabledOriginalValue)
            }
            promise.reject(with: InstantDebitsOnlyAuthenticationSessionManager.Error.failedToStart)
            return promise
        }
        
        if #available(iOS 13, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIView.setAnimationsEnabled(animationsEnabledOriginalValue)
            }
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
            .first(where: { $0.name == "payment_method" })?
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

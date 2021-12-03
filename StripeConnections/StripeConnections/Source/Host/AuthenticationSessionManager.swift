//
//  AuthenticationSessionManager.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/3/21.
//

import UIKit
import AuthenticationServices
@_spi(STP) import StripeCore

@available(iOS 12, *)
class AuthenticationSessionManager: NSObject {

    // MARK: - Types

    enum Result {
        case success, cancel
    }

    // MARK: - Properties

    fileprivate var authSession: ASWebAuthenticationSession?
    fileprivate let manifest: LinkAccountSessionManifest
    fileprivate var window: UIWindow?

    // MARK: - Init

    init(manifest: LinkAccountSessionManifest, window: UIWindow?) {
        self.manifest = manifest
        self.window = window
    }

    // MARK: - Public

    func start() -> Promise<AuthenticationSessionManager.Result> {
        let promise = Promise<AuthenticationSessionManager.Result>()
        guard let url = URL(string: manifest.hostedAuthUrl) else {
            promise.reject(with: ConnectionsSheetError.unknown(debugDescription: "Malformed URL"))
            return promise
        }
        let authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: Constants.callbackScheme,
            completionHandler: { [weak self] returnUrl, error in
                guard let self = self else { return }
                if let error = error {
                    promise.reject(with: error)
                    return
                }

                guard let returnUrlString = returnUrl?.absoluteString else {
                    promise.reject(with: ConnectionsSheetError.unknown(debugDescription: "Missing return URL"))
                    return
                 }

                if returnUrlString == self.manifest.successUrl {
                    promise.fullfill(with: Swift.Result.success(AuthenticationSessionManager.Result.success))
                } else if returnUrlString == self.manifest.cancelUrl {
                    promise.fullfill(with: Swift.Result.success(AuthenticationSessionManager.Result.cancel))
                } else {
                    promise.reject(with: ConnectionsSheetError.unknown(debugDescription: "Unknown return URL"))
                }
        })
        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
        }

        self.authSession = authSession
        if !authSession.start() {
            promise.reject(with: ConnectionsSheetError.unknown(debugDescription: "Failed to start session"))
        }
        return promise
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

@available(iOS 13, *)
extension AuthenticationSessionManager: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.window ?? ASPresentationAnchor()
    }
}

// MARK: - Constants

@available(iOS 12, *)
fileprivate extension AuthenticationSessionManager {
     enum Constants {
        static let callbackScheme = "stripe-auth"
    }
}

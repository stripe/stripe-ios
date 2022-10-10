//
//  AuthenticationSessionManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/3/21.
//

import UIKit
import AuthenticationServices
@_spi(STP) import StripeCore

final class AuthenticationSessionManager: NSObject {

    // MARK: - Types

    enum Result {
        case success
        case webCancelled
        case nativeCancelled
        case redirect(url: URL)
    }

    // MARK: - Properties

    private var authSession: ASWebAuthenticationSession?
    private let manifest: FinancialConnectionsSessionManifest
    private var window: UIWindow?

    // MARK: - Init

    init(manifest: FinancialConnectionsSessionManifest, window: UIWindow?) {
        self.manifest = manifest
        self.window = window
    }

    // MARK: - Public

    func start(additionalQueryParameters: String? = nil) -> Promise<AuthenticationSessionManager.Result> {
        let promise = Promise<AuthenticationSessionManager.Result>()
        let urlString = manifest.hostedAuthUrl + (additionalQueryParameters ?? "")

        guard let url = URL(string: urlString) else {
            promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Malformed hosted auth URL"))
            return promise
        }

        let authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: URL(string: manifest.successUrl)?.scheme,
            completionHandler: { [weak self] returnUrl, error in
                guard let self = self else { return }
                if let error = error {
                    if let authenticationSessionError = error as? ASWebAuthenticationSessionError {
                        switch authenticationSessionError.code {
                        case .canceledLogin:
                            promise.resolve(with: .nativeCancelled)
                        default:
                            promise.reject(with: authenticationSessionError)
                        }
                    } else {
                        promise.reject(with: error)
                    }
                    return
                }

                guard let returnUrlString = returnUrl?.absoluteString else {
                    promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Missing return URL"))
                    return
                 }

                if returnUrlString == self.manifest.successUrl {
                    promise.resolve(with: .success)
                } else if returnUrlString == self.manifest.cancelUrl {
                    promise.resolve(with: .webCancelled)
                } else if returnUrlString.starts(with: Constants.nativeRedirectPrefix), let targetURL = URL(string: returnUrlString.dropPrefix(Constants.nativeRedirectPrefix)) {
                    promise.resolve(with: .redirect(url: targetURL))
                } else {
                    promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Nil return URL"))
                }
        })
        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
        }

        self.authSession = authSession
        if #available(iOS 13.4, *) {
            if !authSession.canStart {
                promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Failed to start session"))
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
            promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Failed to start session"))
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
@available(iOS 13, *)
extension AuthenticationSessionManager: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.window ?? ASPresentationAnchor()
    }
}

// MARK: - Constants

/// :nodoc:
extension AuthenticationSessionManager {
    private enum Constants {
        static let nativeRedirectPrefix = "stripe-auth://native-redirect/"
    }
}

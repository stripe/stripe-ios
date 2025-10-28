//
//  AuthenticationSessionManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/3/21.
//

import AuthenticationServices
@_spi(STP) import StripeCore
import UIKit

final class AuthenticationSessionManager: NSObject {

    // MARK: - Types

    enum Result {
        case success(returnUrl: URL)
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

    func start(hostedAuthUrl: URL) -> Promise<AuthenticationSessionManager.Result> {
        let promise = Promise<AuthenticationSessionManager.Result>()

        guard let successUrl = manifest.successUrl else {
            promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "NULL `successUrl`"))
            return promise
        }

        let authSession = ASWebAuthenticationSession(
            url: hostedAuthUrl,
            callbackURLScheme: URL(string: successUrl)?.scheme,
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
                guard let returnUrl = returnUrl else {
                    promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Missing return URL"))
                    return
                }
                let returnUrlString = returnUrl.absoluteString

                // `matchesSchemeHostAndPath` is necessary for instant debits which
                // contains additional query parameters at the end of the `successUrl`
                if returnUrl.matchesSchemeHostAndPath(of: URL(string: self.manifest.successUrl ?? ""))  {
                    promise.resolve(with: .success(returnUrl: returnUrl))
                } else if  returnUrl.matchesSchemeHostAndPath(of: URL(string: self.manifest.cancelUrl ?? ""))  {
                    promise.resolve(with: .webCancelled)
                } else if returnUrlString.hasNativeRedirectPrefix,
                    let targetURL = URL(string: returnUrlString.droppingNativeRedirectPrefix())
                {
                    promise.resolve(with: .redirect(url: targetURL))
                } else {
                    promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Nil return URL"))
                }
            }
        )
        authSession.presentationContextProvider = self
        authSession.prefersEphemeralWebBrowserSession = true

        self.authSession = authSession
        if #available(iOS 13.4, *) {
            if !authSession.canStart {
                promise.reject(
                    with: FinancialConnectionsSheetError.unknown(debugDescription: "Failed to start session")
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
        UIView.setAnimationsEnabled(false)

        if !authSession.start() {
            UIView.setAnimationsEnabled(animationsEnabledOriginalValue)
            promise.reject(with: FinancialConnectionsSheetError.unknown(debugDescription: "Failed to start session"))
            return promise
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIView.setAnimationsEnabled(animationsEnabledOriginalValue)
        }

        return promise
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

/// :nodoc:

extension AuthenticationSessionManager: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.window ?? ASPresentationAnchor()
    }
}

extension URL {
    fileprivate func matchesSchemeHostAndPath(of otherURL: URL?) -> Bool {
        guard let otherURL = otherURL else {
            return false
        }
        return (
            self.scheme == otherURL.scheme &&
            self.host == otherURL.host &&
            self.path == otherURL.path
        )
    }
}

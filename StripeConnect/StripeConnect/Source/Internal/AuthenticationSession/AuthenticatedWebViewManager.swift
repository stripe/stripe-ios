//
//  AuthenticatedWebViewManager.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/15/24.
//

import AuthenticationServices

/// Singleton helper to manage
class AuthenticatedWebViewManager: NSObject {
    typealias SessionFactory = (_ url: URL, _ callbackURLScheme: String?, _ completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) -> ASWebAuthenticationSession

    /// Used to dependency inject `ASWebAuthenticationSession.init` in tests
    private let sessionFactory: SessionFactory

    /// Window to present the session in
    private weak var window: UIWindow?

    /// Pointer to the auth session
    private weak var authSession: ASWebAuthenticationSession?

    init(sessionFactory: @escaping SessionFactory = ASWebAuthenticationSession.init) {
        self.sessionFactory = sessionFactory
    }

    /// Returns the redirect URL or nil if the user cancelled the flow
    func present(with url: URL, in window: UIWindow?) async throws -> URL? {
        guard authSession == nil else {
            throw AuthenticatedWebViewError.alreadyPresenting
        }
        guard let window else {
            throw AuthenticatedWebViewError.noWindow
        }
        self.window = window

        let returnUrl: URL? = try await withCheckedThrowingContinuation { continuation in
            let authSession = sessionFactory(url, StripeConnectConstants.authenticatedWebViewReturnUrlScheme) { returnUrl, error in
                continuation.resume(with: Result(catching: {
                    try AuthenticatedWebViewManager.completionHandler(returnUrl: returnUrl, error: error)
                }))
            }
            authSession.presentationContextProvider = self

            self.authSession = authSession

            guard authSession.canStart,
                  authSession.start() else {
                continuation.resume(throwing: AuthenticatedWebViewError.cannotStartSession)
                return
            }
        }

        return returnUrl
    }

    static func completionHandler(returnUrl: URL?, error: Error?) throws -> URL? {
        if let authenticationSessionError = error as? ASWebAuthenticationSessionError,
           authenticationSessionError.code == .canceledLogin {
            // The user either selected "Cancel" in the initial modal
            // prompting them to "Sign In" or they hit the "Cancel"
            // button in presented browser view
            return nil
        } else if let error {
            throw error
        }

        return returnUrl
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthenticatedWebViewManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return window ?? .init()
    }
}

//
//  AuthenticatedWebViewManager.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/15/24.
//

import AuthenticationServices

/// Manages authenticated web views for a single component
@available(iOS 15, *)
class AuthenticatedWebViewManager: NSObject {
    typealias SessionFactory = (
        _ url: URL,
        _ callbackURLScheme: String?,
        _ completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> ASWebAuthenticationSession

    /// Used to dependency inject in tests and wrap `ASWebAuthenticationSession.init`
    private let sessionFactory: SessionFactory

    /// The currently presented auth session, if there is one
    weak var authSession: ASWebAuthenticationSession?

    init(sessionFactory: @escaping SessionFactory = ASWebAuthenticationSession.init) {
        self.sessionFactory = sessionFactory
    }

    /// Returns the redirect URL or nil if the user cancelled the flow
    @MainActor
    func present(with url: URL, from view: UIView) async throws -> URL? {
        guard authSession == nil else {
            throw AuthenticatedWebViewError.alreadyPresenting
        }
        guard let window = view.window else {
            throw AuthenticatedWebViewError.notInViewHierarchy
        }

        let presentationContextProvider = AuthenticatedWebViewPresentationContextProvider(window: window)

        let returnUrl: URL? = try await withCheckedThrowingContinuation { continuation in
            let authSession = sessionFactory(url, StripeConnectConstants.authenticatedWebViewReturnUrlScheme) { returnUrl, error in

                if let authenticationSessionError = error as? ASWebAuthenticationSessionError,
                   authenticationSessionError.code == .canceledLogin {
                    // The user either selected "Cancel" in the initial modal
                    // prompting them to "Sign In" or they hit the "Cancel"
                    // button in presented browser view
                    continuation.resume(returning: nil)
                    return
                } else if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: returnUrl)
            }
            authSession.presentationContextProvider = presentationContextProvider
            self.authSession = authSession

            guard authSession.canStart,
                  authSession.start() else {
                continuation.resume(throwing: AuthenticatedWebViewError.cannotStartSession)
                return
            }
        }

        return returnUrl
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

private class AuthenticatedWebViewPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return window
    }
}

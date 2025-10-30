//
//  LinkVerificationWebFallbackController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 9/12/25.
//

import AuthenticationServices
import UIKit

final class LinkVerificationWebFallbackController: NSObject {
    private static let callbackURLSchme = "link-popup"

    typealias CompletionBlock = (LinkVerificationViewController.VerificationResult) -> Void

    private let authenticationUrl: URL
    private let window: UIWindow?
    private var authenticationSession: ASWebAuthenticationSession?
    private var completion: CompletionBlock?
    private var selfRetainer: LinkVerificationWebFallbackController?

    init(authenticationUrl: URL, presentingWindow: UIWindow?) {
        self.authenticationUrl = authenticationUrl
        self.window = presentingWindow
        super.init()
    }

    func present(completion: @escaping CompletionBlock) {
        self.completion = completion
        self.selfRetainer = self

        authenticationSession = ASWebAuthenticationSession(
            url: authenticationUrl,
            callbackURLScheme: Self.callbackURLSchme
        ) { [weak self] callbackURL, error in
            self?.handleAuthenticationResult(callbackURL: callbackURL, error: error)
        }

        authenticationSession?.presentationContextProvider = self
        authenticationSession?.prefersEphemeralWebBrowserSession = true
        authenticationSession?.start()
    }

    private func handleAuthenticationResult(callbackURL: URL?, error: Error?) {
        defer {
            authenticationSession = nil
            selfRetainer = nil
        }

        if let error {
            if let authError = error as? ASWebAuthenticationSessionError {
                switch authError.code {
                case .canceledLogin:
                    completion?(.canceled)
                default:
                    completion?(.failed(error))
                }
            } else {
                completion?(.failed(error))
            }
            return
        }

        guard let callbackURL else {
            completion?(.failed(ASWebAuthenticationSessionError(.presentationContextNotProvided)))
            return
        }

        // Check if this is the completion URL
        if callbackURL.scheme == Self.callbackURLSchme && callbackURL.host == "complete" {
            completion?(.completed)
        } else {
            completion?(.failed(ASWebAuthenticationSessionError(.presentationContextNotProvided)))
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension LinkVerificationWebFallbackController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return window ?? ASPresentationAnchor()
    }
}

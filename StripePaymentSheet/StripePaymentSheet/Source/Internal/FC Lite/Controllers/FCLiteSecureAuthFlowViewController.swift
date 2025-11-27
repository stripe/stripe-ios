//
//  FCLiteSecureAuthFlowViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-11-20.
//

import AuthenticationServices
@_spi(STP) import StripeCore
import UIKit

class FCLiteSecureAuthFlowViewController: UIViewController {
    private let manifest: LinkAccountSessionManifest
    private let elementsSessionContext: ElementsSessionContext?
    private let returnUrl: URL?
    private let completion: ((FCLiteWebFlowResult) -> Void)

    private var authSession: ASWebAuthenticationSession?

    private var hostedAuthUrl: URL {
        return HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: manifest.hostedAuthURL,
            isInstantDebits: manifest.isInstantDebits,
            hasExistingAccountholderToken: manifest.hasAccountholderToken,
            elementsSessionContext: elementsSessionContext
        )
    }

    init(
        manifest: LinkAccountSessionManifest,
        elementsSessionContext: ElementsSessionContext?,
        returnUrl: URL?,
        completion: @escaping ((FCLiteWebFlowResult) -> Void)
    ) {
        self.manifest = manifest
        self.elementsSessionContext = elementsSessionContext
        self.returnUrl = returnUrl
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        startAuthenticationSession()
    }

    private func startAuthenticationSession() {
        let callbackScheme = manifest.successURL.scheme

        let authSession = ASWebAuthenticationSession(
            url: hostedAuthUrl,
            callbackURLScheme: callbackScheme,
            completionHandler: { [weak self] returnUrl, error in
                guard let self else {
                    return
                }

                DispatchQueue.main.async {
                    if let error = error {
                        if let authenticationSessionError = error as? ASWebAuthenticationSessionError {
                            switch authenticationSessionError.code {
                            case .canceledLogin:
                                self.completion(.cancelled(.cancelledWithinWebview))
                            default:
                                self.completion(.failure(authenticationSessionError))
                            }
                        } else {
                            self.completion(.failure(error))
                        }
                        return
                    }

                    guard let returnUrl = returnUrl else {
                        self.completion(.failure(FCLiteError.missingReturnURL))
                        return
                    }

                    // `matchesSchemeHostAndPath` is necessary for instant debits which
                    // contains additional query parameters at the end of the `successUrl`.
                    if returnUrl.matchesSchemeHostAndPath(of: self.manifest.successURL) {
                        self.completion(.success(returnUrl: returnUrl))
                    } else if returnUrl.matchesSchemeHostAndPath(of: self.manifest.cancelURL) {
                        self.completion(.cancelled(.cancelledWithinWebview))
                    } else {
                        self.completion(.failure(FCLiteError.invalidReturnURL))
                    }
                }
            }
        )

        authSession.presentationContextProvider = self
        authSession.prefersEphemeralWebBrowserSession = true

        self.authSession = authSession

        if #available(iOS 13.4, *) {
            if !authSession.canStart {
                completion(.failure(FCLiteError.authSessionCannotStart))
                return
            }
        }

        // Disable animations to control the presentation of ASWebAuthenticationSession.
        // This prevents jarring double modal animations.
        let animationsEnabledOriginalValue = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)

        let started = authSession.start()

        if !started {
            UIView.setAnimationsEnabled(animationsEnabledOriginalValue)
            completion(.failure(FCLiteError.authSessionFailedToStart))
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIView.setAnimationsEnabled(animationsEnabledOriginalValue)
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension FCLiteSecureAuthFlowViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}

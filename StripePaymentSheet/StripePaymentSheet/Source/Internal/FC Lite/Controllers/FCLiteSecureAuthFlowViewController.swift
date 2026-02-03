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
    private let completion: ((FCLiteWebFlowResult) -> Void)

    /// Stored to maintain a strong reference and prevent deallocation.
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
        completion: @escaping ((FCLiteWebFlowResult) -> Void)
    ) {
        self.manifest = manifest
        self.elementsSessionContext = elementsSessionContext
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

        authSession = ASWebAuthenticationSession(
            url: hostedAuthUrl,
            callbackURLScheme: callbackScheme,
            completionHandler: { [weak self] callbackUrl, error in
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

                    guard let callbackUrl = callbackUrl else {
                        self.completion(.failure(FCLiteError.missingReturnURL))
                        return
                    }

                    // `matchesSchemeHostAndPath` is necessary for instant debits which
                    // contains additional query parameters at the end of the `successUrl`.
                    if callbackUrl.matchesSchemeHostAndPath(of: self.manifest.successURL) {
                        self.completion(.success(returnUrl: callbackUrl))
                    } else if callbackUrl.matchesSchemeHostAndPath(of: self.manifest.cancelURL) {
                        self.completion(.cancelled(.cancelledWithinWebview))
                    } else {
                        self.completion(.failure(FCLiteError.invalidReturnURL))
                    }
                }
            }
        )

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = true

        if #available(iOS 13.4, *) {
            if authSession?.canStart == false {
                completion(.failure(FCLiteError.authSessionCannotStart))
                return
            }
        }

        // Disable animations to control the presentation of ASWebAuthenticationSession.
        // This prevents jarring double modal animations.
        let animationsEnabledOriginalValue = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)

        let started = authSession?.start() ?? false

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
        if let window = self.view.window {
            return window
        }
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            return UIWindow(windowScene: windowScene)
        }
        #if os(visionOS)
        fatalError("No window scene available for ASPresentationAnchor on visionOS")
        #else
        return ASPresentationAnchor()
        #endif
    }
}

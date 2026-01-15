//
//  AuthenticationUIPresenter.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
import Foundation
import SafariServices
@_spi(STP) import StripeCore
import UIKit

/// Encapsulates UI presentation logic for authentication flows.
///
/// This class handles the presentation of Safari view controllers and
/// ASWebAuthenticationSession for payment authentication.
final class AuthenticationUIPresenter: NSObject {

    // MARK: - Properties

    /// The currently presented Safari view controller, if any
    private(set) var safariViewController: SFSafariViewController?

    /// The currently active web authentication session, if any
    private(set) var webAuthSession: ASWebAuthenticationSession?

    /// Callback scheme for web authentication sessions
    private let callbackScheme = "stripesdk"

    // MARK: - Safari View Controller Presentation

    /// Creates and configures a Safari view controller for the given URL.
    /// - Parameters:
    ///   - url: The URL to display
    ///   - context: The authentication context for configuration
    ///   - delegate: The delegate to receive Safari view controller events
    /// - Returns: A configured SFSafariViewController
    func createSafariViewController(
        for url: URL,
        context: STPAuthenticationContext,
        delegate: SFSafariViewControllerDelegate?
    ) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .overFullScreen
        #if !os(visionOS)
        safariVC.dismissButtonStyle = .close
        safariVC.delegate = delegate
        #endif

        if context.responds(to: #selector(STPAuthenticationContext.configureSafariViewController(_:))) {
            context.configureSafariViewController?(safariVC)
        }

        self.safariViewController = safariVC
        return safariVC
    }

    /// Presents a Safari view controller.
    /// - Parameters:
    ///   - safariVC: The Safari view controller to present
    ///   - presentingViewController: The view controller to present from
    ///   - completion: Called after presentation completes
    func presentSafariViewController(
        _ safariVC: SFSafariViewController,
        from presentingViewController: UIViewController,
        completion: (() -> Void)?
    ) {
        presentingViewController.present(safariVC, animated: true, completion: completion)
    }

    /// Dismisses the currently presented Safari view controller.
    /// - Parameter completion: Called after dismissal completes
    func dismissSafariViewController(completion: (() -> Void)? = nil) {
        safariViewController?.dismiss(animated: true, completion: completion)
        safariViewController = nil
    }

    // MARK: - Web Authentication Session

    /// Creates and starts an ASWebAuthenticationSession.
    /// - Parameters:
    ///   - url: The URL for authentication
    ///   - presentationContextProvider: The context provider for presentation
    ///   - completionHandler: Called when the session completes
    /// - Returns: The created session
    @discardableResult
    func startWebAuthSession(
        url: URL,
        presentationContextProvider: ASWebAuthenticationPresentationContextProviding,
        completionHandler: @escaping (URL?, Error?) -> Void
    ) -> ASWebAuthenticationSession {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme,
            completionHandler: { [weak self] url, error in
                self?.webAuthSession = nil
                completionHandler(url, error)
            }
        )
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = presentationContextProvider
        self.webAuthSession = session
        session.start()
        return session
    }

    /// Cancels the currently active web authentication session.
    func cancelWebAuthSession() {
        webAuthSession?.cancel()
        webAuthSession = nil
    }

    // MARK: - Cleanup

    /// Cleans up all UI state.
    func cleanup() {
        dismissSafariViewController()
        cancelWebAuthSession()
    }
}

// MARK: - Presentation Validation

extension AuthenticationUIPresenter {

    /// Validates that UI can be presented from the given context.
    /// - Parameters:
    ///   - context: The authentication context
    ///   - error: On return, contains an error if presentation is not possible
    /// - Returns: `true` if presentation is possible, `false` otherwise
    static func canPresent(
        with context: STPAuthenticationContext,
        error: inout NSError?
    ) -> Bool {
        let presentingViewController = context.authenticationPresentingViewController()

        // Check for various presentation issues
        if presentingViewController.view.window == nil {
            error = NSError(
                domain: STPPaymentHandler.errorDomain,
                code: STPPaymentHandlerErrorCode.unexpectedErrorCode.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
                    STPError.errorMessageKey: "authenticationPresentingViewController is not in the window hierarchy. "
                        + "You should probably return the top-most view controller instead.",
                ]
            )
            return false
        }

        if presentingViewController.presentedViewController != nil {
            error = NSError(
                domain: STPPaymentHandler.errorDomain,
                code: STPPaymentHandlerErrorCode.unexpectedErrorCode.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
                    STPError.errorMessageKey: "authenticationPresentingViewController is already presenting. "
                        + "You should probably dismiss the presented view controller in `prepareAuthenticationContextForPresentation`.",
                ]
            )
            return false
        }

        return true
    }
}

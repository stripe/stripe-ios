//
//  ServerDrivenRedirectPresenter.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import AuthenticationServices
import Foundation
import SafariServices
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

/// How the customer was sent to authenticate. Raw values match STPPaymentHandler's `redirect_type` analytics values.
enum ServerDrivenRedirectType: String {
    case webAuthenticationSession = "ASWAS"
    case safariViewController = "SFVC"
    case nativeApp = "native_app"
}

/// How the customer came back. Raw values match STPPaymentHandler's `redirect_type` analytics values.
enum ServerDrivenRedirectReturnType: String {
    /// The ASWebAuthenticationSession finished, either by redirecting to its callback or because the customer closed it.
    case webAuthenticationSession = "ASWAS"
    /// The customer closed the SFSafariViewController.
    case safariViewController = "SFVC"
    /// Something opened the return URL.
    case returnURLCallback = "return_url"
    /// The customer switched back to the app after it opened another app.
    case appForegrounded = "app_foregrounded"
}

enum ServerDrivenRedirectResult {
    /// The customer came back. The intent's status says whether they finished.
    case returned(ServerDrivenRedirectReturnType)
    /// The redirect couldn't be shown, e.g. there's no app for a non-web URL or nothing to present from.
    case failed(Error)
}

/// Sends the customer to a `redirect_to_url` next action and reports when they come back.
protocol ServerDrivenRedirectPresenting {
    @MainActor
    func redirect(
        to url: URL,
        returnURL: URL?,
        useWebAuthSession: Bool,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (ServerDrivenRedirectType) -> Void
    ) async -> ServerDrivenRedirectResult
}

/// A copy of what `STPPaymentHandler._handleRedirect` and its return callbacks do for `redirect_to_url`:
/// open the URL in an app if it's a universal link, otherwise in ASWebAuthenticationSession or SFSafariViewController,
/// then finish on the return URL, the app foregrounding, or the web view closing.
///
/// Deliberately left out (see the spike doc): pre-following redirect trampolines (`followRedirects`),
/// `simulateAppToAppRedirect`, and the polling screen that STPPaymentHandler shows over the web view for some types.
final class ServerDrivenRedirectPresenter: NSObject, ServerDrivenRedirectPresenting {
    private var continuation: CheckedContinuation<ServerDrivenRedirectResult, Never>?
    private var authenticationContext: STPAuthenticationContext?
    private var useWebAuthSession = false
    private var safariViewController: SFSafariViewController?
    private var webAuthenticationSession: ASWebAuthenticationSession?

    @MainActor
    func redirect(
        to url: URL,
        returnURL: URL?,
        useWebAuthSession: Bool,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (ServerDrivenRedirectType) -> Void
    ) async -> ServerDrivenRedirectResult {
        guard continuation == nil else {
            stpAssertionFailure("Redirecting while a redirect is in progress")
            return .failed(ServerDrivenPaymentHandler.error(.noConcurrentActionsErrorCode))
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.authenticationContext = authenticationContext
            self.useWebAuthSession = useWebAuthSession
            if let returnURL {
                STPURLCallbackHandler.shared().register(self, for: returnURL)
            }
            openInApp(url: url, didOpen: didOpen)
        }
    }

    /// Opens a universal link in its app, or a custom-scheme URL. Universal links don't fall back to Safari, so the
    /// customer stays in this app if the app isn't installed.
    private func openInApp(url: URL, didOpen: @escaping (ServerDrivenRedirectType) -> Void) {
        var options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        #if !targetEnvironment(macCatalyst)
        if url.scheme == "http" || url.scheme == "https" {
            options[.universalLinksOnly] = true
        }
        #endif
        UIApplication.shared.open(url, options: options) { [self] opened in
            if opened {
                didOpen(.nativeApp)
                NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            } else {
                presentWebView(url: url, didOpen: didOpen)
            }
        }
    }

    private func presentWebView(url: URL, didOpen: @escaping (ServerDrivenRedirectType) -> Void) {
        guard let context = authenticationContext else { return }
        let present = { [self] in
            guard url.scheme == "http" || url.scheme == "https" else {
                finish(.failed(ServerDrivenPaymentHandler.error(.requiredAppNotAvailable)))
                return
            }
            if let error = Self.presentationError(context) {
                finish(.failed(error))
                return
            }
            if useWebAuthSession {
                // The session also closes if something opens the app's return URL while it's showing.
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "stripesdk") { [self] _, _ in
                    webAuthenticationSession = nil
                    // UIViewController is non-optional in the protocol, so pass a placeholder like STPPaymentHandler does.
                    context.authenticationContextWillDismiss?(UIViewController())
                    context.authenticationContextDidDismiss?(UIViewController())
                    finish(.returned(.webAuthenticationSession))
                }
                session.prefersEphemeralWebBrowserSession = false
                session.presentationContextProvider = self
                webAuthenticationSession = session
                didOpen(.webAuthenticationSession)
                // If the session doesn't start, its completion never runs, so finish here rather than wait forever.
                if !session.start() {
                    webAuthenticationSession = nil
                    finish(.failed(ServerDrivenPaymentHandler.error(.requiresAuthenticationContextErrorCode, loggingSafeErrorMessage: "ASWebAuthenticationSession failed to start")))
                }
            } else {
                let safariViewController = SFSafariViewController(url: url)
                safariViewController.modalPresentationStyle = .overFullScreen
                #if !os(visionOS)
                safariViewController.dismissButtonStyle = .close
                safariViewController.delegate = self
                #endif
                context.configureSafariViewController?(safariViewController)
                self.safariViewController = safariViewController
                didOpen(.safariViewController)
                context.authenticationPresentingViewController().present(safariViewController, animated: true)
            }
        }
        if context.responds(to: #selector(STPAuthenticationContext.prepare(forPresentation:))) {
            context.prepare?(forPresentation: present)
        } else {
            present()
        }
    }

    /// Like `STPPaymentHandler._canPresent`.
    private static func presentationError(_ context: STPAuthenticationContext) -> NSError? {
        if NSClassFromString("XCTest") != nil {
            return nil
        }
        let presentingViewController = context.authenticationPresentingViewController()
        let message: String
        if presentingViewController.viewIfLoaded?.window == nil {
            message = "authenticationPresentingViewController is not in the window hierarchy."
        } else if presentingViewController.presentedViewController != nil {
            message = "authenticationPresentingViewController is already presenting."
        } else {
            return nil
        }
        return ServerDrivenPaymentHandler.error(.requiresAuthenticationContextErrorCode, loggingSafeErrorMessage: message)
    }

    @objc private func willEnterForeground() {
        finish(.returned(.appForegrounded))
    }

    private func finish(_ result: ServerDrivenRedirectResult) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        STPURLCallbackHandler.shared().unregisterListener(self)
        authenticationContext = nil
        continuation?.resume(returning: result)
        continuation = nil
    }
}

extension ServerDrivenRedirectPresenter: STPURLCallbackListener {
    func handleURLCallback(_ url: URL) -> Bool {
        guard !useWebAuthSession else {
            // ASWebAuthenticationSession handles its own return. A return URL opened while it's showing is likely from
            // an app the page sent the customer to, so let the session finish instead.
            return false
        }
        let context = authenticationContext
        if let safariViewController {
            context?.authenticationContextWillDismiss?(safariViewController)
            safariViewController.dismiss(animated: true) {
                context?.authenticationContextDidDismiss?(safariViewController)
            }
            self.safariViewController = nil
        }
        finish(.returned(.returnURLCallback))
        return true
    }
}

#if !os(visionOS)
extension ServerDrivenRedirectPresenter: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        authenticationContext?.authenticationContextWillDismiss?(controller)
        authenticationContext?.authenticationContextDidDismiss?(controller)
        safariViewController = nil
        finish(.returned(.safariViewController))
    }
}
#endif

extension ServerDrivenRedirectPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return authenticationContext?.authenticationPresentingViewController().view.window ?? stp_makeFallbackPresentationAnchor()
    }
}

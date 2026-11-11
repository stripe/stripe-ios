//
//  RedirectNextActionPresenter.swift
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
enum RedirectType: String {
    case webAuthenticationSession = "ASWAS"
    case safariViewController = "SFVC"
    case nativeApp = "native_app"
}

/// How the customer came back. Raw values match STPPaymentHandler's `redirect_type` analytics values.
enum RedirectReturnType: String {
    /// The ASWebAuthenticationSession finished, either by redirecting to its callback or because the customer closed it.
    case webAuthenticationSession = "ASWAS"
    /// The customer closed the SFSafariViewController.
    case safariViewController = "SFVC"
    /// Something opened the return URL.
    case returnURLCallback = "return_url"
    /// The customer switched back to the app after it opened another app.
    case appForegrounded = "app_foregrounded"
}

enum RedirectResult {
    /// The customer came back. The intent's status says whether they finished.
    case returned(RedirectReturnType)
    /// The redirect couldn't be shown, e.g. there's no app for a non-web URL or nothing to present from.
    case failed(Error)
}

/// Sends the customer to a redirect next action and reports when they come back.
@MainActor
protocol RedirectPresenting: AnyObject {
    /// - Parameters:
    ///   - didOpen: Called when the app or web view opens, for analytics.
    ///   - didPresent: Called once the web view is on screen (with it) or the app opened (with nil), like
    ///     STPPaymentHandler's `_handleRedirect` completion. The polling screen goes behind the web view here.
    func redirect(
        _ redirect: ResolvedNextAction.Redirect,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (RedirectType) -> Void,
        didPresent: ((SFSafariViewController?) -> Void)?
    ) async -> RedirectResult

    /// Closes the web view without the customer, e.g. because the polling screen behind it finished the payment.
    /// The pending `redirect` call returns `.returned(.safariViewController)`.
    func close()
}

/// A lean copy of what `STPPaymentHandler._handleRedirect` and its return callbacks do: open the URL as an app,
/// otherwise in ASWebAuthenticationSession or SFSafariViewController, then finish on the return URL, the app
/// foregrounding, or the web view closing.
///
/// Changes to STPPaymentHandler's redirect (consent-domain trampolines, foregrounding vs URL callback order, visionOS)
/// need to be made here too.
final class RedirectNextActionPresenter: NSObject, RedirectPresenting {
    private var continuation: CheckedContinuation<RedirectResult, Never>?
    private var authenticationContext: STPAuthenticationContext?
    private var useWebAuthSession = false
    private var safariViewController: SFSafariViewController?
    private var webAuthenticationSession: ASWebAuthenticationSession?
    /// STPPaymentHandler's testmode `simulateAppToAppRedirect`: open every URL in Safari, as if it were the app.
    private let simulateAppToAppRedirect: Bool

    init(simulateAppToAppRedirect: Bool = false) {
        self.simulateAppToAppRedirect = simulateAppToAppRedirect
    }

    func redirect(
        _ redirect: ResolvedNextAction.Redirect,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (RedirectType) -> Void,
        didPresent: ((SFSafariViewController?) -> Void)?
    ) async -> RedirectResult {
        guard continuation == nil else {
            stpAssertionFailure("Redirecting while a redirect is in progress")
            return .failed(PaymentConfirmer.error(.noConcurrentActionsErrorCode))
        }
        var redirect = redirect
        if redirect.followRedirects, let url = redirect.webURL {
            // STPPaymentHandler follows the trampoline with a semaphore on the main thread; this doesn't block it.
            let followed = await Task.detached { STPPaymentHandler.sharedHandler.followRedirect(to: url) }.value
            redirect.appURL = followed
            redirect.webURL = followed
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.authenticationContext = authenticationContext
            self.useWebAuthSession = redirect.useWebAuthSession
            if let returnURL = redirect.returnURL {
                STPURLCallbackHandler.shared().register(self, for: returnURL)
            }
            open(redirect, didOpen: didOpen, didPresent: didPresent)
        }
    }

    func close() {
        if let safariViewController {
            let context = authenticationContext
            context?.authenticationContextWillDismiss?(safariViewController)
            safariViewController.dismiss(animated: true) {
                context?.authenticationContextDidDismiss?(safariViewController)
            }
            self.safariViewController = nil
        }
        webAuthenticationSession?.cancel()
        webAuthenticationSession = nil
        finish(.returned(.safariViewController))
    }

    /// Opens the app URL: a universal link in its app, or any custom-scheme URL. Universal links don't fall back to
    /// Safari, so the customer stays in this app if the app isn't installed.
    private func open(_ redirect: ResolvedNextAction.Redirect, didOpen: @escaping (RedirectType) -> Void, didPresent: ((SFSafariViewController?) -> Void)?) {
        var options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        var appURL = redirect.appURL
        #if !targetEnvironment(macCatalyst)
        if appURL?.scheme == "http" || appURL?.scheme == "https" {
            options[.universalLinksOnly] = true
        }
        #endif
        if simulateAppToAppRedirect {
            options[.universalLinksOnly] = false
            appURL = appURL ?? redirect.webURL
        }
        guard let appURL else {
            presentWebView(url: redirect.webURL, didOpen: didOpen, didPresent: didPresent)
            return
        }
        UIApplication.shared.open(appURL, options: options) { [self] opened in
            if opened {
                didOpen(.nativeApp)
                didPresent?(nil)
                NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            } else {
                presentWebView(url: redirect.webURL, didOpen: didOpen, didPresent: didPresent)
            }
        }
    }

    private func presentWebView(url: URL?, didOpen: @escaping (RedirectType) -> Void, didPresent: ((SFSafariViewController?) -> Void)?) {
        guard let context = authenticationContext else { return }
        let present = { [self] in
            if let error = Self.presentationError(context) {
                finish(.failed(error))
                return
            }
            guard let url, url.scheme == "http" || url.scheme == "https" else {
                finish(.failed(PaymentConfirmer.error(.requiredAppNotAvailable)))
                return
            }
            if useWebAuthSession {
                // The session also closes if something opens the app's return URL while it's showing.
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "stripesdk") { [self] _, _ in
                    guard webAuthenticationSession != nil else { return }
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
                    finish(.failed(PaymentConfirmer.error(.requiresAuthenticationContextErrorCode, loggingSafeErrorMessage: "ASWebAuthenticationSession failed to start")))
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
                context.authenticationPresentingViewController().present(safariViewController, animated: true) {
                    didPresent?(safariViewController)
                }
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
        return PaymentConfirmer.error(.requiresAuthenticationContextErrorCode, loggingSafeErrorMessage: message)
    }

    @objc private func willEnterForeground() {
        finish(.returned(.appForegrounded))
    }

    private func finish(_ result: RedirectResult) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        STPURLCallbackHandler.shared().unregisterListener(self)
        authenticationContext = nil
        continuation?.resume(returning: result)
        continuation = nil
    }
}

extension RedirectNextActionPresenter: STPURLCallbackListener {
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
extension RedirectNextActionPresenter: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        authenticationContext?.authenticationContextWillDismiss?(controller)
        authenticationContext?.authenticationContextDidDismiss?(controller)
        safariViewController = nil
        finish(.returned(.safariViewController))
    }
}
#endif

extension RedirectNextActionPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return authenticationContext?.authenticationPresentingViewController().view.window ?? stp_makeFallbackPresentationAnchor()
    }
}

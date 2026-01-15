//
//  STPPaymentHandler+Redirect.swift
//  StripePayments
//
//  Extracted from STPPaymentHandler.swift for modularity.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
import Foundation
import SafariServices
@_spi(STP) import StripeCore
import UIKit

// MARK: - URL Redirect Handling

extension STPPaymentHandler {

    // A URLSessionTaskDelegate that can not be redirected by HTTP redirect codes. It is very focused on its task, you see.
    fileprivate class UnredirectableSessionDelegate: NSObject, URLSessionTaskDelegate {
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            // Don't get redirected, just call the completion handler
            completionHandler(nil)
        }
    }

    // Follow the first redirect for a url, but not any subsequent redirects
    @_spi(STP) public func followRedirect(to url: URL) -> URL {
        let urlSession = URLSession(configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration, delegate: UnredirectableSessionDelegate(), delegateQueue: nil)
        let urlRequest = URLRequest(url: url)
        let blockingDataTaskSemaphore = DispatchSemaphore(value: 0)

        var resultingUrl = url
        let task = urlSession.dataTask(with: urlRequest) { _, response, error in
            defer {
                blockingDataTaskSemaphore.signal()
            }

            guard error == nil,
                let httpResponse = response as? HTTPURLResponse,
                (200...308).contains(httpResponse.statusCode),
                  let responseURLString = httpResponse.allHeaderFields["Location"] as? String,
                  let responseURL = URL(string: responseURLString)
            else {
                return
            }
            resultingUrl = responseURL
        }
        task.resume()
        blockingDataTaskSemaphore.wait()
        return resultingUrl
    }

    func _retryAfterDelay(retryCount: Int, delayTime: TimeInterval = 3, block: @escaping STPVoidBlock) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            block()
        }
    }

    /// Retrieves and checks the payment intent status for the current action.
    /// If pollingBudget is nil, this is the first attempt and a new budget is created.
    @objc func _handleWillForegroundNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        STPURLCallbackHandler.shared().unregisterListener(self)
        logURLRedirectNextActionFinished(returnType: .appForegrounded)
        _retrieveAndCheckIntentForCurrentAction()
    }

    @_spi(STP) public func _handleRedirect(to url: URL, withReturn returnURL: URL?, useWebAuthSession: Bool) {
        _handleRedirect(to: url, fallbackURL: url, return: returnURL, useWebAuthSession: useWebAuthSession)
    }

    /// Handles redirection to URLs using a native URL or a fallback URL and updates the current action.
    /// Redirects to an app if possible, if that fails opens the url in a web view
    /// - Parameters:
    ///     - nativeURL: A URL to be opened natively.
    ///     - fallbackURL: A secondary URL to be attempted if the native URL is not available.
    ///     - returnURL: The URL to be registered with the `STPURLCallbackHandler`.
    ///     - useWebAuthSession: Use ASWebAuthenticationSession instead of SFSafariViewController.
    ///     - completion: A completion block invoked after the URL redirection is handled. The SFSafariViewController used is provided as an argument, if it was used for the redirect.
    func _handleRedirect(to nativeURL: URL?, fallbackURL: URL?, return returnURL: URL?, useWebAuthSession: Bool, completion: ((SFSafariViewController?) -> Void)? = nil) {
        if let _redirectShim, let url = nativeURL ?? fallbackURL {
            _redirectShim(url, returnURL, true)
        }

        // During testing, the completion block is not called since the `UIApplication.open` completion block is never invoked.
        // As a workaround we invoke the completion in a defer block if the _redirectShim is not nil to simulate presenting a web view
        defer {
            if _redirectShim != nil {
                completion?(nil)
            }
        }

        var url = nativeURL
        guard let currentAction else {
            stpAssertionFailure("Calling _handleRedirect without a currentAction")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentHandlerError, error: InternalError.invalidState, additionalNonPIIParams: ["error_message": "Calling _handleRedirect without a currentAction"])
            analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
            return
        }
        if let returnURL {
            STPURLCallbackHandler.shared().register(self, for: returnURL)
        }

        // Open the link in SafariVC
        let presentSFViewControllerBlock: (() -> Void) = {
            let context = currentAction.authenticationContext

            let presentingViewController = context.authenticationPresentingViewController()

            let doChallenge: STPVoidBlock = {
                var presentationError: NSError?
                guard self._canPresent(with: context, error: &presentationError) else {
                    currentAction.complete(
                        with: STPPaymentHandlerActionStatus.failed,
                        error: presentationError
                    )
                    return
                }

                if let fallbackURL,
                    ["http", "https"].contains(fallbackURL.scheme)
                {
                    if useWebAuthSession {
                        if self._redirectShim != nil {
                            // No-op if the redirect shim is active, as we don't want to open the consent dialog. We'll call the completion block automatically.
                            return
                        }
                        self.logURLRedirectNextActionStarted(redirectType: .ASWebAuthenticationSession)
                        // Note that ASWebAuthenticationSession will also close based on the `redirectURL` defined in the app's Info.plist if called within the ASWAS,
                        // not only via this callbackURLScheme.
                        let asWebAuthenticationSession = ASWebAuthenticationSession(url: fallbackURL, callbackURLScheme: "stripesdk", completionHandler: { _, _ in
                            if context.responds(
                                to: #selector(STPAuthenticationContext.authenticationContextWillDismiss(_:))
                            ) {
                                // This isn't great, but UIViewController is non-nil in the protocol. Maybe it's better to still call it, even if the VC isn't useful?
                                context.authenticationContextWillDismiss?(UIViewController())
                            }
                            // This isn't great, but UIViewController is non-nil in the protocol. Maybe it's better to still call it, even if the VC isn't useful?
                            self.callContextDidDismissIfNeeded(context, UIViewController())
                            STPURLCallbackHandler.shared().unregisterListener(self)
                            self.logURLRedirectNextActionFinished(returnType: .ASWebAuthenticationSession)
                            self._retrieveAndCheckIntentForCurrentAction()
                            self.asWebAuthenticationSession = nil
                        })
                        asWebAuthenticationSession.prefersEphemeralWebBrowserSession = false
                        asWebAuthenticationSession.presentationContextProvider = currentAction
                        self.asWebAuthenticationSession = asWebAuthenticationSession
                        if context.responds(to: #selector(STPAuthenticationContext.prepare(forPresentation:))) {
                            context.prepare?(forPresentation: {
                                asWebAuthenticationSession.start()
                            })
                        } else {
                            asWebAuthenticationSession.start()
                        }
                    } else {
                        self.logURLRedirectNextActionStarted(redirectType: .SFSafariViewController)
                        let safariViewController = SFSafariViewController(url: fallbackURL)
                        safariViewController.modalPresentationStyle = .overFullScreen
#if !os(visionOS)
                        safariViewController.dismissButtonStyle = .close
                        safariViewController.delegate = self
#endif
                        if context.responds(
                            to: #selector(STPAuthenticationContext.configureSafariViewController(_:))
                        ) {
                            context.configureSafariViewController?(safariViewController)
                        }
                        self.safariViewController = safariViewController
                        presentingViewController.present(safariViewController, animated: true, completion: {
                            completion?(safariViewController)
                        })
                    }
                } else {
                    currentAction.complete(
                        with: STPPaymentHandlerActionStatus.failed,
                        error: self._error(for: .requiredAppNotAvailable)
                    )
                }
            }
            if context.responds(to: #selector(STPAuthenticationContext.prepare(forPresentation:))) {
                context.prepare?(forPresentation: doChallenge)
            } else {
                doChallenge()
            }
        }

        // Redirect to an app
        // We don't want universal links to open up Safari, but we do want to allow custom URL schemes
        var options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        #if !targetEnvironment(macCatalyst)
        if let scheme = url?.scheme, scheme == "http" || scheme == "https" {
            options[UIApplication.OpenExternalURLOptionsKey.universalLinksOnly] = true
        }
        #endif

        // If we're simulating app-to-app redirects, we always want to open the URL in Safari instead of an in-app web view.
        // We'll tell Safari to open all URLs, not just universal links.
        // If we don't have a nativeURL, we should open the fallbackURL in Safari instead.
        if simulateAppToAppRedirect {
            options[UIApplication.OpenExternalURLOptionsKey.universalLinksOnly] = false
            url = nativeURL ?? fallbackURL
        }

        // We don't check canOpenURL before opening the URL because that requires users to pre-register the custom URL schemes
        if let url = url {
            UIApplication.shared.open(
                url,
                options: options,
                completionHandler: { success in
                    if !success {
                        // no app installed, launch safari view controller
                        presentSFViewControllerBlock()
                    } else {
                        self.logURLRedirectNextActionStarted(redirectType: .nativeApp)
                        completion?(nil)
                        NotificationCenter.default.addObserver(
                            self,
                            selector: #selector(self._handleWillForegroundNotification),
                            name: UIApplication.willEnterForegroundNotification,
                            object: nil
                        )
                    }
                }
            )
        } else {
            presentSFViewControllerBlock()
        }
    }
}

// MARK: - SFSafariViewControllerDelegate

#if !os(visionOS)
extension STPPaymentHandler: SFSafariViewControllerDelegate {
    /// :nodoc:
    @objc
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        let context = currentAction?.authenticationContext
        if context?.responds(
            to: #selector(STPAuthenticationContext.authenticationContextWillDismiss(_:))
        ) ?? false {
            context?.authenticationContextWillDismiss?(controller)
        }

        callContextDidDismissIfNeeded(context, controller)

        safariViewController = nil
        STPURLCallbackHandler.shared().unregisterListener(self)
        logURLRedirectNextActionFinished(returnType: .SFSafariViewController)
        _retrieveAndCheckIntentForCurrentAction()
    }
}
#endif

// MARK: - STPURLCallbackListener

/// :nodoc:
@_spi(STP) extension STPPaymentHandler: STPURLCallbackListener {
    /// :nodoc:
    @_spi(STP) public func handleURLCallback(_ url: URL) -> Bool {
        if currentAction?.nextAction()?.redirectToURL?.useWebAuthSession ?? false {
            // Don't handle the URL — If a user clicks the URL in ASWebAuthenticationSession, ASWebAuthenticationSession will handle it internally.
            // If we're returning from another app via a URL while ASWebAuthenticationSession is open, it's likely that the PM initiated a redirect to another app
            // (such as a banking app) and is waiting for a response from that app.
            return false
        }
        logURLRedirectNextActionFinished(returnType: .returnURLCallback)
        // Note: At least my iOS 15 device, willEnterForegroundNotification is triggered before this method when returning from another app, which means this method isn't called because it unregisters from STPURLCallbackHandler.
        let context = currentAction?.authenticationContext
        if context?.responds(
            to: #selector(STPAuthenticationContext.authenticationContextWillDismiss(_:))
        ) ?? false,
            let safariViewController = safariViewController
        {
            context?.authenticationContextWillDismiss?(safariViewController)
        }

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        STPURLCallbackHandler.shared().unregisterListener(self)
        safariViewController?.dismiss(animated: true) {
            self.callContextDidDismissIfNeeded(context, self.safariViewController)
            self.safariViewController = nil
        }
        _retrieveAndCheckIntentForCurrentAction()
        return true
    }
}

// MARK: - PaymentSheetAuthenticationContext

/// Internal authentication context for PaymentSheet magic
@_spi(STP) public protocol PaymentSheetAuthenticationContext: STPAuthenticationContext {
    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void)
    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?)
    func presentPollingVCForAction(action: STPPaymentHandlerPaymentIntentActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?)
}

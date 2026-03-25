//
//  WebViewViewController.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 9/15/23.
//

import AuthenticationServices
import Foundation
import SafariServices
import SwiftUI
import UIKit
import WebKit

// ======================
// SUMMARY:
// ======================
// Handling Financial Connections Auth Flow in an embedded
// webview (ex. `WKWebView`) requires special code because
// bank OAuth flow presents a pop-up which is not handled
// by WKWebView.
//
// There are two ways around this:
// 1. Don't use `WKWebView`. Instead, use the Mobile SDK, which
//    handles everything for you. This is the recommended solution.
// 2. Write custom code to handle this edge-case (which is what this example shows).
//
//
//
// Steps:
// 1. Create a Financial Connections session while also providing a `return_url` parameter.
//    (ex. `stripe.financialConnections.sessions.create`).
//
//    The `return_url` should be a link to your website. In this example code,
//    the `return_url` is `https://connections-webview-example.stripedemos.com/redirect`.
//
// 2. Add client code (shown below) that will open an extra browser that
//    will handle the bank OAuth pop-up.
//
// 3. Handle app-to-app authentication flows by attempting to open new-window
//    URLs as universal links. This is done via `UIApplication.shared.open`
//    and passing `[.universalLinksOnly: true]` as the `options`.
//
// 4. When Financial Connections calls the `return_url`, your website code
//    should redirect to a custom URL. In this example code, the redirect URL
//    is `zzz-custom://open/customtab_return`.
//
// 5. Dismiss the extra browser to return back to your `WKWebView`.
//    This is done automatically when using `ASWebAuthenticationSession`.

/// The website that presents the Financial Connections Auth Flow.
private let websiteURL = URL(string: "https://connections-webview-example.stripedemos.com/")!

// ======================
// IMPORTANT NOTE:
// ======================
// This redirect URL comes from your website.
//
// Here is example code using `express` of listening
private let redirectURL = URL(string: "zzz-custom://open/customtab_return")!

@available(iOS 14.0, *)
final class WebViewViewController: UIViewController {

    private var webAuthenticationSession: ASWebAuthenticationSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        let webView = WKWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration()
        )
        let request = URLRequest(url: websiteURL)
        webView.load(request)

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // ======================
        // IMPORTANT NOTE:
        // ======================
        // If you comment the line below, and press "Test OAuth Institution"
        // while going through the test-mode flow, you will notice that
        // nothing happens. This is because `WKWebView` does not automatically
        // handle OAuth pop-ups. That's why the `return_url` parameter is necessary.
        webView.uiDelegate = self
    }
}

@available(iOS 14.0, *)
extension WebViewViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Check if the link is attempting to open in a new window.
        // This is typically the case for a banking partner's authentication flow.
        let isAttemptingToOpenLinkInNewWindow = navigationAction.targetFrame?.isMainFrame != true

        if isAttemptingToOpenLinkInNewWindow, let url = navigationAction.request.url {
            // Attempt to open the URL as a universal link.
            // Universal links allow apps on the device to handle specific URLs directly.
            UIApplication.shared.open(
                url,
                options: [.universalLinksOnly: true],
                completionHandler: { [weak self] success in
                    guard let self else { return }
                    if success {
                        // App-to-app flow:
                        // The URL was successfully opened in a banking application that supports universal links.
                        print("Successfully opened the authentication URL in a bank app: \(url)")
                    } else {
                        // Fallback for when no compatible bank app is found:
                        // Create an `ASWebAuthenticationSession` to handle the authentication in a secure in-app browser
                        self.launchInSecureBrowser(url: url)
                    }
                })
        }
        return nil
    }

    private func launchInSecureBrowser(url: URL) {
        let webAuthenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: redirectURL.scheme,
            completionHandler: { redirectURL, error in
                if let error {
                    if
                        (error as NSError).domain == ASWebAuthenticationSessionErrorDomain,
                        (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue
                    {
                        print("User manually closed the browser by pressing 'Cancel' at the top-left corner.")
                    } else {
                        print("Received an error from ASWebAuthenticationSession: \(error)")
                    }
                } else {
                    // ======================
                    // IMPORTANT NOTE:
                    // ======================
                    // The browser will automatically close when
                    // the `callbackURLScheme` is called.
                    print("Received a redirect URL: \(redirectURL?.absoluteString ?? "null")")
                }
            }
        )
        self.webAuthenticationSession = webAuthenticationSession
        webAuthenticationSession.presentationContextProvider = self
        webAuthenticationSession.prefersEphemeralWebBrowserSession = true // disable the initial Apple alert
        webAuthenticationSession.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

@available(iOS 14.0, *)
extension WebViewViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}

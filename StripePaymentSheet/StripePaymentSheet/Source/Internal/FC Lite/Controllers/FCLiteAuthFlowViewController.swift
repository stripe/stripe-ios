//
//  FCLiteAuthFlowViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import AuthenticationServices
import UIKit
// `@preconcurrency` suppresses Sendable-related warnings from WebKit.
@_spi(STP) import StripeCore
@preconcurrency import WebKit

class FCLiteAuthFlowViewController: UIViewController {
    enum WebFlowResult {
        enum CancellationType {
            case cancelledWithinWebview
            case cancelledOutsideWebView
        }

        case success(returnUrl: URL)
        case cancelled(CancellationType)
        case failure(Error)
    }

    private let manifest: LinkAccountSessionManifest
    private let elementsSessionContext: ElementsSessionContext?
    private let returnUrl: URL?
    private let onLoad: () -> Void
    private let completion: ((WebFlowResult) -> Void)

    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var webView: WKWebView!

    private var hostedAuthUrl: URL {
        HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: manifest.hostedAuthURL,
            isInstantDebits: manifest.isInstantDebits,
            elementsSessionContext: elementsSessionContext
        )
    }

    init(
        manifest: LinkAccountSessionManifest,
        elementsSessionContext: ElementsSessionContext?,
        returnUrl: URL?,
        onLoad: @escaping () -> Void,
        completion: @escaping ((WebFlowResult) -> Void)
    ) {
        self.onLoad = onLoad
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
        setupWebView()
    }

    private func setupWebView() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.uiDelegate = self
        webView.isHidden = true
        webView.navigationDelegate = self

        #if DEBUG
        // Allow the web view to be inspected for debug builds on 16.4+
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        let request = URLRequest(url: hostedAuthUrl)
        webView.load(request)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func didFinishLoad() {
        onLoad()
        webView.isHidden = false
    }
}

// MARK: WKNavigationDelegate
extension FCLiteAuthFlowViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            return
        }

        // `matchesSchemeHostAndPath` is necessary for instant debits which
        // contains additional query parameters at the end of the `successUrl`.
        if url.matchesSchemeHostAndPath(of: manifest.successURL) {
            decisionHandler(.cancel)
            completion(.success(returnUrl: url))
        } else if url.matchesSchemeHostAndPath(of: manifest.cancelURL) {
            decisionHandler(.cancel)
            completion(.cancelled(.cancelledWithinWebview))
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishLoad()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFinishLoad()
        completion(.failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        didFinishLoad()
        completion(.failure(error))
    }
}

// MARK: WKUIDelegate
extension FCLiteAuthFlowViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            return nil
        }

        // Check if the link is attempting to open in a new window.
        // This is typically the case for a banking partner's authentication flow.
        let isAttemptingToOpenLinkInNewWindow = navigationAction.targetFrame?.isMainFrame != true
        guard isAttemptingToOpenLinkInNewWindow else {
            return nil
        }

        // If a return URL isn't provided, we don't support app-to-app.
        // Instead, handle authentication in a secure in-app browser.
        guard returnUrl != nil else {
            launchInSecureBrowser(url: url)
            return nil
        }

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
                } else {
                    // Fallback for when no compatible bank app is found:
                    // Create an `ASWebAuthenticationSession` to handle the authentication in a secure in-app browser.
                    self.launchInSecureBrowser(url: url)
                }
            }
        )
        return nil
    }

    private func launchInSecureBrowser(url: URL) {
        let authRedirectUrl = URL(string: "stripe://financial-connections-lite/auth_redirect")!
        let webAuthenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: authRedirectUrl.scheme,
            completionHandler: { _, _ in
                // Any outcome of this auth session will be automatically handled by our web flow.
                // The browser window will automatically close when a redirect to the `callbackURLScheme` is detected.
            }
        )
        self.webAuthenticationSession = webAuthenticationSession
        webAuthenticationSession.presentationContextProvider = self
        webAuthenticationSession.prefersEphemeralWebBrowserSession = true // disable the initial Apple alert
        webAuthenticationSession.start()
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding
extension FCLiteAuthFlowViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}

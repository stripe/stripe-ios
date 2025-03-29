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
        case success(returnUrl: URL)
        case cancelled
        case failure(Error)
    }

    private let manifest: LinkAccountSessionManifest
    private let elementsSessionContext: ElementsSessionContext?
    private let returnUrl: URL?
    private let completion: ((WebFlowResult) -> Void)

    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var webView: WKWebView!

    private var progressObservation: NSKeyValueObservation?
    private let progressBar = UIProgressView(progressViewStyle: .bar)

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
        completion: @escaping ((WebFlowResult) -> Void)
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
        setupProgressBar()
        setupWebView()
    }

    private func setupWebView() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.uiDelegate = self
        webView.navigationDelegate = self

        observeWebviewLoadingProgress()

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

    // MARK: Progress bar
    private func setupProgressBar() {
        let color = manifest.isInstantDebits ? FCLiteColor.link : FCLiteColor.stripe
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.trackTintColor = .lightGray
        progressBar.progressTintColor = color
        progressBar.progress = 0.0
    }

    private func showProgressBar() {
        guard progressBar.superview == nil else { return }
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2.0),
        ])
    }

    private func hideProgressBar() {
        UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
            self.progressBar.alpha = 0.0
        }, completion: { _ in
            self.progressBar.removeFromSuperview()
        })
    }

    private func observeWebviewLoadingProgress() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            guard let self else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let progress = Float(self.webView.estimatedProgress)
                self.progressBar.progress = progress
                if progress >= 1.0 {
                    self.hideProgressBar()
                }
            }
        }
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
            completion(.cancelled)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showProgressBar()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideProgressBar()
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

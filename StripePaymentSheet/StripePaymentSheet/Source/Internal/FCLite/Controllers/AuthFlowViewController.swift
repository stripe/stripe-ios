//
//  AuthFlowViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

import AuthenticationServices
import UIKit
@preconcurrency import WebKit

class AuthFlowViewController: UIViewController {
    enum WebFlowResult {
        case success(returnUrl: URL)
        case cancelled
        case failure(Error)
    }

    private let manifest: LinkAccountSessionManifest
    private let returnUrl: URL
    private let completion: ((WebFlowResult) -> Void)

    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var webView: WKWebView!

    private var progressObservation: NSKeyValueObservation?
    private let progressBar = UIProgressView(progressViewStyle: .bar)

    init(
        manifest: LinkAccountSessionManifest,
        returnUrl: URL,
        completion: @escaping ((WebFlowResult) -> Void)
    ) {
        self.manifest = manifest
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

    private func setupWebView() {
        webView = WKWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration()
        )

        webView.uiDelegate = self
        webView.navigationDelegate = self

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            guard let self else { return }

            DispatchQueue.main.async {
                self.showProgressBar()
                self.progressBar.progress = Float(self.webView.estimatedProgress)
                if self.webView.estimatedProgress >= 1.0 {
                    self.hideProgressBar()
                }
            }
        }

        let url = hostedAuthUrl(from: manifest)
        let request = URLRequest(url: url)
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
}

extension AuthFlowViewController: WKNavigationDelegate {
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
        progressBar.removeFromSuperview()
        completion(.failure(error))
    }
}

extension AuthFlowViewController: WKUIDelegate {
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
        let redirectUrl = URL(string: "stripe://financial-connections-lite/auth_redirect")!
        let webAuthenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: redirectUrl.scheme,
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

extension AuthFlowViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}

private extension URL {
    func matchesSchemeHostAndPath(of otherURL: URL) -> Bool {
        return (
            self.scheme == otherURL.scheme &&
            self.host == otherURL.host &&
            self.path == otherURL.path
        )
    }
}

private extension AuthFlowViewController {
    func hostedAuthUrl(from manifest: LinkAccountSessionManifest) -> URL {
        guard manifest.isInstantDebits else {
            return manifest.hostedAuthURL
        }

        let additionalParameters: [String] = [
            "return_payment_method=true",
            "expand_payment_method=true",
        ]
        let urlString = manifest.hostedAuthURL.absoluteString
        let joinedParameters = additionalParameters.joined(separator: "&")
        let updatedUrlString = urlString + (urlString.hasSuffix("&") ? "" : "&") + joinedParameters
        return URL(string: updatedUrlString) ?? manifest.hostedAuthURL
    }
}

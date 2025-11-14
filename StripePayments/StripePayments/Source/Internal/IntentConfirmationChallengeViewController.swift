//
//  IntentConfirmationChallengeViewController.swift
//  StripePayments
//
//  Created by Joyce Qin on 11/4/25.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit
@preconcurrency import WebKit

/// View controller for handling intent confirmation challenges via WebView
/// This handles the `intent_confirmation_challenge` next action type by loading
/// a Stripe-hosted web page that performs authentication via Stripe.js
@available(iOS 14.0, *)
class IntentConfirmationChallengeViewController: UIViewController {

    // MARK: - Properties
    private let apiClient: STPAPIClient
    private let clientSecret: String
    private let completion: (Result<Void, Error>) -> Void

    private var webView: WKWebView!
    private var dimmedBackgroundView: UIView!

    // Hard-coded challenge URL
    private let challengeURL = URL(string: "https://mobile-active-challenge-764603794666.us-central1.run.app/")!

    // MARK: - Initialization
    init(
        apiClient: STPAPIClient,
        clientSecret: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        setupDimmedBackground()
        setupWebView()
        loadChallenge()
    }

    // MARK: - Setup
    private func setupDimmedBackground() {
        dimmedBackgroundView = UIView()
        dimmedBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        dimmedBackgroundView.alpha = 0 // Initially hidden

        view.addSubview(dimmedBackgroundView)

        NSLayoutConstraint.activate([
            dimmedBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Setup message handlers
        let contentController = WKUserContentController()
        contentController.add(self, name: "getInitParams")
        contentController.add(self, name: "onReady")
        contentController.add(self, name: "onSuccess")
        contentController.add(self, name: "onError")

        configuration.userContentController = contentController

        // Inject bridge scripts
        injectBridgeScripts(into: contentController)

        // Create WebView
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        // Make webview transparent
        webView.isOpaque = false
        webView.alpha = 0

        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func injectBridgeScripts(into contentController: WKUserContentController) {
        // CRITICAL: Set initParams BEFORE page loads so it's available immediately
        // The web page expects window.initParams to be set via window.setInitParams()
        let initParamsScript = """
        window.setInitParams = function(params) {
            window.initParams = params;
        };
        window.setInitParams({
            clientSecret: "\(clientSecret)",
            publishableKey: "\(apiClient.publishableKey ?? "")"
        });
        """

        // Inject at document start (BEFORE the page's scripts run)
        let startScript = WKUserScript(
            source: initParamsScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        contentController.addUserScript(startScript)
    }

    private func loadChallenge() {
        let request = URLRequest(url: challengeURL)
        webView.load(request)
    }

    // MARK: - Handlers
    private func handleReady() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7) {
                self.dimmedBackgroundView.alpha = 1.0
                self.webView.alpha = 1.0
            }
        }
    }

    private func handleSuccess() {
        completion(.success(()))
    }

    private func handleError(_ error: Error) {
        #if DEBUG
        print("[IntentConfirmationChallenge] Error: \(error)")
        #endif

        completion(.failure(error))
    }

    /// Validates that the message comes from the expected Stripe origin
    private func isValidMessageOrigin(_ message: WKScriptMessage) -> Bool {
        let validHosts = ["pay.stripe.com", "js.stripe.com", "mobile-active-challenge-764603794666.us-central1.run.app"]
        let host = message.frameInfo.securityOrigin.host
        return validHosts.contains(host)
    }
}

// MARK: - WKScriptMessageHandler
@available(iOS 14.0, *)
extension IntentConfirmationChallengeViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Validate message origin for security
        guard isValidMessageOrigin(message) else {
            #if DEBUG
            print("[IntentConfirmationChallenge] ⚠️ Invalid message origin: \(message.frameInfo.securityOrigin.host)")
            #endif
            return
        }

        switch message.name {
        case "getInitParams":
            // This shouldn't be called since we inject params, but handle it anyway
            #if DEBUG
            print("[IntentConfirmationChallenge] getInitParams called (params already injected)")
            #endif

        case "onReady":
            #if DEBUG
            print("[IntentConfirmationChallenge] ✅ Ready")
            #endif
            handleReady()

        case "onSuccess":
            #if DEBUG
            print("[IntentConfirmationChallenge] ✅ Success: \(message.body)")
            #endif
            handleSuccess()

        case "onError":
            if let errorDict = message.body as? [String: Any],
               let errorMessage = errorDict["message"] as? String {
                let errorType = errorDict["type"] as? String ?? "unknown"
                let errorCode = errorDict["code"] as? String
                handleError(ChallengeError.webError(message: errorMessage, type: errorType, code: errorCode))
            } else {
                handleError(ChallengeError.unknownError)
            }

        default:
            #if DEBUG
            print("[IntentConfirmationChallenge] Unknown message: \(message.name)")
            #endif
        }
    }

}

// MARK: - WKNavigationDelegate
@available(iOS 14.0, *)
extension IntentConfirmationChallengeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(ChallengeError.navigationFailed(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(ChallengeError.navigationFailed(error))
    }
}

// MARK: - Errors
enum ChallengeError: LocalizedError {
    case webError(message: String, type: String, code: String?)
    case navigationFailed(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .webError(let message, _, _):
            return message
        case .navigationFailed(let error):
            return "Navigation failed: \(error.localizedDescription)"
        case .unknownError:
            return "Unknown error."
        }
    }
}

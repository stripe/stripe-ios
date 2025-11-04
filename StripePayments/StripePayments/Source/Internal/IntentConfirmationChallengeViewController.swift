//
//  IntentConfirmationChallengeViewController.swift
//  StripePayments
//
//  Created by Joyce Qin on 11/4/25.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit
import WebKit

/// View controller for handling intent confirmation challenges via WebView
/// This handles the `intent_confirmation_challenge` next action type by loading
/// a Stripe-hosted web page that performs authentication via Stripe.js
class IntentConfirmationChallengeViewController: UIViewController {

    // MARK: - Properties
    private let apiClient: STPAPIClient
    private let clientSecret: String
    private let completion: (Result<Void, Error>) -> Void

    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!

    // Hard-coded challenge URL
    private let challengeURL = URL(string: "http://localhost:3004")!

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

        view.backgroundColor = .systemBackground

        setupActivityIndicator()
        setupWebView()
        setupConstraints()

        loadChallenge()
    }

    // MARK: - Setup
    private func setupActivityIndicator() {
//        activityIndicator = UIActivityIndicatorView(style: .large)
//        activityIndicator.color = .systemGray
//        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//        activityIndicator.startAnimating()
//        view.addSubview(activityIndicator)
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()

        // Enable JavaScript (required for Stripe.js)
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            // Fallback on earlier versions
        }

        // Setup message handlers
        let contentController = WKUserContentController()
        contentController.add(self, name: "getInitParams")
        contentController.add(self, name: "onReady")
        contentController.add(self, name: "onSuccess")
        contentController.add(self, name: "onError")
        contentController.add(self, name: "consoleLog")

        configuration.userContentController = contentController

        // Inject bridge scripts
        injectBridgeScripts(into: contentController)

        // Create WebView
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        // Safari user agent (prevents mobile web restrictions)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1"

        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        view.addSubview(webView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

//            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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

        // Console interceptor for debugging
        let consoleInterceptor = """
        (function() {
            ['log', 'error', 'warn', 'info', 'debug'].forEach(method => {
                const original = console[method];
                console[method] = function(...args) {
                    original.apply(console, args);
                    try {
                        window.webkit.messageHandlers.consoleLog.postMessage({
                            level: method,
                            message: args.map(arg => {
                                if (typeof arg === 'object') {
                                    try { return JSON.stringify(arg); }
                                    catch(e) { return String(arg); }
                                }
                                return String(arg);
                            }).join(' ')
                        });
                    } catch(e) {}
                };
            });
        })();
        """

        // Inject at document start (BEFORE the page's scripts run)
        let startScript = WKUserScript(
            source: initParamsScript + "\n" + consoleInterceptor,
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
            UIView.animate(withDuration: 0.3) {
//                self.activityIndicator.alpha = 0.0
                self.webView.alpha = 1.0
            } completion: { _ in
//                self.activityIndicator.stopAnimating()
            }
        }
    }

    private func handleSuccess(_ result: Any?) {
        #if DEBUG
        if let result = result {
            print("[IntentConfirmationChallenge] Success: \(result)")
        }
        #endif

        completion(.success(()))
    }

    private func handleError(_ error: Error) {
        #if DEBUG
        print("[IntentConfirmationChallenge] Error: \(error)")
        #endif

        completion(.failure(error))
    }

    // MARK: - Security
    private func isValidMessageOrigin(_ message: WKScriptMessage) -> Bool {
        let validHosts = ["pay.stripe.com", "js.stripe.com", "localhost"]
        let host = message.frameInfo.securityOrigin.host
        return validHosts.contains(host)
    }
}

// MARK: - WKScriptMessageHandler
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
            handleSuccess(message.body)

        case "onError":
            if let errorDict = message.body as? [String: Any],
               let errorMessage = errorDict["message"] as? String {
                let errorType = errorDict["type"] as? String ?? "unknown"
                let errorCode = errorDict["code"] as? String
                #if DEBUG
                print("[IntentConfirmationChallenge] ❌ Error: type=\(errorType), message=\(errorMessage), code=\(errorCode ?? "none")")
                #endif
                handleError(ChallengeError.webError(message: errorMessage, type: errorType, code: errorCode))
            } else {
                #if DEBUG
                print("[IntentConfirmationChallenge] ❌ Error: \(message.body)")
                #endif
                handleError(ChallengeError.unknownError)
            }

        case "consoleLog":
            #if DEBUG
            if let logDict = message.body as? [String: Any],
               let level = logDict["level"] as? String,
               let logMessage = logDict["message"] as? String {
                let emoji = logEmojiForLevel(level)
                print("[IntentConfirmationChallenge][\(emoji)] \(logMessage)")
            }
            #endif

        default:
            #if DEBUG
            print("[IntentConfirmationChallenge] Unknown message: \(message.name)")
            #endif
        }
    }

    private func logEmojiForLevel(_ level: String) -> String {
        switch level.lowercased() {
        case "error": return "❌"
        case "warn": return "⚠️"
        case "info": return "ℹ️"
        case "debug": return "🐛"
        case "log": return "📝"
        default: return "💬"
        }
    }
}

// MARK: - WKNavigationDelegate
extension IntentConfirmationChallengeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(ChallengeError.navigationFailed(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(ChallengeError.navigationFailed(error))
    }
}

// MARK: - WKUIDelegate
extension IntentConfirmationChallengeViewController: WKUIDelegate {
    // Handle JavaScript alerts if needed
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
}

// MARK: - Errors
enum ChallengeError: LocalizedError {
    case invalidURL
    case invalidOrigin
    case webError(message: String, type: String, code: String?)
    case navigationFailed(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for intent confirmation challenge"
        case .invalidOrigin:
            return "Received message from invalid origin"
        case .webError(let message, _, _):
            return message
        case .navigationFailed(let error):
            return "Navigation failed: \(error.localizedDescription)"
        case .unknownError:
            return NSError.stp_unexpectedErrorMessage()
        }
    }
}

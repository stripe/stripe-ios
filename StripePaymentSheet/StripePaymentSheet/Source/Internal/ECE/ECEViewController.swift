//
//  ECEViewController.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
@preconcurrency import WebKit

// Protocol for handling Express Checkout Element events
@available(iOS 16.0, *)
protocol ExpressCheckoutWebviewDelegate: AnyObject {
    func amountForECEView(_ eceView: ECEViewController) -> Int
    func eceView(_ eceView: ECEViewController, didReceiveShippingAddressChange shippingAddress: [String: Any]) async throws -> [String: Any]
    func eceView(_ eceView: ECEViewController, didReceiveShippingRateChange shippingRate: [String: Any]) async throws -> [String: Any]
    func eceView(_ eceView: ECEViewController, didReceiveECEClick event: [String: Any]) async throws -> [String: Any]
    func eceView(_ eceView: ECEViewController, didReceiveECEConfirmation paymentDetails: [String: Any]) async throws -> [String: Any]
}

protocol ECEViewControllerDelegate: AnyObject {
    func didCancel()
}

// Custom errors for Express Checkout operations
enum ExpressCheckoutError: LocalizedError {
    case invalidShippingRate(rateId: String)
    case missingRequiredField(field: String)

    var errorDescription: String? {
        switch self {
        case .invalidShippingRate(let rateId):
            return "Invalid shipping rate: \(rateId)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}

@available(iOS 16.0, *)
class ECEViewController: UIViewController {
    let apiClient: STPAPIClient
    let shopId: String
    let customerSessionClientSecret: String
    private weak var delegate: ECEViewControllerDelegate?

    init(apiClient: STPAPIClient,
         shopId: String,
         customerSessionClientSecret: String,
         delegate: ECEViewControllerDelegate? = nil) {
        self.apiClient = apiClient
        self.shopId = shopId
        self.customerSessionClientSecret = customerSessionClientSecret
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var webView: WKWebView!
    private var popupWebView: WKWebView?

    // Delegate for Express Checkout Element events
    weak var expressCheckoutWebviewDelegate: ExpressCheckoutWebviewDelegate?

    // We normally hide Express Checkout Element in WKWebViews (as many don't handle popups correctly)
    // Fake Safari's UA to disable that behavior
    static let FakeSafariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1"

    override func loadView() {
        // Create main view
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add a loading spinner
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .systemGray
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        setupWebView()

        // Add the tiny 1x1 webview as a hidden subview
        view.addSubview(webView)
        loadECE()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()

        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Setup message handlers for the bridge
        let contentController = WKUserContentController()
        contentController.add(self, name: "ready")
        contentController.add(self, name: "error")
        contentController.add(self, name: "consoleLog")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "calculateShipping")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "calculateShippingRateChange")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "confirmPayment")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "handleECEClick")

        configuration.userContentController = contentController

        // Inject JavaScript to capture messages and set up the bridge
        let bridgeScript = """
        function getStripePublishableKey() {
          return "\(apiClient.publishableKey ?? "")";
        }

        window.NATIVE_AMOUNT_TOTAL = \(expressCheckoutWebviewDelegate?.amountForECEView(self) ?? 0);

        window.NativeStripeECE = {
            handleClick: async function(eventData) {
                return await window.webkit.messageHandlers.handleECEClick.postMessage({
                    eventData: eventData
                });
            },
            calculateShipping: async function(shippingAddress) {
                return await window.webkit.messageHandlers.calculateShipping.postMessage({
                    shippingAddress: shippingAddress
                });
            },
            calculateShippingRateChange: async function(shippingRate) {
                return await window.webkit.messageHandlers.calculateShippingRateChange.postMessage({
                    shippingRate: shippingRate
                });
            },
            confirmPayment: async function(paymentDetails) {
                return await window.webkit.messageHandlers.confirmPayment.postMessage({
                    paymentDetails: paymentDetails
                });
            }
        };

        // Notify that the bridge is ready
        window.webkit.messageHandlers.ready.postMessage({
            type: 'bridgeReady'
        });

        """

        // Intercept console logs
        let consoleInterceptor = """
        (function() {
            const originalConsole = {
                log: console.log,
                error: console.error,
                warn: console.warn,
                info: console.info,
                debug: console.debug
            };

            function formatArgs(args) {
                return Array.from(args).map(arg => {
                    if (typeof arg === 'object') {
                        try {
                            return JSON.stringify(arg, null, 2);
                        } catch (e) {
                            return String(arg);
                        }
                    }
                    return String(arg);
                }).join(' ');
            }

            ['log', 'error', 'warn', 'info', 'debug'].forEach(method => {
                console[method] = function(...args) {
                    originalConsole[method].apply(console, args);
                    try {
                        window.webkit.messageHandlers.consoleLog.postMessage({
                            level: method,
                            message: formatArgs(args),
                            stackTrace: method === 'error' ? (new Error()).stack : undefined
                        });
                    } catch(e) {}
                };
            });
        })();
        """

        let earlyScript = WKUserScript(source: consoleInterceptor, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(earlyScript)

        let script = WKUserScript(source: bridgeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)

        // TODO: It's 500x500 for now for debugging, but set this to 1x1 before release
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        webView.isHidden = false // Should not be hidden, so that we actually render it
        webView.alpha = 0.01 // TODO: Attempt to set to 0.00 if we can get away with it without Safari optimizing it out

        webView.customUserAgent = Self.FakeSafariUserAgent
    }

    private func loadECE() {
        let staticHTML = ECEIndexHTML(shopId: shopId, customerSessionClientSecret: customerSessionClientSecret)
        webView.loadHTMLString(staticHTML.ECEHTML, baseURL: URL(string: "https://pay.stripe.com")!)
    }

    func unloadWebview() {
        popupWebView?.removeFromSuperview()
        popupWebView = nil
        webView?.removeFromSuperview()
        webView = nil
    }

    /// Validates that the message comes from the expected Stripe origin
    private func isValidMessageOrigin(_ message: WKScriptMessage) -> Bool {
        // Only allow messages from pay.stripe.com
        return message.frameInfo.securityOrigin.host == "pay.stripe.com"
    }
}

// MARK: - WKScriptMessageHandler
@available(iOS 16.0, *)
extension ECEViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Validate message origin for security
        guard isValidMessageOrigin(message) else {
            return
        }

        let messageBody = message.body

        switch message.name {
        case "ready":
            log("✅ Bridge Ready")

        case "error":
            log("❌ Bridge Error:")
            if let errorDict = messageBody as? [String: Any] {
                printMessageDetails(errorDict)
            } else {
                log("   Error: \(messageBody)")
            }

        case "consoleLog":
            #if DEBUG
            if let logDict = messageBody as? [String: Any],
               let level = logDict["level"] as? String,
               let logMessage = logDict["message"] as? String {
                let emoji = logEmojiForLevel(level)
                log("\(emoji) JS Console.\(level): \(logMessage)")

                // Optionally print stack trace for errors
                if level == "error", let stackTrace = logDict["stackTrace"] as? String {
                    let lines = stackTrace.split(separator: "\n").prefix(5) // Show first 5 lines of stack
                    for line in lines {
                        log("     \(line)")
                    }
                }
            }
            #else
            // Don't log in release mode, this could contain sensitive info
            break
            #endif

        default:
            log("🔍 Unknown message type '\(message.name)': \(messageBody)")
        }
    }

    private func printMessageDetails(_ messageDict: [String: Any]) {
        for (key, value) in messageDict.sorted(by: { $0.key < $1.key }) {
            if let nestedDict = value as? [String: Any] {
                log("   \(key):")
                for (nestedKey, nestedValue) in nestedDict.sorted(by: { $0.key < $1.key }) {
                    if let stringValue = nestedValue as? String, stringValue.count > 200 {
                        log("     \(nestedKey): \(String(stringValue.prefix(200)))...")
                    } else {
                        log("     \(nestedKey): \(nestedValue)")
                    }
                }
            } else if let array = value as? [Any] {
                log("   \(key): [\(array.count) items]")
                if array.count <= 5 {
                    for (index, item) in array.enumerated() {
                        log("     [\(index)]: \(item)")
                    }
                }
            } else if let stringValue = value as? String, stringValue.count > 200 {
                log("   \(key): \(String(stringValue.prefix(200)))...")
            } else {
                log("   \(key): \(value)")
            }
        }
    }

    private func logEmojiForLevel(_ level: String) -> String {
        switch level.lowercased() {
        case "error": return "❌"
        case "warn": return "⚠️"
        case "info": return "ℹ️"
        case "debug": return "🐛"
        case "log": return "📝"
        default: return "��"
        }
    }
}

struct BridgeError: LocalizedError {
    var description: String

    var errorDescription: String? {
        return description
    }

    init(_ description: String) {
        self.description = description
    }
}

@available(iOS 16.0, *)
extension ECEViewController: WKScriptMessageHandlerWithReply {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        // Validate message origin for security
        guard isValidMessageOrigin(message) else {
            replyHandler(nil, "Invalid message origin")
            return
        }

        Task {
            do {
                let response = try await handleMessage(message: message)
                replyHandler(response, nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }
        }
    }

    func handleMessage(message: WKScriptMessage) async throws -> Any? {
        let messageBody = message.body
        guard let expressCheckoutDelegate = expressCheckoutWebviewDelegate else {
            throw BridgeError("ExpressCheckoutWebviewDelegate not set")
        }
        guard let messageDict = messageBody as? [String: Any] else {
            throw BridgeError("Invalid message format \(messageBody)")
        }

        switch message.name {
        case "calculateShipping":
            if let shippingAddress = messageDict["shippingAddress"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveShippingAddressChange: shippingAddress)
            } else {
                throw BridgeError("Invalid calculateShipping message format")
            }

        case "calculateShippingRateChange":
            if let shippingRate = messageDict["shippingRate"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveShippingRateChange: shippingRate)
            } else {
                throw BridgeError("Invalid calculateShippingRateChange message format")
            }

        case "confirmPayment":
            if let paymentDetails = messageDict["paymentDetails"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveECEConfirmation: paymentDetails)
            } else {
                throw BridgeError("Invalid confirmPayment message format")
            }

        case "handleECEClick":
            if let eventData = messageDict["eventData"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveECEClick: eventData)
            } else {
                throw BridgeError("Invalid handleECEClick message format")
            }

        default:
            throw BridgeError("Unknown message type: \(message.name)")
        }
    }
}

// MARK: - WKNavigationDelegate
@available(iOS 16.0, *)
extension ECEViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        log("Navigation started: \(webView.url?.absoluteString ?? "unknown")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log("Navigation finished: \(webView.url?.absoluteString ?? "unknown")")

        // If this is the main page load, initialize the app with our native data
        if webView.url?.absoluteString.contains("pay.stripe.com") == true {
            // Call the JavaScript initializeApp() function now that native data is injected
            webView.evaluateJavaScript("initializeApp()") { _, error in
                if let error = error {
                    log("Failed to call initializeApp(): \(error)")
                    // Bail with error
                } else {
                    log("Successfully called initializeApp()")
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log("Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate (Popup Handling)
@available(iOS 16.0, *)
extension ECEViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        log("Popup requested for URL: \(navigationAction.request.url?.absoluteString ?? "unknown")")

        // Use the provided configuration directly (this fixes the configuration error)
        // Create popup with full screen bounds
        popupWebView = WKWebView(frame: view.bounds, configuration: configuration)
        popupWebView?.navigationDelegate = self
        popupWebView?.uiDelegate = self
        popupWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        #if DEBUG
        if #available(iOS 16.4, *) {
            popupWebView?.isInspectable = true
        }
        #endif

        // Set the same Safari user agent for popups
        popupWebView?.customUserAgent = Self.FakeSafariUserAgent

        // Add the popup webview as a fullscreen overlay
        if let popupWebView = popupWebView {
            view.addSubview(popupWebView)
        }

        return popupWebView
    }

    @objc private func closePopup() {
        unloadWebview()
        delegate?.didCancel()
    }

    func webViewDidClose(_ webView: WKWebView) {
        if webView == popupWebView {
            closePopup()
        }
    }

    // Handle generic JavaScript alerts/confirms/prompts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: frame.request.url?.host() ?? "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.Localized.ok, style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: frame.request.url?.host() ?? "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.Localized.ok, style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: frame.request.url?.host() ?? "", message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: String.Localized.ok, style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel) { _ in
            completionHandler(nil)
        })
        present(alert, animated: true)
    }
}

fileprivate extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

private func log(_ message: String) {
    let timestamp = DateFormatter.logFormatter.string(from: Date())
    #if DEBUG
    print("[\(timestamp)] \(message)")
    #endif
}

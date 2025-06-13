//
//  ECEViewController.swift
//  WebViewBridge2
//
//  Created by David Estes on 5/30/25.
//
//  Updated to use WKScriptMessageHandlerWithReply (iOS 14+)
//  This provides native async/await support without manual request ID management
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
import WebKit

// Protocol for handling Express Checkout Element events
@available(iOS 16.0, *)
protocol ExpressCheckoutWebviewDelegate: AnyObject {
    func amountForECEView(_ eceView: ECEViewController) -> Int
    func eceView(_ eceView: ECEViewController, didReceiveShippingAddressChange shippingAddress: [String: Any]) async throws -> [String: Any]
    func eceView(_ eceView: ECEViewController, didReceiveShippingRateChange shippingRate: [String: Any]) async throws -> [String: Any]
    func eceView(_ eceView: ECEViewController, didReceiveECEClick event: [String: Any]) async throws -> [String: Any]
    func eceView(_ eceView: ECEViewController, didReceiveECEConfirmation paymentDetails: [String: Any]) async throws -> [String: Any]
}

// Custom errors for Express Checkout operations
enum ExpressCheckoutError: LocalizedError {
    case invalidShippingAddress(details: String)
    case invalidShippingRate(rateId: String)
    case shippingServiceFailure(underlying: Error)
    case missingRequiredField(field: String)
    case paymentConfirmationFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidShippingAddress(let details):
            return "Invalid shipping address: \(details)"
        case .invalidShippingRate(let rateId):
            return "Invalid shipping rate: \(rateId)"
        case .shippingServiceFailure(let error):
            return "Shipping service error: \(error.localizedDescription)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .paymentConfirmationFailed(let reason):
            return "Payment confirmation failed: \(reason)"
        }
    }
}

@available(iOS 16.0, *)
class ECEViewController: UIViewController {

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
        setupNavigationBar()

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

        // Enable JavaScript
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Setup message handlers for the bridge
        let contentController = WKUserContentController()

        // Add message handlers for different types of messages
        // Use regular handlers for one-way messages
        contentController.add(self, name: "ready")
        contentController.add(self, name: "error")
        contentController.add(self, name: "consoleLog")

        // Use reply handlers for request/response messages (iOS 14+)
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "calculateShipping")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "calculateShippingRateChange")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "confirmPayment")
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "handleECEClick")

        configuration.userContentController = contentController

        // Inject JavaScript to capture messages and set up the bridge
        let bridgeScript = """

        function getStripePublishableKey() {
        // TODO: Update this key once the bridge is ready
          return "pk_test_51RUTiSAs6uch2mqQune4yYMgnaPTI8z7AuCS9CPb5zaDQuUsje3qsRZKwgjDND3DTwvKVz6aSWYFy36FVA7iyn7h00QbaV5A9S";
        }

        window.NATIVE_AMOUNT_TOTAL = \(expressCheckoutWebviewDelegate?.amountForECEView(self) ?? 0);

        window.NativeShipping = {
            calculateShipping: async function(shippingAddress) {
                return await window.webkit.messageHandlers.calculateShipping.postMessage({
                    shippingAddress: shippingAddress
                });
            },

            calculateShippingRateChange: async function(shippingRate) {
                return await window.webkit.messageHandlers.calculateShippingRateChange.postMessage({
                    shippingRate: shippingRate
                });
            }
        };

        window.NativePayment = {
            confirmPayment: async function(paymentDetails) {
                return await window.webkit.messageHandlers.confirmPayment.postMessage({
                    paymentDetails: paymentDetails
                });
            }
        };

        window.NativeECE = {
            handleClick: async function(eventData) {
                return await window.webkit.messageHandlers.handleECEClick.postMessage({
                    eventData: eventData
                });
            }
        };

        // Notify that the bridge is ready
        try {
            window.webkit.messageHandlers.ready.postMessage({
                type: 'bridgeReady'
            });
        } catch(e) {
            // Ignore errors if webkit handlers not available
        }
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

        // Create a tiny 1x1 pixel webview positioned at origin
        // It's 500x500 for now for debugging
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 500, height: 500), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        webView.isHidden = false // Keep it technically visible but tiny
        webView.alpha = 1.00 // Make it nearly transparent // don't do this for now

        webView.customUserAgent = Self.FakeSafariUserAgent
    }

    private func setupNavigationBar() {
        title = "Checkout"

        // Add refresh button, back, and forward for debugging. Let's get rid of these before ship
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshWebView)
        )
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack)),
            UIBarButtonItem(title: "Forward", style: .plain, target: self, action: #selector(goForward)),
        ]
    }

    private func loadECE() {
        webView.loadHTMLString(ECEHTML, baseURL: URL(string: "https://pay.stripe.com")!)
    }

    @objc private func refreshWebView() {
        webView.reload()
    }

    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
}

// MARK: - WKScriptMessageHandler
@available(iOS 16.0, *)
extension ECEViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageBody = message.body
        let timestamp = DateFormatter.logFormatter.string(from: Date())

        switch message.name {
        case "ready":
            print("✅ [\(timestamp)] Bridge Ready:")
            // TODO: Some timer here to make sure we get ready in time or log an error

        case "error":
            print("❌ [\(timestamp)] Bridge Error:")
            if let errorDict = messageBody as? [String: Any] {
                printMessageDetails(errorDict)
            } else {
                print("   Error: \(messageBody)")
            }

        case "consoleLog":
            if let logDict = messageBody as? [String: Any],
               let level = logDict["level"] as? String,
               let logMessage = logDict["message"] as? String {
                let emoji = logEmojiForLevel(level)
                print("\(emoji) [\(timestamp)] JS Console.\(level): \(logMessage)")

                // Optionally print stack trace for errors
                if level == "error", let stackTrace = logDict["stackTrace"] as? String {
                    let lines = stackTrace.split(separator: "\n").prefix(5) // Show first 5 lines of stack
                    for line in lines {
                        print("     \(line)")
                    }
                }
            }

        default:
            print("🔍 [\(timestamp)] Unknown message type '\(message.name)': \(messageBody)")
        }
    }

    private func printMessageDetails(_ messageDict: [String: Any]) {
        for (key, value) in messageDict.sorted(by: { $0.key < $1.key }) {
            if let nestedDict = value as? [String: Any] {
                print("   \(key):")
                for (nestedKey, nestedValue) in nestedDict.sorted(by: { $0.key < $1.key }) {
                    if let stringValue = nestedValue as? String, stringValue.count > 200 {
                        print("     \(nestedKey): \(String(stringValue.prefix(200)))...")
                    } else {
                        print("     \(nestedKey): \(nestedValue)")
                    }
                }
            } else if let array = value as? [Any] {
                print("   \(key): [\(array.count) items]")
                if array.count <= 5 {
                    for (index, item) in array.enumerated() {
                        print("     [\(index)]: \(item)")
                    }
                }
            } else if let stringValue = value as? String, stringValue.count > 200 {
                print("   \(key): \(String(stringValue.prefix(200)))...")
            } else {
                print("   \(key): \(value)")
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

struct BridgeError: Error {
    public var localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
// MARK: - WKScriptMessageHandlerWithReply (iOS 14+)
@available(iOS 16.0, *)
extension ECEViewController: WKScriptMessageHandlerWithReply {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
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
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        guard let expressCheckoutDelegate = expressCheckoutWebviewDelegate else {
            throw BridgeError("ExpressCheckoutWebviewDelegate not set")
        }
        guard let messageDict = messageBody as? [String: Any] else {
            throw BridgeError("Invalid message format \(messageBody)")
        }

        switch message.name {
        case "calculateShipping":
            print("🚚 [\(timestamp)] Calculate Shipping Request:")
            if let shippingAddress = messageDict["shippingAddress"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveShippingAddressChange: shippingAddress)
            } else {
                throw BridgeError("Invalid calculateShipping message format")
            }

        case "calculateShippingRateChange":
            print("📦 [\(timestamp)] Calculate Shipping Rate Change Request:")
            if let shippingRate = messageDict["shippingRate"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveShippingRateChange: shippingRate)
            } else {
                throw BridgeError("Invalid calculateShippingRateChange message format")
            }

        case "confirmPayment":
            print("💳 [\(timestamp)] Confirm Payment Request (iOS 14+ Reply):")
            if let paymentDetails = messageDict["paymentDetails"] as? [String: Any] {
                return try await expressCheckoutDelegate.eceView(self, didReceiveECEConfirmation: paymentDetails)
            } else {
                throw BridgeError("Invalid confirmPayment message format")
            }

        case "handleECEClick":
            print("👆 [\(timestamp)] ECE Click Event:")
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
        print("🚀 Navigation started: \(webView.url?.absoluteString ?? "unknown")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Navigation finished: \(webView.url?.absoluteString ?? "unknown")")

        // If this is the main page load, initialize the app with our native data
        if webView.url?.absoluteString.contains("pay.stripe.com") == true {
            // Call the JavaScript initializeApp() function now that native data is injected
            webView.evaluateJavaScript("initializeApp()") { _, error in
                if let error = error {
                    print("❌ Failed to call initializeApp(): \(error)")
                    // Bail with error
                } else {
                    print("✅ Successfully called initializeApp()")
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate (Popup Handling)
@available(iOS 16.0, *)
extension ECEViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        print("🪟 Popup requested for URL: \(navigationAction.request.url?.absoluteString ?? "unknown")")

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

            // Add a close button overlay
            let closeButton = UIButton(type: .custom)
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = .systemGray
            closeButton.backgroundColor = .systemBackground.withAlphaComponent(0.9)
            closeButton.layer.cornerRadius = 20
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)

            popupWebView.addSubview(closeButton)

            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: popupWebView.safeAreaLayoutGuide.topAnchor, constant: 16),
                closeButton.trailingAnchor.constraint(equalTo: popupWebView.trailingAnchor, constant: -16),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40),
            ])

            // Store reference to close button so we can remove it later
            closeButton.tag = 999
        }

        return popupWebView
    }

    @objc private func closePopup() {
        popupWebView?.removeFromSuperview()
        popupWebView = nil
    }

    @objc private func refreshPopup() {
        popupWebView?.reload()
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

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Payment Methods
@available(iOS 16.0, *)
extension ECEViewController {

    // Handle payment confirmation with reply handler (iOS 14+)
    private func handlePaymentConfirmationWithReply(paymentDetails: [String: Any], replyHandler: @escaping (Any?, String?) -> Void) async {
        print("💳 Processing payment confirmation...")

        // If delegate is set, let it handle the ECE confirmation
        if let delegate = expressCheckoutWebviewDelegate {
            do {
                let response = try await delegate.eceView(self, didReceiveECEConfirmation: paymentDetails)
                replyHandler(response, nil)
            } catch {
                print("❌ ECE confirmation failed: \(error)")
                replyHandler(nil, error.localizedDescription)
            }
        } else {
            // Fallback to direct payment intent creation if no delegate
            await handleDirectPaymentConfirmation(paymentDetails: paymentDetails, replyHandler: replyHandler)
        }
    }

    // Direct payment confirmation without delegate
    @available(iOS 16.0, *)
    private func handleDirectPaymentConfirmation(paymentDetails: [String: Any], replyHandler: @escaping (Any?, String?) -> Void) async {
        // Extract payment details
//        let billingDetails = paymentDetails["billingDetails"] as? [String: Any]
//        let shippingAddress = paymentDetails["shippingAddress"] as? [String: Any]
        let shippingRate = paymentDetails["shippingRate"] as? [String: Any]
        let selectedShippingId = shippingRate?["id"] as? String
        let mode = paymentDetails["mode"] as? String ?? "payment"
        let captureMethod = paymentDetails["captureMethod"] as? String ?? "automatic"
//        let paymentMethod = paymentDetails["paymentMethod"] as? [String: Any]
//        let createPaymentMethodEnabled = paymentDetails["createPaymentMethodEnabled"] as? Bool ?? false

        // Create payment intent
        do {
            let paymentData = try await createPaymentIntent(
                mode: mode,
                captureMethod: captureMethod,
                selectedShippingId: selectedShippingId
            )

            guard let clientSecret = paymentData["secret"] as? String,
                  let paymentIntentId = paymentData["paymentIntentId"] as? String else {
                replyHandler(nil, "Invalid payment intent response")
                return
            }

            print("✅ PaymentIntent created: \(paymentIntentId)")

            // Return the response directly via reply handler
            let response: [String: Any] = [
                "clientSecret": clientSecret,
                "paymentIntentId": paymentIntentId,
                "mode": mode,
                "requiresAction": false,
                "status": "requires_confirmation",
            ]

            replyHandler(response, nil)

            // Get payment intent details after a short delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await getPaymentIntentDetails(paymentIntentId: paymentIntentId)
            }

        } catch {
            print("❌ Failed to create payment intent: \(error)")
            replyHandler(nil, error.localizedDescription)
        }
    }

    // Create payment intent by calling the Glitch endpoint - now async
    private func createPaymentIntent(
        mode: String,
        captureMethod: String,
        selectedShippingId: String?
    ) async throws -> [String: Any] {
        let url = URL(string: "https://unexpected-dune-list.glitch.me/secret")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "mode": mode,
            "captureMethod": captureMethod,
            "selectedShippingId": selectedShippingId ?? NSNull(),
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ExpressCheckoutError.paymentConfirmationFailed(reason: "Invalid server response")
        }

        return json
    }

    // Get payment intent details - now async
    private func getPaymentIntentDetails(paymentIntentId: String) async {
        let url = URL(string: "https://unexpected-dune-list.glitch.me/intent/\(paymentIntentId)")!

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Invalid payment intent response")
                return
            }

            print("📋 PaymentIntent details:")
            printMessageDetails(json)
        } catch {
            print("❌ Failed to get payment intent details: \(error)")
        }
    }

}

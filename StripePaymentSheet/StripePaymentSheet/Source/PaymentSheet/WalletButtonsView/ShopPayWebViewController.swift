//
//  ShopPayWebviewModel.swift
//  StripePaymentSheet
//
//  Created by John Woo on 6/6/25.
//

@_spi(STP) import StripePayments
import UIKit
import WebKit

@available(iOS 14.0, *)
class ShopPayWebViewController: UIViewController {
    let authenticationContext: STPAuthenticationContext

    private var webView: WKWebView!
    private var popupWebView: WKWebView!

    init(authenticationContext: STPAuthenticationContext) {
        self.authenticationContext = authenticationContext
//        super.init()
        super.init(nibName: nil, bundle: nil)

    }

    required init?(coder: NSCoder) {
//        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create main view
        view = UIView()
        view.backgroundColor = .systemBackground

        setupWebView()

        // Add the tiny 1x1 webview as a hidden subview
        view.addSubview(webView)
    }
    func loadStripeCheckout() {
        guard let url = URL(string: "https://zenith-spicy-dinosaur.glitch.me/checkout/") else {
            print("❌ Invalid URL")
            return
        }

        print("🌐 Loading Stripe checkout: \(url)")
        let request = URLRequest(url: url)
        webView.load(request)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupNavigationBar()

        // Add a label to show this is a hidden webview
        let label = UILabel()
        label.text = "Hidden WebView Bridge\n\nThe 1x1 pixel WebView is running invisibly.\nCheck console for bridge messages."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])

        loadStripeCheckout()
    }
    func setupWebView() {
        let configuration = WKWebViewConfiguration()

        // Enable JavaScript
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Setup message handlers for the bridge
        let contentController = WKUserContentController()

        // Add message handlers for different types of messages
        contentController.add(self, name: "stripeMessage")
        contentController.add(self, name: "consoleLog")
        contentController.add(self, name: "ready")
        contentController.add(self, name: "error")

        configuration.userContentController = contentController

        // Inject JavaScript to capture messages and set up the bridge
        let bridgeScript = """
        // Override console.log to capture messages
        (function() {
            const originalLog = console.log;
            console.log = function(...args) {
                try {
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'log',
                        message: args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' '),
                        origin: window.location.origin,
                        url: window.location.href
                    });
                } catch(e) {
                    // Ignore errors if webkit handlers not available
                }
                originalLog.apply(console, arguments);
            };

            const originalError = console.error;
            console.error = function(...args) {
                try {
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'error',
                        message: args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' '),
                        origin: window.location.origin,
                        url: window.location.href
                    });
                } catch(e) {
                    // Ignore errors if webkit handlers not available
                }
                originalError.apply(console, arguments);
            };

            const originalWarn = console.warn;
            console.warn = function(...args) {
                try {
                    window.webkit.messageHandlers.consoleLog.postMessage({
                        level: 'warn',
                        message: args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' '),
                        origin: window.location.origin,
                        url: window.location.href
                    });
                } catch(e) {
                    // Ignore errors if webkit handlers not available
                }
                originalWarn.apply(console, arguments);
            };
        })();

        // Capture postMessage calls for the current frame only
        (function() {
            const originalPostMessage = window.postMessage;
            window.postMessage = function(message, targetOrigin) {
                try {
                    window.webkit.messageHandlers.stripeMessage.postMessage({
                        type: 'postMessage',
                        message: message,
                        targetOrigin: targetOrigin,
                        timestamp: Date.now(),
                        origin: window.location.origin,
                        url: window.location.href
                    });
                } catch(e) {
                    // Ignore errors if webkit handlers not available
                }
                return originalPostMessage.call(window, message, targetOrigin);
            };
        })();

        // Listen for message events (this captures both incoming and outgoing messages)
        window.addEventListener('message', function(event) {
            try {
                // Capture detailed information about the message
                let sourceInfo = 'unknown';
                try {
                    if (event.source === window) {
                        sourceInfo = 'self';
                    } else if (event.source === window.parent) {
                        sourceInfo = 'parent';
                    } else if (event.source && event.source.location) {
                        sourceInfo = event.source.location.origin;
                    } else {
                        sourceInfo = 'iframe';
                    }
                } catch(e) {
                    sourceInfo = 'cross-origin';
                }

                window.webkit.messageHandlers.stripeMessage.postMessage({
                    type: 'messageEvent',
                    data: event.data,
                    origin: event.origin,
                    source: sourceInfo,
                    timestamp: Date.now(),
                    currentFrame: window.location.href,
                    ports: event.ports ? event.ports.length : 0
                });
            } catch(e) {
                // Ignore errors if webkit handlers not available
            }
        });

        // Enhanced detection for Stripe-specific communications
        (function() {
            // Override the parent.postMessage safely by detecting when it's called
            const originalSend = XMLHttpRequest.prototype.send;
            XMLHttpRequest.prototype.send = function(...args) {
                try {
                    window.webkit.messageHandlers.stripeMessage.postMessage({
                        type: 'xhr',
                        url: this.responseURL || 'unknown',
                        method: this.method || 'unknown',
                        timestamp: Date.now(),
                        origin: window.location.origin
                    });
                } catch(e) {
                    // Ignore errors
                }
                return originalSend.apply(this, args);
            };

            // Monitor fetch requests
            if (window.fetch) {
                const originalFetch = window.fetch;
                window.fetch = function(...args) {
                    try {
                        const url = args[0];
                        window.webkit.messageHandlers.stripeMessage.postMessage({
                            type: 'fetch',
                            url: typeof url === 'string' ? url : url.url,
                            timestamp: Date.now(),
                            origin: window.location.origin
                        });
                    } catch(e) {
                        // Ignore errors
                    }
                    return originalFetch.apply(this, args);
                };
            }
        })();

        // Function to simulate click on shop-pay-payment-request-button in iframes
        function findAndClickShopPayButton() {
            function searchInFrame(frameWindow, depth = 0) {
                if (depth > 5) return false; // Prevent infinite recursion

                try {
                    const button = frameWindow.document.querySelector('shop-pay-payment-request-button');
                    if (button) {
                        console.log('Found shop-pay-payment-request-button at depth', depth);
                        // Try multiple click simulation methods
                        button.click();

                        // Also dispatch synthetic click events
                        const clickEvent = new MouseEvent('click', {
                            bubbles: true,
                            cancelable: true,
                            view: frameWindow
                        });
                        button.dispatchEvent(clickEvent);

                        // Try triggering any onclick handlers
                        if (button.onclick) {
                            button.onclick();
                        }

                        window.webkit.messageHandlers.stripeMessage.postMessage({
                            type: 'shopPayButtonClicked',
                            depth: depth,
                            timestamp: Date.now(),
                            buttonFound: true,
                            origin: frameWindow.location.origin
                        });

                        return true;
                    }

                    // Search in child iframes
                    const iframes = frameWindow.document.querySelectorAll('iframe');
                    for (let iframe of iframes) {
                        try {
                            if (searchInFrame(iframe.contentWindow, depth + 1)) {
                                return true;
                            }
                        } catch(e) {
                            // Cross-origin iframe, skip
                            console.log('Cross-origin iframe at depth', depth + 1);
                        }
                    }
                } catch(e) {
                    console.log('Error searching frame at depth', depth, ':', e.message);
                }

                return false;
            }

            const found = searchInFrame(window);

            if (!found) {
                window.webkit.messageHandlers.stripeMessage.postMessage({
                    type: 'shopPayButtonSearch',
                    buttonFound: false,
                    timestamp: Date.now(),
                    message: 'shop-pay-payment-request-button not found in any accessible iframe'
                });
            }
        }

        // Wait 1 second after page load, then try to find and click the shop pay button
        setTimeout(() => {
            console.log('Searching for shop-pay-payment-request-button...');
            findAndClickShopPayButton();
        }, 1000);

        // Notify that the bridge is ready
        try {
            window.webkit.messageHandlers.ready.postMessage({
                type: 'bridgeReady',
                timestamp: Date.now(),
                userAgent: navigator.userAgent,
                url: window.location.href,
                origin: window.location.origin,
                isTopFrame: window === window.top
            });
        } catch(e) {
            // Ignore errors if webkit handlers not available
        }
        """

        let script = WKUserScript(source: bridgeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)

        // Create a tiny 1x1 pixel webview positioned at origin
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
// Requires ios 16.4
//        webView.isInspectable = true
        webView.isHidden = false // Keep it technically visible but tiny
        webView.alpha = 0.01 // Make it nearly transparent

        // Set Safari user agent to prevent hiding of Express Checkout Element
        // This makes Stripe think we're running in Safari instead of WKWebView
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1"
    }
}

// MARK: - WKScriptMessageHandler
@available(iOS 14.0, *)
extension ShopPayWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageBody = message.body
        let timestamp = DateFormatter.logFormatter.string(from: Date())

        switch message.name {
        case "stripeMessage":
            print("📨 [\(timestamp)] Stripe Message Bridge:")
            if let messageDict = messageBody as? [String: Any] {
                printMessageDetails(messageDict)
            } else {
                print("   Raw message: \(messageBody)")
            }

        case "consoleLog":
            if let logDict = messageBody as? [String: Any],
               let level = logDict["level"] as? String,
               let logMessage = logDict["message"] as? String {
                let emoji = logEmojiForLevel(level)
                let origin = (logDict["origin"] as? String) ?? "unknown"
                let url = (logDict["url"] as? String) ?? "unknown"
                let frameInfo = origin != url ? "[\(origin)]" : ""
                print("\(emoji) [\(timestamp)] Console \(level.uppercased())\(frameInfo): \(logMessage)")
                if logMessage.lowercased().contains("stripe") || logMessage.lowercased().contains("error") {
                    print("   📍 Source: \(url)")
                }
            }

        case "ready":
            print("✅ [\(timestamp)] Bridge Ready:")
            if let readyDict = messageBody as? [String: Any] {
                if let userAgent = readyDict["userAgent"] as? String {
                    if userAgent.contains("Safari") && !userAgent.contains("Mobile") {
                        print("   🎯 Safari User Agent Detected: SUCCESS")
                    } else if userAgent.contains("Safari") {
                        print("   📱 Mobile Safari User Agent Detected: SUCCESS")
                    } else {
                        print("   ⚠️  WKWebView User Agent Detected (not Safari)")
                    }
                }
                printMessageDetails(readyDict)
            }

        case "error":
            print("❌ [\(timestamp)] Bridge Error:")
            if let errorDict = messageBody as? [String: Any] {
                printMessageDetails(errorDict)
            } else {
                print("   Error: \(messageBody)")
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
        case "log": return "📝"
        default: return "📝"
        }
    }
}

// MARK: - WKNavigationDelegate
@available(iOS 14.0, *)
extension ShopPayWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🚀 Navigation started: \(webView.url?.absoluteString ?? "unknown")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Navigation finished: \(webView.url?.absoluteString ?? "unknown")")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow all navigation for Stripe checkout
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate (Popup Handling)
@available(iOS 14.0, *)
extension ShopPayWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        print("🪟 Popup requested for URL: \(navigationAction.request.url?.absoluteString ?? "unknown")")

        // Use the provided configuration directly (this fixes the configuration error)
        popupWebView = WKWebView(frame: .zero, configuration: configuration)
        popupWebView?.navigationDelegate = self
        popupWebView?.uiDelegate = self

        // Set the same Safari user agent for popups
        popupWebView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1"
        /*
        // Create popup window
        if #available(iOS 13.0, *) {
            if let windowScene = view.window?.windowScene {
                popupWindow = UIWindow(windowScene: windowScene)
            }
        } else {
            popupWindow = UIWindow(frame: UIScreen.main.bounds)
        }*/

        let popupViewController = UIViewController()
        popupViewController.view = popupWebView
        popupViewController.title = "Stripe Popup"

//        let navController = UINavigationController(rootViewController: popupViewController)

        // Add close button to popup
        popupViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closePopup)
        )

//        popupWindow?.rootViewController = navController
//        popupWindow?.makeKeyAndVisible()

        return popupWebView
    }

    @objc private func closePopup() {
//        popupWindow?.isHidden = true
//        popupWindow = nil
//        popupWebView = nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        if webView == popupWebView {
            closePopup()
        }
    }

    // Handle JavaScript alerts/confirms/prompts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        authenticationContext.authenticationPresentingViewController().present(alert, animated: true)
//        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        authenticationContext.authenticationPresentingViewController().present(alert, animated: true)

//        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "Input", message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        authenticationContext.authenticationPresentingViewController().present(alert, animated: true)

        //        present(alert, animated: true)
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

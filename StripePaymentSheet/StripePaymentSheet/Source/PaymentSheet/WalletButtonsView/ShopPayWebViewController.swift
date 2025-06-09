//
//  ShopPayWebviewModel.swift
//  StripePaymentSheet
//
//  Created by John Woo on 6/6/25.
//

@_spi(STP) import StripePayments
import UIKit
import WebKit

@available(iOS 16.4, *)
class ShopPayWebViewController: UIViewController {
    let authenticationContext: STPAuthenticationContext

    private var webView: WKWebView!
    private var popupWebView: WKWebView!
    private var popupWindow: UIWindow?
    private var button: UIButton


    init(authenticationContext: STPAuthenticationContext) {
        self.authenticationContext = authenticationContext
        self.button = UIButton(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // Create main view
//        view = UIView()
//        view.backgroundColor = .systemBackground

        setupWebView()
        view = webView
        self.button.addTarget(self, action: #selector(didTapNativeButton), for: .touchUpInside)
        self.button.backgroundColor = .blue
        self.view.addSubview(button)
        // Add the tiny 1x1 webview as a hidden subview
//        view.addSubview(webView)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        // Add a label to show this is a hidden webview
        loadStripeCheckout()
    }
    
    
    func loadStripeCheckout() {
//        let oldURL = "https://zenith-spicy-dinosaur.glitch.me/checkout/"
//        let confTokensDemo = "https://confirmation-tokens.glitch.me/checkout/"
        let confTokensDemo = "https://inquisitive-seasoned-fountain-apayqa.glitch.me/checkout/"
        guard let url = URL(string: confTokensDemo) else {
            print("❌ Invalid URL")
            return
        }

//        print("🌐 Loading Stripe checkout: \(url)")
        let request = URLRequest(url: url)
        webView.load(request)
//      webView.loadHTMLString(ShopPayStaticHTMLPage.htmlString, baseURL: nil)
    }

    private func setupNavigationBar() {
        title = "Stripe Checkout Bridge"
        
        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshWebView)
        )
        
        // Add back/forward buttons if needed
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack)),
            UIBarButtonItem(title: "Forward", style: .plain, target: self, action: #selector(goForward))
        ]
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

    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Enable JavaScript
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
//        configuration.defaultWebpagePreferences.javaScriptCanOpenWindowsAutomatically = true
        
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


        function findAndClickAmazonPayButton() {
            function searchInFrame(frameWindow, depth = 0) {
                if (depth > 5) return false; // Prevent infinite recursion
                
                try {
                    // Look for the Amazon Pay button by class or id
                    const button = frameWindow.document.querySelector('.amazonpay-button-parent-container-checkout') || 
                                  frameWindow.document.querySelector('#stripe-falcon-button');
                    
                    if (button) {
                        console.log('Found Amazon Pay button at depth', depth);
                        
                        // Log details about the button to help with debugging
                        console.log('Button details:', {
                            id: button.id,
                            className: button.className,
                            role: button.getAttribute('role'),
                            ariaLabel: button.getAttribute('aria-label'),
                            isRendered: button.getAttribute('rendered'),
                            isVisible: button.style.display !== 'none' && button.offsetParent !== null
                        });
                        
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
                        
                        // Look for potential shadow DOM (used by some custom elements)
                        if (button.shadowRoot) {
                            console.log('Button has shadow root, attempting to click inside shadow DOM');
                            const shadowButton = button.shadowRoot.querySelector('button, [role="button"]');
                            if (shadowButton) {
                                shadowButton.click();
                            }
                        }
                        
                        // Attempt to find a button inside the container (common pattern)
                        const nestedButton = button.querySelector('button, [role="button"]');
                        if (nestedButton) {
                            console.log('Found nested button element, clicking it');
                            nestedButton.click();
                        }
                        
                        window.webkit.messageHandlers.stripeMessage.postMessage({
                            type: 'amazonPayButtonClicked',
                            depth: depth,
                            timestamp: Date.now(),
                            buttonFound: true,
                            buttonId: button.id,
                            buttonClass: button.className,
                            origin: frameWindow.location.origin
                        });
                        
                        return true;
                    }
                    
                    // If button not found directly, search for elements with "amazon" in their attributes
                    const possibleAmazonElements = frameWindow.document.querySelectorAll('[id*="amazon"],[class*="amazon"],[aria-label*="Amazon"]');
                    if (possibleAmazonElements.length > 0) {
                        console.log(`Found ${possibleAmazonElements.length} potential Amazon Pay elements`);
                        for (const element of possibleAmazonElements) {
                            console.log('Potential Amazon element:', element.tagName, {
                                id: element.id, 
                                class: element.className,
                                role: element.getAttribute('role')
                            });
                            
                            // Try clicking this element too
                            try {
                                element.click();
                                console.log('Clicked potential Amazon element');
                            } catch (e) {
                                console.log('Failed to click potential element:', e.message);
                            }
                        }
                    }
                    
                    // Search in child iframes
                    const iframes = frameWindow.document.querySelectorAll('iframe');
                    console.log(`Searching through ${iframes.length} iframes at depth ${depth}`);
                    
                    for (let iframe of iframes) {
                        try {
                            if (searchInFrame(iframe.contentWindow, depth + 1)) {
                                return true;
                            }
                        } catch(e) {
                            console.log('Cross-origin iframe at depth', depth + 1, ':', e.message);
                        }
                    }
                } catch(e) {
                    console.log('Error searching frame at depth', depth, ':', e.message);
                }
                
                return false;
            }
            
            // Additional diagnostics before starting search
            console.log('Page URL:', window.location.href);
            console.log('Document ready state:', document.readyState);
            
            // Log all iframes on the page for debugging
            const allIframes = document.querySelectorAll('iframe');
            console.log(`Top level has ${allIframes.length} iframes`);
            allIframes.forEach((iframe, i) => {
                console.log(`Iframe ${i} src:`, iframe.src || 'no src', 'id:', iframe.id || 'no id');
            });
            
            const found = searchInFrame(window);
            
            if (!found) {
                // Log HTML structure to help with debugging
                console.log('Button not found. Document structure:');
                console.log(document.body.innerHTML);
                
                window.webkit.messageHandlers.stripeMessage.postMessage({
                    type: 'amazonPayButtonSearch',
                    buttonFound: false,
                    timestamp: Date.now(),
                    message: 'Amazon Pay button not found in any accessible iframe',
                    documentBodyHTML: document.body.innerHTML.substring(0, 1000) // First 1000 chars for diagnosis
                });
            }
        }

        // The button might need more time to render, so wait longer
        setTimeout(() => {
            console.log('Searching for Amazon Pay button...');
            findAndClickAmazonPayButton();
        }, 2000); // Wait 2 seconds

        
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
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isInspectable = true
        
        // Set Safari user agent to prevent hiding of Express Checkout Element
        // This makes Stripe think we're running in Safari instead of WKWebView
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1"
    }
    
    func executeJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ JavaScript execution error: \(error.localizedDescription)")
            } else if let result = result {
                print("✅ JavaScript execution result: \(result)")
            }
            completion?(result, error)
        }
    }
    
    struct ShippingDetails: Encodable {
        let name: String
        let shippingMethod: String
    }
    func sendExampleShippingDetails() {
        let shippingOptions = [
            ShippingDetails(name: "Standard Shipping", shippingMethod: "standard"),
            ShippingDetails(name: "Express Shipping", shippingMethod: "express"),
            ShippingDetails(name: "Next Day Delivery", shippingMethod: "next-day")
        ]
        
        sendShippingDetailsToJavaScript(shippingOptions) { success, error in
            if success {
                print("JavaScript successfully received shipping options")
            } else if let error = error {
                print("Failed to send shipping options: \(error.localizedDescription)")
            }
        }
    }
    func sendShippingDetailsToJavaScript(_ shippingDetails: [ShippingDetails], completion: ((Bool, Error?) -> Void)? = nil) {
        do {
            // Convert the array to JSON data
            let jsonData = try JSONEncoder().encode(shippingDetails)
            
            // Convert JSON data to a string that can be used in JavaScript
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Escape any quotes to avoid breaking the JavaScript string
                let escapedJsonString = jsonString.replacingOccurrences(of: "\"", with: "\\\"")
                
                // Create the JavaScript code that will process this data
                let jsCode = """
                (function() {
                    try {
                        // Parse the JSON string back to a JavaScript object
                        const shippingDetails = JSON.parse("\(escapedJsonString)");
                        
                        // Log the received data
                        console.log("📦 Received shipping details from iOS:", shippingDetails);
                        
                        // Store it in a global variable for access by other scripts
                        window.nativeShippingDetails = shippingDetails;
                        
                        // Dispatch an event to notify any listeners
                        const event = new CustomEvent('shippingDetailsReceived', { 
                            detail: { 
                                shippingDetails: shippingDetails,
                                timestamp: Date.now()
                            }
                        });
                        document.dispatchEvent(event);
                        
                        // Process each shipping item (example)
                        shippingDetails.forEach(item => {
                            console.log(`Processing shipping option: ${item.name} with method ${item.shippingMethod}`);
                            // Your JavaScript code to handle each shipping detail
                        });
                        
                        return true; // Success indicator
                    } catch (error) {
                        console.error("Error processing shipping details:", error);
                        return false; // Error indicator
                    }
                })();
                """
                
                // Execute the JavaScript
                executeJavaScript(jsCode) { result, error in
                    if let error = error {
                        print("❌ Error sending shipping details to JavaScript: \(error.localizedDescription)")
                        completion?(false, error)
                    } else if let success = result as? Bool, success {
                        print("✅ Successfully sent shipping details to JavaScript")
                        completion?(true, nil)
                    } else {
                        print("⚠️ Unexpected result when sending shipping details: \(String(describing: result))")
                        completion?(false, NSError(domain: "ShippingDetailsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process shipping details in JavaScript"]))
                    }
                }
            } else {
                let error = NSError(domain: "ShippingDetailsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string"])
                print("❌ \(error.localizedDescription)")
                completion?(false, error)
            }
        } catch {
            print("❌ Error encoding shipping details: \(error.localizedDescription)")
            completion?(false, error)
        }
    }


}

// MARK: - WKScriptMessageHandler
@available(iOS 16.4, *)

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
//                executeNativeCommandToJavaScript()
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
    @objc
    func didTapNativeButton() {
//        executeNativeCommandToJavaScript()
        sendExampleShippingDetails()
    }
    
    // Add this method to execute commands once the bridge is ready
    private func executeNativeCommandToJavaScript() {
        print("🚀 Native iOS sending command to JavaScript...")
        
        // Example command: log a message
        let logCommand = """
        console.log("Hello from native iOS! Bridge is connected and working.");
        """
        
        // Example command: execute a function in the webpage
        let executeFunction = """
        (function() {
            console.log("Executing native command from iOS...");
            
            // Create and dispatch a custom event that your web app can listen for
            const nativeEvent = new CustomEvent('nativeCommand', {
                detail: {
                    command: 'initialize',
                    timestamp: \(Date().timeIntervalSince1970),
                    source: 'iOS-Native'
                }
            });
            document.dispatchEvent(nativeEvent);
            
            return "Command executed successfully";
        })();
        """
        
        // Execute the commands
        executeJavaScript(logCommand)
        
        // Execute with a slight delay to ensure the first command completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.executeJavaScript(executeFunction) { result, error in
                if let result = result {
                    print("🔄 Command execution feedback: \(result)")
                }
            }
        }
    }

}

// MARK: - WKNavigationDelegate
@available(iOS 16.4, *)
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
@available(iOS 16.4, *)
extension ShopPayWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        print("🪟 Popup requested for URL: \(navigationAction.request.url?.absoluteString ?? "unknown")")

        // Use the provided configuration directly (this fixes the configuration error)
        popupWebView = WKWebView(frame: .zero, configuration: configuration)
        popupWebView?.navigationDelegate = self
        popupWebView?.uiDelegate = self
        
        // Set the same Safari user agent for popups
        popupWebView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Mobile/15E148 Safari/604.1"
        
        // Create popup window
            if let windowScene = view.window?.windowScene {
                popupWindow = UIWindow(windowScene: windowScene)
            }
//        } else {
//            popupWindow = UIWindow(frame: UIScreen.main.bounds)
//        }

        let popupViewController = UIViewController()
        popupViewController.view = popupWebView
        popupViewController.title = "Stripe Popup"

        let navController = UINavigationController(rootViewController: popupViewController)

        // Add close button to popup
        popupViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closePopup)
        )

        popupWindow?.rootViewController = navController
        popupWindow?.makeKeyAndVisible()
        
        return popupWebView
    }

    @objc private func closePopup() {
        popupWindow?.isHidden = true
        popupWindow = nil
        popupWebView = nil
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

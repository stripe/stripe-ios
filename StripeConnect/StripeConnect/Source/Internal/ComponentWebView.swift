//
//  ComponentWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import UIKit
import WebKit

class ComponentWebView: WKWebView, WKScriptMessageHandler {
    private var fetchClientSecret: () async -> String?

    let publishableKey: String
    let componentType: String

    /// Supported message handlers for JS -> Swift messaging
    enum MessageHandler: String, CaseIterable {
        /// Temporary handler to print debug statements to Xcode's console from JS
        case debug
        /// Begins fetching the client secret. After this is called, Swift will execute the `resolveFetchClientSecret` JS function.
        case beginFetchClientSecret
    }

    init(publishableKey: String,
         componentType: String,
         fetchClientSecret: @escaping () async -> String?) {
        self.fetchClientSecret = fetchClientSecret
        self.publishableKey = publishableKey
        self.componentType = componentType

        let contentController = WKUserContentController()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences = preferences

        super.init(frame: .zero, configuration: config)

        // Allow the web view to be inspected for debug builds
        #if DEBUG
        if #available(iOS 16.4, *) {
            isInspectable = true
        }
        #endif

        MessageHandler.allCases.forEach { handler in
            contentController.add(self, name: handler.rawValue)
        }

//        let indexURL = BundleLocator.resourcesBundle.url(forResource: "index", withExtension: "html", subdirectory: "WebViewFiles")!
//        let directoryUrl = BundleLocator.resourcesBundle.url(forResource: "WebViewFiles", withExtension: nil)!
//        var urlComponents = URLComponents(url: indexURL, resolvingAgainstBaseURL: true)!
//        urlComponents.queryItems = [
//            .init(name: "publishableKey", value: publishableKey),
//            .init(name: "componentType", value: componentType),
//        ]


//        loadFileURL(urlComponents.url!, allowingReadAccessTo: directoryUrl)

        loadContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reload() -> WKNavigation? {
        loadContents()
        return nil
    }

    func loadContents() {
        // Load HTML file and spoof that it's coming from docs.stripe.com
        // This is a hack.
        let htmlFile = BundleLocator.resourcesBundle.url(forResource: "template", withExtension: "html")!
        let htmlText = try! String(contentsOf: htmlFile, encoding: .utf8)
            .replacingOccurrences(of: "{{COMPONENT_TYPE}}", with: componentType)
            .replacingOccurrences(of: "{{PUBLISHABLE_KEY}}", with: publishableKey)
        let data = htmlText.data(using: .utf8)!

        load(data, mimeType: "text/html", characterEncodingName: "utf8", baseURL: URL(string: "https://docs.stripe.com/")!)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        switch MessageHandler(rawValue: message.name) {
        case .none:
            // TODO: We should probably log an error for this
            print("Unrecognized handler \(message.name)")

        case .debug:
            print(message.body as? String as Any)

        case .beginFetchClientSecret:
            Task { @MainActor in
                // TODO: Add error handling if `fetchClientSecret` is nil
                // Alternatively, we could make `fetchClientSecret` have a `throws async -> String` signature and forward the error to the integrator
                let secret = await fetchClientSecret() ?? ""
                self.synchronousEvaluateJavaScript("resolveFetchClientSecret('\(secret)')")
            }
        }
    }

    // MARK: - Private

    /**
     Wrapper for synchronous version of `evaluateJavaScript` so we can call it
     from an async context without compiler warning.

     - Note:
     Using the async version of `evaluateJavaScript` causes the fatal error:
     `Unexpectedly found nil while implicitly unwrapping an Optional value`

     Explicitly calling the synchronous version from an async context triggers the compiler warning:
     `Consider using asynchronous alternative function`

     So wrapping this function is the only way to avoid a compiler warning and fata
     */
    private func synchronousEvaluateJavaScript(_ script: String) {
        evaluateJavaScript(script)
    }
}

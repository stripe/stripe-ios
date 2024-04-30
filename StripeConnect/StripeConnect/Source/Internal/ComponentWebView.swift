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

    /// Supported message handlers for JS -> Swift messaging
    enum MessageHandler: String, CaseIterable {
        /// Temporary handler to print debug statements to Xcode's console from JS
        case debug
        /// Begins fetching the client secret. After this is called, Swift will execute the `resolveFetchClientSecret` JS function.
        case beginFetchClientSecret
    }

    init(publishableKey: String,
         componentType: String,
         appearance: StripeConnectInstance.Appearance,
         fetchClientSecret: @escaping () async -> String?) {
        self.fetchClientSecret = fetchClientSecret

        let contentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        super.init(frame: .zero, configuration: config)

        // Allow the web view to be inspected for debug builds on 16.4+
        #if DEBUG
        if #available(iOS 16.4, *) {
            isInspectable = true
        }
        #endif

        MessageHandler.allCases.forEach { handler in
            contentController.add(self, name: handler.rawValue)
        }

//        addDebugRefreshButton()
        loadContents(publishableKey: publishableKey, componentType: componentType, appearance: appearance)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        switch MessageHandler(rawValue: message.name) {
        case .none:
            debugPrint("Unrecognized handler \(message.name)")

        case .debug:
            debugPrint(message.body as? String as Any)

        case .beginFetchClientSecret:
            Task { @MainActor in
                // TODO: Add error handling if `fetchClientSecret` is nil
                // Alternatively, we could make `fetchClientSecret` have a `throws async -> String` signature and forward the error to the integrator
                let secret = await fetchClientSecret() ?? ""
                self.synchronousEvaluateJavaScript("resolveFetchClientSecret('\(secret)')")
            }
        }
    }

    // MARK: - Internal

    func updateAppearance(_ appearance: StripeConnectInstance.Appearance) {
        evaluateJavaScript("stripeConnectInstance.update({appearance: \(appearance.asJsonString)})")
    }

    func updateLocale(_ locale: Locale) {
        evaluateJavaScript("stripeConnectInstance.update({locale: \(locale.identifier)})")
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

    private func loadContents(
        publishableKey: String,
        componentType: String,
        appearance: StripeConnectInstance.Appearance
    ) {
        // Load HTML file and spoof that it's coming from connect-js.stripe.com
        // to avoid CORS restrictions from loading a local file.
        guard let htmlFile = BundleLocator.resourcesBundle.url(forResource: "template", withExtension: "html"),
              var htmlText = try? String(contentsOf: htmlFile, encoding: .utf8) else {
            debugPrint("Couldn't load `template.html`")
            return
        }

        htmlText = htmlText
            .replacingOccurrences(of: "{{COMPONENT_TYPE}}", with: componentType)
            .replacingOccurrences(of: "{{PUBLISHABLE_KEY}}", with: publishableKey)
            .replacingOccurrences(of: "{{APPEARANCE}}", with: appearance.asJsonString)

        guard let data = htmlText.data(using: .utf8) else {
            debugPrint("Couldn't encode html data")
            return
        }

        load(data, mimeType: "text/html", characterEncodingName: "utf8", baseURL: URL(string: "https://connect-js.stripe.com")!)
    }

//    private func addDebugRefreshButton() {
//        #if DEBUG
//
//        let refreshButton = UIButton(type: .system)
//        refreshButton.setTitle("Refresh", for: .normal)
//
//        // Calling `reload` will just load `docs.stripe.com`, so we need to
//        // reload the contents instead.
//        refreshButton.addTarget(nil, action: #selector(loadContents), for: .touchUpInside)
//        addSubview(refreshButton)
//        refreshButton.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            refreshButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
//            refreshButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
//        ])
//
//        #endif
//    }
}

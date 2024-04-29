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

    init(publishableKey: String,
         componentType: String,
         fetchClientSecret: @escaping () async -> String?) {
        self.fetchClientSecret = fetchClientSecret

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

        contentController.add(self, name: "fetchClientSecret")
        contentController.add(self, name: "debug")

        let htmlFileUrl = BundleLocator.resourcesBundle.url(forResource: "component", withExtension: "html", subdirectory: "WebViewFiles")!
        let directoryUrl = BundleLocator.resourcesBundle.url(forResource: "WebViewFiles", withExtension: nil)!

        var urlComponents = URLComponents(url: htmlFileUrl, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            .init(name: "publishableKey", value: publishableKey),
            .init(name: "componentType", value: componentType),
        ]

        loadFileURL(urlComponents.url!, allowingReadAccessTo: directoryUrl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, 
                               didReceive message: WKScriptMessage) {
        if message.name == "debug" {
            print(message.body as? String as Any)
        }
        guard message.name == "fetchClientSecret" else {
            return
        }

        Task { @MainActor in
            let secret = await fetchClientSecret() ?? ""
            /*
             Using the async version of `evaluateJavaScript` causes the fatal error:
             `Unexpectedly found nil while implicitly unwrapping an Optional value`

             Explicitly calling the non-async version triggers a compiler warning,
             so wrapping it with `synchronousEvaluateJavaScript` makes the compiler happy.
             */
            self.synchronousEvaluateJavaScript("resolveFetchClientSecret('\(secret)')")
        }
    }

    // MARK: - Private

    private func synchronousEvaluateJavaScript(_ script: String) {
        evaluateJavaScript(script)
    }
}

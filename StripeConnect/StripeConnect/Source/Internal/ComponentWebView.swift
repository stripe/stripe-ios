//
//  ComponentWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import UIKit
import WebKit

class ComponentWebView: WKWebView, WKScriptMessageHandler, WKUIDelegate {
    /// Supported message handlers for JS -> Swift messaging
    enum MessageHandler: String, CaseIterable {
        /// Temporary handler to print debug statements to Xcode's console from JS
        case debug
        /// Begins fetching the client secret. After this is called, Swift will execute the `resolveFetchClientSecret` JS function.
        case beginFetchClientSecret
    }

    private var connectInstance: StripeConnectInstance
    private var componentType: String

    /// Closure to present a popup web view controller
    var presentPopup: ((UIViewController) -> Void)?

    init(connectInstance: StripeConnectInstance,
         componentType: String) {
        self.connectInstance = connectInstance
        self.componentType = componentType

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
        uiDelegate = self

        addDebugReloadButton()
        loadContents()
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
                let secret = await connectInstance.fetchClientSecret() ?? ""
                self.synchronousEvaluateJavaScript("resolveFetchClientSecret('\(secret)')")
            }
        }
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }

        guard let presentPopup else {
            assertionFailure("Cannot present popup")
            return nil
        }

        let popupVC = PopupWebViewController(configuration: configuration, navigationAction: navigationAction)
        let navController = UINavigationController(rootViewController: popupVC)
        popupVC.navigationItem.rightBarButtonItem = .init(systemItem: .done, primaryAction: .init(handler: { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
        }))

        presentPopup(navController)
        return popupVC.webView
    }

    // MARK: - Internal

    // TODO: There's probably a better way to do this than calling in from every VC.
    // Maybe wrapping this in a container view that calls these from deinit?
    func preventRetainCycles() {
        stopLoading()
        MessageHandler.allCases.forEach { handler in
            configuration.userContentController.removeScriptMessageHandler(forName: handler.rawValue)
        }
        uiDelegate = nil
    }

    func updateAppearance(_ appearance: StripeConnectInstance.Appearance) {
        evaluateJavaScript("stripeConnectInstance.update({appearance: \(appearance.asJsonString)})")
    }

    func logout() async {
        _ = try? await evaluateJavaScript("stripeConnectInstance.logout()")
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

     Wrapping this function is the only way to avoid both the fatal error and compiler warning.
     */
    private func synchronousEvaluateJavaScript(_ script: String) {
        evaluateJavaScript(script)
    }

    private func loadContents() {
        // Load HTML file and spoof that it's coming from connect-js.stripe.com
        // to avoid CORS restrictions from loading a local file.
        guard let htmlFile = BundleLocator.resourcesBundle.url(forResource: "template", withExtension: "html"),
              var htmlText = try? String(contentsOf: htmlFile, encoding: .utf8) else {
            debugPrint("Couldn't load `template.html`")
            return
        }

        // TODO: Error handle if PK is nil
        htmlText = htmlText
            .replacingOccurrences(of: "{{COMPONENT_TYPE}}", with: componentType)
            .replacingOccurrences(of: "{{PUBLISHABLE_KEY}}", with: connectInstance.apiClient.publishableKey ?? "")
            .replacingOccurrences(of: "{{APPEARANCE}}", with: connectInstance.appearance.asJsonString)

        guard let data = htmlText.data(using: .utf8) else {
            debugPrint("Couldn't encode html data")
            return
        }

        load(data, mimeType: "text/html", characterEncodingName: "utf8", baseURL: URL(string: "https://connect-js.stripe.com")!)
    }

    private func addDebugReloadButton() {
        #if DEBUG
        let reloadButton = UIButton(
            type: .system,
            primaryAction: .init(handler: { [weak self] _ in
                // Calling `reload` will just load `connect-js.stripe.com`,
                // so we need to reload the contents instead.
                self?.loadContents()
            })
        )
        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        reloadButton.layer.cornerRadius = 4

        addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reloadButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            reloadButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8),
        ])

        #endif
    }
}

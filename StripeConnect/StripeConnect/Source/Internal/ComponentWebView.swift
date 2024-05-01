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

    private var fetchClientSecret: () async -> String?
    var presentPopup: ((UIViewController) -> Void)?
    private var dismissPopup: (() -> Void)?

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
        uiDelegate = self

        addDebugReloadButton(publishableKey: publishableKey, componentType: componentType, appearance: appearance)
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
        popupVC.navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .done, target: self, action: #selector(didClosePopup))
        dismissPopup = { [weak popupVC] in
            popupVC?.dismiss(animated: true)
        }

        presentPopup(navController)
        return popupVC.webView
    }

    // MARK: - Internal

    @objc
    func didClosePopup() {
        dismissPopup?()
        dismissPopup = nil
    }

    func registerSubscriptions(connectInstance: StripeConnectInstance,
                               storeIn cancellables: inout Set<AnyCancellable>) {
        connectInstance.$appearance.sink { [weak self] appearance in
            self?.updateAppearance(appearance)
        }.store(in: &cancellables)
        connectInstance.logoutPublisher.sink { [weak self] _ in
            self?.logout()
        }.store(in: &cancellables)
    }

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

    func logout() {
        evaluateJavaScript("stripeConnectInstance.logout()")
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

    private func addDebugReloadButton(
        publishableKey: String,
        componentType: String,
        appearance: StripeConnectInstance.Appearance
    ) {
        #if DEBUG
        guard #available(iOS 14, *) else { return }

        let reloadButton = UIButton(
            type: .system,
            primaryAction: .init(handler: { [weak self] _ in
                // Calling `reload` will just load `connect-js.stripe.com`,
                // so we need to reload the contents instead.
                self?.loadContents(publishableKey: publishableKey,
                             componentType: componentType,
                             appearance: appearance)
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

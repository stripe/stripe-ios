//
//  ComponentWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import UIKit
import WebKit

class ComponentWebView: WKWebView {

    /// Supported message handlers for one way JS -> Swift messaging
    enum VoidMessageHandler: String, CaseIterable {
        /// Prints debug statements to Xcode's console from JS
        case debug
    }

    /// Supported async message handlers for JS to call into Swift and receive an async return value
    enum MessageHandlerWithReply: String, CaseIterable {
        /// Fetches the client secret
        case fetchClientSecret
    }

    private var connectInstance: StripeConnectInstance
    private var componentType: String

    /// The content controller that registers JS -> Script message handlers
    private let contentController: WKUserContentController

    /// Closure to present a popup web view controller
    var presentPopup: ((UIViewController) -> Void)?

    init(connectInstance: StripeConnectInstance,
         componentType: String) {
        self.connectInstance = connectInstance
        self.componentType = componentType

        contentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        super.init(frame: .zero, configuration: config)

        // Allow the web view to be inspected for debug builds on 16.4+
        #if DEBUG
        if #available(iOS 16.4, *) {
            isInspectable = true
        }
        #endif

        uiDelegate = self

        registerMessageHandlers()
        addDebugReloadButton()
        loadContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - WKScriptMessageHandler

extension ComponentWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        switch VoidMessageHandler(rawValue: message.name) {
        case .none:
            debugPrint("Unrecognized handler \(message.name)")

        case .debug:
            debugPrint(message.body as? String as Any)
        }
    }
}

// MARK: - WKScriptMessageHandlerWithReply

extension ComponentWebView: WKScriptMessageHandlerWithReply {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        switch MessageHandlerWithReply(rawValue: message.name) {
        case .none:
            debugPrint("Unrecognized handler \(message.name)")
            return (nil, nil)

        case .fetchClientSecret:
            let secret = await connectInstance.fetchClientSecret()
            return (secret, nil)
        }
    }
}

// MARK: - WKUIDelegate

extension ComponentWebView: WKUIDelegate {
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
}

// MARK: - Internal

extension ComponentWebView {

    // TODO: There's probably a better way to do this than calling in from every VC.
    // Maybe wrapping this in a container view that calls these from deinit?
    func preventRetainCycles() {
        stopLoading()
        contentController.removeAllScriptMessageHandlers()
        uiDelegate = nil
    }

    func updateAppearance(_ appearance: StripeConnectInstance.Appearance) {
        evaluateJavaScript("stripeConnectInstance.update({appearance: \(appearance.asJsonString)})")
    }

    func logout() async {
        _ = try? await evaluateJavaScript("stripeConnectInstance.logout()")
    }
}

// MARK: - Private

private extension ComponentWebView {
    func registerMessageHandlers() {
        VoidMessageHandler.allCases.forEach { handler in
            contentController.add(self, name: handler.rawValue)
        }
        MessageHandlerWithReply.allCases.forEach { handler in
            contentController.addScriptMessageHandler(self, contentWorld: .page, name: handler.rawValue)
        }
    }

    func loadContents() {
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

    func addDebugReloadButton() {
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

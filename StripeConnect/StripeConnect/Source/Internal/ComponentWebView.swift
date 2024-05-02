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
    // TODO: We can update this to the URL of our remote index page (see note on loadContents).
    /// Any camera access requests coming from the base URL will be automatically accepted
    static let baseURL = URL(string: "https://connect-js.stripe.com")!

    private var connectInstance: StripeConnectInstance
    private var componentType: String

    /// The content controller that registers JS -> Script message handlers
    private let contentController: WKUserContentController

    /// Closure to present a popup web view controller.
    /// This is required for any components that can open a popup, otherwise an assertionFailure will occur.
    var presentPopup: ((UIViewController) -> Void)?

    /// Closure that executes when the view finishes loading.
    /// - Note: If any JS needs to be evaluated immediately after instantiation, do that here.
    var didFinishLoading: ((ComponentWebView) -> Void)?

    init(connectInstance: StripeConnectInstance,
         componentType: String) {
        self.connectInstance = connectInstance
        self.componentType = componentType

        contentController = WKUserContentController()
        let config = WKWebViewConfiguration()

        // Allows for custom JS message handlers for JS -> Swift communication
        config.userContentController = contentController

        // Allows the identity verification flow to display the camera feed
        // embedded in the web view instead of full screen. Also works for
        // embedded YouTube videos.
        config.allowsInlineMediaPlayback = true

        super.init(frame: .zero, configuration: config)

        // Allow the web view to be inspected for debug builds on 16.4+
        #if DEBUG
        if #available(iOS 16.4, *) {
            isInspectable = true
        }
        #endif

        uiDelegate = self
        navigationDelegate = self

        registerMessageHandlers()
        addDebugReloadButton()
        loadContents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - WKUIDelegate

extension ComponentWebView: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Enables the auth popup to work for onboarding page

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

    func webView(_ webView: WKWebView,
                 decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
                 initiatedBy frame: WKFrameInfo,
                 type: WKMediaCaptureType) async -> WKPermissionDecision {
        // Don't prompt the user for camera permissions from connect-js
        origin.host == Self.baseURL.host ? .grant : .deny
    }
}

// MARK: - WKNavigationDelegate

extension ComponentWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Call our custom handler when we know the page has finished loading
        didFinishLoading?(self)
    }
}

// MARK: - Internal

extension ComponentWebView {
    /// Calls `update({appearance: ...})` on the JS StripeConnectInstance
    func updateAppearance(_ appearance: StripeConnectInstance.Appearance) {
        evaluateJavaScript("stripeConnectInstance.update({appearance: \(appearance.asJsonString)})")
    }

    /// Calls `logout()` on the JS StripeConnectInstance
    func logout() async {
        _ = try? await evaluateJavaScript("stripeConnectInstance.logout()")
    }

    /// Convenience method to add `ScriptMessageHandler`
    func addMessageHandler(_ messageHandler: ScriptMessageHandler,
                           contentWorld: WKContentWorld = .page) {
        contentController.add(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }

    /// Convenience method to add `ScriptMessageHandlerWithReply`
    func addMessageHandler<T>(_ messageHandler: ScriptMessageHandlerWithReply<T>,
                              contentWorld: WKContentWorld = .page) {
        contentController.addScriptMessageHandler(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }
}

// MARK: - Private

private extension ComponentWebView {
    /// Registers JS -> Swift message handlers
    func registerMessageHandlers() {
        addMessageHandler(.init(name: "debug", didReceiveMessage: { message in
            debugPrint(message.body)
        }))
        addMessageHandler(.init(name: "fetchClientSecret", didReceiveMessage: { [weak self] _ in
            return await self?.connectInstance.fetchClientSecret()
        }))
    }

    /**
     Loads the contents of `template.html`, passing in appearance, componentType,
     and publishableKey, then spoofs it's coming from connect-js.stripe.com.

     - Note: This is a temporary hack. Long term, we should host this page on connect-js.stripe.com

     TODO: Delete this function before beta release
     */
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

        load(data, mimeType: "text/html", characterEncodingName: "utf8", baseURL: Self.baseURL)
    }

    /**
     Overlays a "Reload" button on top of the web view, for debug purposes only
     so the contents can be reloaded after connecting to the Safari debugger.
     
     - Note: This is only needed while we're implementing the hack to spoof
     `connect-js.stripe.com` mentioned in `loadContents` comments. The Safari 
     debugger has a reload button, however it currently loads `connect-js.stripe.com`
     instead of reloading `template.html`. Once this has been updated to use a
     remote web page, the refresh button in the Safari debugger will be sufficient.

     TODO: Delete this function before beta release
     */
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

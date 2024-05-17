//
//  ComponentWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(STP) import StripeCore
import UIKit
import WebKit

/// Wraps a `StripeComponentInstance`
class ConnectComponentWebView: ConnectWebView {
    private var connectInstance: StripeConnectInstance
    private var componentType: String

    /// The content controller that registers JS -> Swift message handlers
    private let contentController: WKUserContentController

    init(connectInstance: StripeConnectInstance,
         componentType: String,
         shouldUseHorizontalPadding: Bool = true) {
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

        addMessageHandlers()
        updateColors(connectInstance.appearance)
        addNotificationObservers()

        load(URLRequest(url: initialURL))

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Internal

extension ConnectComponentWebView {
    /// Calls `update({appearance: ...})` on the JS StripeConnectInstance
    func updateAppearance(_ appearance: StripeConnectInstance.Appearance) {
        evaluateJavaScript("""
            stripeConnectInstance.update({appearance: \(appearance.asJsonString)});
            document.body.setAttribute("style", "background-color:\(appearance.styleBackgroundColor);");
        """)
        updateColors(appearance)
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

private extension ConnectComponentWebView {
    /// Registers JS -> Swift message handlers
    func addMessageHandlers() {
        addMessageHandler(.init(name: "debug", didReceiveMessage: { message in
            debugPrint(message.body)
        }))
        addMessageHandler(.init(name: "fetchClientSecret", didReceiveMessage: { [weak self] _ in
            return await self?.connectInstance.fetchClientSecret()
        }))
        addMessageHandler(.init(name: "fetchAppearanceOptions", didReceiveMessage: { [weak self] _ in
            return self?.connectInstance.appearance.asJsonDictionary
        }))
        addMessageHandler(.init(name: "fetchFonts", didReceiveMessage: { [weak self] _ in
            return self?.connectInstance.customFonts.compactMap(\.asJsonDictionary)
        }))
    }

    /// Adds NotificationCenter observers
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluateJavaScript("stripeConnectInstance.update({locale: \(Locale.autoupdatingCurrent.webIdentifier)})")
        }
    }

    /// Updates the view's background color to match appearance.
    /// - Note: This avoids a white flash when initially loading the page when a background color is set
    func updateColors(_ appearance: StripeConnectInstance.Appearance) {
        isOpaque = appearance.colorBackground == nil
        backgroundColor = appearance.colorBackground ?? .systemBackground
    }

    /// Generates a URL with initial params
    var initialURL: URL {
        var components = URLComponents(url: StripeConnectConstants.connectWrapperURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            .init(name: "componentType", value: componentType),
            .init(name: "locale", value: Locale.autoupdatingCurrent.webIdentifier),
            .init(name: "publishableKey", value: connectInstance.apiClient.publishableKey),
        ]

        // Convert to hash-param instead of query-params
        let urlString = components.url!.absoluteString
            .replacingOccurrences(of: "?", with: "#")

        return URL(string: urlString)!
    }
}

extension Locale {
    /// iOS uses underscores for locale (`en_US`) but web uses hyphens (`en-US`)
    var webIdentifier: String {
        guard let region = stp_regionCode,
              let language = stp_languageCode else {
            return ""
        }
        return "\(language)-\(region)"
    }
}

//
//  ComponentWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(STP) import StripeCore
import UIKit
import WebKit

class ConnectComponentWebView: ConnectWebView {
    /// The embedded component manager that will be used for requests.
    var componentManager: EmbeddedComponentManager
    
    /// The component type that should be loaded.
    private var componentType: ComponentType

    /// The content controller that registers JS -> Swift message handlers
    private let contentController: WKUserContentController

    /// Represents the current locale that should get sent to the webview
    private let webLocale: Locale
    
    /// The current notification center instance
    private let notificationCenter: NotificationCenter
    
    init(componentManager: EmbeddedComponentManager,
         componentType: ComponentType,
         // Should only be overridden for tests
         notificationCenter: NotificationCenter = NotificationCenter.default,
         webLocale: Locale = Locale.autoupdatingCurrent,
         loadContent: Bool = true) {
        self.componentManager = componentManager
        self.componentType = componentType
        self.notificationCenter = notificationCenter
        self.webLocale = webLocale
        contentController = WKUserContentController()
        let config = WKWebViewConfiguration()

        // Allows for custom JS message handlers for JS -> Swift communication
        config.userContentController = contentController

        // Allows the identity verification flow to display the camera feed
        // embedded in the web view instead of full screen. Also works for
        // embedded YouTube videos.
        config.allowsInlineMediaPlayback = true

        super.init(frame: .zero, configuration: config)
        componentManager.registerChild(self)
        guard let publishableKey = componentManager.apiClient.publishableKey else {
            assertionFailure("A publishable key is required. For more info, see https://stripe.com/docs/keys")
            return
        }
        addMessageHandlers()
        addNotificationObservers()
        if loadContent {
            load(.init(url: StripeConnectConstants.connectJSURL(component: componentType.rawValue, publishableKey: publishableKey)))
        }
    }

    func updateAppearance(appearance: Appearance) {
        sendMessage(UpdateConnectInstanceSender.init(payload: .init(locale: webLocale.webIdentifier, appearance: .init(appearance: appearance, traitCollection: traitCollection))))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        DispatchQueue.main.async {
            self.updateAppearance(appearance: self.componentManager.appearance)
        }
    }
}

// MARK: - Internal

extension ConnectComponentWebView {
    /// Convenience method to add `ScriptMessageHandler`
    func addMessageHandler<Payload>(_ messageHandler: ScriptMessageHandler<Payload>,
                           contentWorld: WKContentWorld = .page) {
        contentController.add(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }

    /// Convenience method to add `ScriptMessageHandlerWithReply`
    func addMessageHandler<Payload, Response>(_ messageHandler: ScriptMessageHandlerWithReply<Payload, Response>,
                              contentWorld: WKContentWorld = .page) {
        contentController.addScriptMessageHandler(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }
    
    /// Convenience method to send messages to the webview.
    func sendMessage(_ sender: any MessageSender) {
        if let message = sender.javascriptMessage {
            evaluateJavaScript(message)
        }
    }
}

// MARK: - Private

private extension ConnectComponentWebView {
    /// Registers JS -> Swift message handlers
    func addMessageHandlers() {
        addMessageHandler(FetchInitParamsMessageHandler.init(didReceiveMessage: {[weak self] _ in
            guard let self else {
                stpAssertionFailure("Message received after web view was deallocated")
                // If self no longer exists give default values
                return .init(locale: "", appearance: .init(appearance: .default, traitCollection: .init()))
            }
            return .init(locale: webLocale.webIdentifier, appearance: .init(appearance: componentManager.appearance, traitCollection: traitCollection))
        }))
        addMessageHandler(DebugMessageHandler())
        addMessageHandler(FetchClientSecretMessageHandler { [weak self] _ in
            await self?.componentManager.fetchClientSecret()
        })
        addMessageHandler(PageDidLoadMessageHandler{_ in })
        addMessageHandler(AccountSessionClaimedMessageHandler{ message in
        })

    }

    /// Adds NotificationCenter observers
    func addNotificationObservers() {
        notificationCenter.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            sendMessage(UpdateConnectInstanceSender(payload: .init(locale: webLocale.webIdentifier, appearance: .init(appearance: componentManager.appearance, traitCollection: traitCollection))))
        }
    }
}

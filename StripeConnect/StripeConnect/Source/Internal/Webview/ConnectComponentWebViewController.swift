//
//  ConnectComponentWebViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
import WebKit

@available(iOS 15, *)
class ConnectComponentWebViewController: UIViewController {
    private(set) lazy var webView: ConnectWebView = {
        let config = WKWebViewConfiguration()

        // Allows for custom JS message handlers for JS -> Swift communication
        config.userContentController = contentController

        // Allows the identity verification flow to display the camera feed
        // embedded in the web view instead of full screen. Also works for
        // embedded YouTube videos.
        config.allowsInlineMediaPlayback = true

        return .init(frame: .zero, configuration: config)
    }()

    /// The embedded component manager that will be used for requests.
    let componentManager: EmbeddedComponentManager

    /// The component type that should be loaded.
    private let componentType: ComponentType

    /// The content controller that registers JS -> Swift message handlers
    private let contentController = WKUserContentController()

    /// Represents the current locale that should get sent to the webview
    private let webLocale: Locale

    /// The current notification center instance
    private let notificationCenter: NotificationCenter

    private let setterMessageHandler: OnSetterFunctionCalledMessageHandler = .init()

    private var didFailLoadWithError: (Error) -> Void

    let activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    init<InitProps: Encodable>(
        componentManager: EmbeddedComponentManager,
        componentType: ComponentType,
        fetchInitProps: @escaping () -> InitProps,
        didFailLoadWithError: @escaping (Error) -> Void,
        // Should only be overridden for tests
        notificationCenter: NotificationCenter = NotificationCenter.default,
        webLocale: Locale = Locale.autoupdatingCurrent,
        loadContent: Bool = true
    ) {
        self.componentManager = componentManager
        self.componentType = componentType
        self.notificationCenter = notificationCenter
        self.webLocale = webLocale
        self.didFailLoadWithError = didFailLoadWithError

        super.init(nibName: nil, bundle: nil)

        // Setup views
        webView.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: webView.centerYAnchor),
        ])

        // Colors
        updateColors(appearance: componentManager.appearance)

        // Register webView callbacks
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
        webView.didLoadWithError = { [weak self] error in
            self?.didFailLoad(error: error)
        }

        // Register observers
        componentManager.registerChild(self)
        addMessageHandlers(fetchInitProps: fetchInitProps)
        addNotificationObservers()

        // Load the web page
        if loadContent {
            activityIndicator.startAnimating()
            let url = ConnectJSURLParams(component: componentType, apiClient: componentManager.apiClient).url
            webView.load(.init(url: url))
        }
    }

    /// Convenience init for empty init props
    convenience init(componentManager: EmbeddedComponentManager,
                     componentType: ComponentType,
                     didFailLoadWithError: @escaping (Error) -> Void,
                     // Should only be overridden for tests
                     notificationCenter: NotificationCenter = NotificationCenter.default,
                     webLocale: Locale = Locale.autoupdatingCurrent,
                     loadContent: Bool = true) {
        self.init(componentManager: componentManager,
                  componentType: componentType,
                  fetchInitProps: VoidPayload.init,
                  didFailLoadWithError: didFailLoadWithError,
                  notificationCenter: notificationCenter,
                  webLocale: webLocale,
                  loadContent: loadContent)
    }
    func updateAppearance(appearance: Appearance) {
        sendMessage(UpdateConnectInstanceSender.init(payload: .init(locale: webLocale.toLanguageTag(), appearance: .init(appearance: appearance, traitCollection: traitCollection))))
        updateColors(appearance: appearance)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = webView
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        DispatchQueue.main.async {
            self.updateAppearance(appearance: self.componentManager.appearance)
        }
    }
}

// MARK: - Internal

@available(iOS 15, *)
extension ConnectComponentWebViewController {
    /// Convenience method to add `ScriptMessageHandler`
    func addMessageHandler<Payload>(_ messageHandler: ScriptMessageHandler<Payload>,
                                    contentWorld: WKContentWorld = .page) {
        contentController.add(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }

    func addMessageHandler(_ handler: OnSetterFunctionCalledMessageHandler.Handler) {
        setterMessageHandler.addHandler(handler: handler)
    }

    /// Convenience method to add `ScriptMessageHandlerWithReply`
    func addMessageHandler<Payload, Response>(_ messageHandler: ScriptMessageHandlerWithReply<Payload, Response>,
                                              contentWorld: WKContentWorld = .page) {
        contentController.addScriptMessageHandler(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }

    /// Convenience method to send messages to the webview.
    func sendMessage(_ sender: any MessageSender) {
        if let message = sender.javascriptMessage {
            webView.evaluateJavaScript(message)
        }
    }
}

// MARK: - Private

@available(iOS 15, *)
private extension ConnectComponentWebViewController {
    /// Registers JS -> Swift message handlers
    func addMessageHandlers<InitProps: Encodable>(
        fetchInitProps: @escaping () -> InitProps
    ) {
        addMessageHandler(setterMessageHandler)
        addMessageHandler(OnLoaderStartMessageHandler { [activityIndicator] _ in
            activityIndicator.stopAnimating()
        })
        addMessageHandler(FetchInitParamsMessageHandler.init(didReceiveMessage: {[weak self] _ in
            guard let self else {
                stpAssertionFailure("Message received after web view was deallocated")
                // If self no longer exists give default values
                return .init(locale: "", appearance: .init(appearance: .default, traitCollection: .init()))
            }
            return .init(locale: webLocale.toLanguageTag(),
                         appearance: .init(appearance: componentManager.appearance, traitCollection: self.traitCollection),
                         fonts: componentManager.fonts.map({ .init(customFontSource: $0) }))
        }))
        addMessageHandler(FetchInitComponentPropsMessageHandler(fetchInitProps))
        addMessageHandler(OnLoadErrorMessageHandler { [weak self] value in
            self?.didFailLoad(error: value.error.connectEmbedError)
        })
        addMessageHandler(DebugMessageHandler())
        addMessageHandler(FetchClientSecretMessageHandler { [weak self] _ in
            await self?.componentManager.fetchClientSecret()
        })
        addMessageHandler(PageDidLoadMessageHandler { _ in
            // TODO: MXMOBILE-2491 Use this for analytics
        })
        addMessageHandler(AccountSessionClaimedMessageHandler{ _ in
            // TODO: MXMOBILE-2491 Use this for analytics
        })
    }

    /// Adds NotificationCenter observers
    func addNotificationObservers() {
        notificationCenter.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // swiftlint:disable:previous unused_capture_list
            guard let self else { return }
            sendMessage(UpdateConnectInstanceSender(payload: .init(locale: webLocale.toLanguageTag(), appearance: .init(appearance: componentManager.appearance, traitCollection: traitCollection))))
        }
    }

    func updateColors(appearance: Appearance) {
        webView.backgroundColor = appearance.colors.background
        webView.isOpaque = webView.backgroundColor == nil
        activityIndicator.tintColor = appearance.colors.loadingIndicatorColor
    }

    func didFailLoad(error: Error) {
        didFailLoadWithError(error)
        activityIndicator.stopAnimating()
    }
}

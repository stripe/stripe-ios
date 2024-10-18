//
//  ConnectComponentWebViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(STP) import StripeCore
import StripeFinancialConnections
@_spi(STP) import StripeUICore
import UIKit
import WebKit

@available(iOS 15, *)
class ConnectComponentWebViewController: ConnectWebViewController {

    /// The embedded component manager that will be used for requests.
    let componentManager: EmbeddedComponentManager

    /// The content controller that registers JS -> Swift message handlers
    private let contentController = WKUserContentController()

    /// Represents the current locale that should get sent to the webview
    private let webLocale: Locale

    /// The current notification center instance
    private let notificationCenter: NotificationCenter

    /// Manages authenticated web views
    private let authenticatedWebViewManager: AuthenticatedWebViewManager

    /// Presents the FinancialConnectionsSheet
    private let financialConnectionsPresenter: FinancialConnectionsPresenter

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
        loadContent: Bool,
        fetchInitProps: @escaping () -> InitProps,
        didFailLoadWithError: @escaping (Error) -> Void,
        // Should only be overridden for tests
        notificationCenter: NotificationCenter = NotificationCenter.default,
        webLocale: Locale = Locale.autoupdatingCurrent,
        authenticatedWebViewManager: AuthenticatedWebViewManager = .init(),
        financialConnectionsPresenter: FinancialConnectionsPresenter = .init()
    ) {
        self.componentManager = componentManager
        self.notificationCenter = notificationCenter
        self.webLocale = webLocale
        self.authenticatedWebViewManager = authenticatedWebViewManager
        self.didFailLoadWithError = didFailLoadWithError
        self.financialConnectionsPresenter = financialConnectionsPresenter

        let config = WKWebViewConfiguration()

        // Allows for custom JS message handlers for JS -> Swift communication
        config.userContentController = contentController

        // Allows the identity verification flow to display the camera feed
        // embedded in the web view instead of full screen. Also works for
        // embedded YouTube videos.
        config.allowsInlineMediaPlayback = true

        super.init(configuration: config)

        // Setup views
        webView.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: webView.centerYAnchor),
        ])

        // Colors
        updateColors(appearance: componentManager.appearance)

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
                     loadContent: Bool,
                     didFailLoadWithError: @escaping (Error) -> Void,
                     // Should only be overridden for tests
                     notificationCenter: NotificationCenter = NotificationCenter.default,
                     webLocale: Locale = Locale.autoupdatingCurrent,
                     authenticatedWebViewManager: AuthenticatedWebViewManager = .init(),
                     financialConnectionsPresenter: FinancialConnectionsPresenter = .init()) {
        self.init(componentManager: componentManager,
                  componentType: componentType,
                  loadContent: loadContent,
                  fetchInitProps: VoidPayload.init,
                  didFailLoadWithError: didFailLoadWithError,
                  notificationCenter: notificationCenter,
                  webLocale: webLocale,
                  authenticatedWebViewManager: authenticatedWebViewManager,
                  financialConnectionsPresenter: financialConnectionsPresenter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async {
            self.updateAppearance(appearance: self.componentManager.appearance)
        }
    }

    // MARK: - ConnectWebViewController

    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        super.webView(webView, didFail: navigation, withError: error)
        didFailLoad(error: error)
        // TODO: MXMOBILE-2491 log error
    }

    override func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        if let response = navigationResponse.response as? HTTPURLResponse,
           response.hasErrorStatus {
            didFailLoad(error: HTTPStatusError(errorCode: response.statusCode))
            // TODO: MXMOBILE-2491 log error
        }

        return await super.webView(webView, decidePolicyFor: navigationResponse)
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

    func updateAppearance(appearance: Appearance) {
        sendMessage(UpdateConnectInstanceSender.init(payload: .init(locale: webLocale.toLanguageTag(), appearance: .init(appearance: appearance, traitCollection: traitCollection))))
        updateColors(appearance: appearance)
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
        addMessageHandler(OpenAuthenticatedWebViewMessageHandler { [weak self] payload in
            self?.openAuthenticatedWebView(payload)
        })
        addMessageHandler(OpenFinancialConnectionsMessageHandler(didReceiveMessage: { [weak self] payload in
            self?.openFinancialConnections(payload)
        }))
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

    /// Opens the url in the given payload in an ASWebAuthenticationSession and sends the resulting redirect to
    func openAuthenticatedWebView(_ payload: OpenAuthenticatedWebViewMessageHandler.Payload) {
        Task { @MainActor in
            do {
                // TODO: MXMOBILE-2491 log `component.authenticated_web.*` analytic
                let returnUrl = try await authenticatedWebViewManager.present(with: payload.url, from: view)

                sendMessage(ReturnedFromAuthenticatedWebViewSender(payload: .init(url: returnUrl, id: payload.id)))
            } catch {
                // TODO: MXMOBILE-2491 log `component.authenticated_web.error` analytic
                debugPrint("Error returning from authenticated web view: \(error)")
            }
        }
    }

    func openFinancialConnections(_ args: OpenFinancialConnectionsMessageHandler.Payload) {
        Task { @MainActor in
            let result = await financialConnectionsPresenter.presentForToken(
                apiClient: componentManager.apiClient,
                clientSecret: args.clientSecret,
                from: self
            )

            var token: String?
            // TODO: MXMOBILE-2491 Log these as errors instead of printing to console

            switch result {
            case .completed(result: (_, let returnedToken)):
                token = returnedToken?.id
                if returnedToken == nil {
                    debugPrint("Error using FinancialConnections: no bank token returned")
                }
            case .failed(let error):
                debugPrint("Error using FinancialConnections: \(error)")
            case .canceled:
                // No-op
                break
            }

            sendMessage(ReturnedFromFinancialConnectionsSender(payload: .init(bankToken: token, id: args.id)))
        }
    }
}

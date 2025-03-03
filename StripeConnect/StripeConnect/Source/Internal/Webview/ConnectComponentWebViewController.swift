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

    var onDismiss: (() -> Void)?

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

    private lazy var setterMessageHandler: OnSetterFunctionCalledMessageHandler = .init(analyticsClient: analyticsClient)

    private var didFailLoadWithError: (Error) -> Void

    private var pageLoaded: Bool = false

    let activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    var errorScreen: WebViewErrorScreen?

    init<InitProps: Encodable>(
        componentManager: EmbeddedComponentManager,
        componentType: ComponentType,
        loadContent: Bool,
        analyticsClientFactory: ComponentAnalyticsClientFactory,
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
        let allowedHosts = (StripeConnectConstants.allowedHosts + [self.componentManager.baseURL.host]).compactMap({ $0 })
        let analyticsClient = analyticsClientFactory(.init(
            params: ConnectJSURLParams(component: componentType, apiClient: componentManager.apiClient, publicKeyOverride: componentManager.publicKeyOverride)))
        super.init(
            configuration: config,
            analyticsClient: analyticsClient,
            allowedHosts: allowedHosts
        )

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

        // Log created event
        analyticsClient.log(event: ComponentCreatedEvent())

        // Load the web page
        if loadContent {
            activityIndicator.startAnimating()
            do {
                let url = try ConnectJSURLParams(component: componentType, apiClient: componentManager.apiClient, publicKeyOverride: componentManager.publicKeyOverride).url(baseURL: componentManager.baseURL)
                analyticsClient.loadStart = .now
                webView.load(.init(url: url))
            } catch {
                showAlertAndLog(error: error)
            }
        }
    }

    /// Convenience init for empty init props
    convenience init(componentManager: EmbeddedComponentManager,
                     componentType: ComponentType,
                     loadContent: Bool,
                     analyticsClientFactory: ComponentAnalyticsClientFactory,
                     didFailLoadWithError: @escaping (Error) -> Void,
                     // Should only be overridden for tests
                     notificationCenter: NotificationCenter = NotificationCenter.default,
                     webLocale: Locale = Locale.autoupdatingCurrent,
                     authenticatedWebViewManager: AuthenticatedWebViewManager = .init(),
                     financialConnectionsPresenter: FinancialConnectionsPresenter = .init()) {
        self.init(componentManager: componentManager,
                  componentType: componentType,
                  loadContent: loadContent,
                  analyticsClientFactory: analyticsClientFactory,
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analyticsClient.logComponentViewed(viewedAt: .now)
    }

    // MARK: - ConnectWebViewController

    override func webViewDidFinishNavigation(to url: URL?) {
        super.webViewDidFinishNavigation(to: url)

        guard let url,
              url.absoluteStringRemovingParams == componentManager.baseURL.absoluteString else {
            analyticsClient.log(event: UnexpectedNavigationEvent(metadata: .init(url: url)))
            return
        }
        analyticsClient.logComponentWebPageLoaded(loadEnd: .now)
    }

    override func webViewDidFailNavigation(withError error: any Error) {
        super.webViewDidFailNavigation(withError: error)

        showErrorScreenIfNeeded()

        didFailLoad(error: error)
        analyticsClient.log(event: PageLoadErrorEvent(metadata: .init(
            error: error,
            url: webView.url
        )))
    }

    override func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        // If the component web page fails to load with an HTTP error, send a
        // load failure to event
        if let response = navigationResponse.response as? HTTPURLResponse,
           response.url?.absoluteStringRemovingParams == componentManager.baseURL.absoluteString,
           response.hasErrorStatus {
            let error = HTTPStatusError(errorCode: response.statusCode)
            didFailLoad(error: error)
            analyticsClient.log(event: PageLoadErrorEvent(metadata: .init(
                error: error,
                url: response.url
            )))
        }

        return await super.webView(webView, decidePolicyFor: navigationResponse)
    }

    // If the component fails to load entirely we show a native error screen
    // if the component has loaded then it's the component's responsibility to display the error.
    func showErrorScreenIfNeeded() {
        guard !pageLoaded else { return }
        let errorScreen = WebViewErrorScreen(title: STPLocalizedString(
            "Something went wrong.",
            "Title for error message when component fails to load"
        ), subtitle: STPLocalizedString(
            "Please check your connection or try again later.",
            "Subtitle for error message when component fails to load indicating there may be an issue with the internet connection."
        ), appearance: componentManager.appearance)
        self.view.addSubview(errorScreen)
        errorScreen.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorScreen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorScreen.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
        self.errorScreen = errorScreen
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

    func sendMessageAsync(_ sender: any MessageSender) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let message = try sender.javascriptMessage()
                webView.evaluateJavaScript(message, completionHandler: { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                })
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Convenience method to send messages to the webview.
    func sendMessage(_ sender: any MessageSender) {
        Task { @MainActor in
            do {
                try await sendMessageAsync(sender)
            } catch {
                analyticsClient.logClientError(error)
            }
        }
    }

    func updateAppearance(appearance: Appearance) {
        sendMessage(UpdateConnectInstanceSender.init(payload: .init(locale: webLocale.toLanguageTag(), appearance: .init(appearance: appearance, traitCollection: traitCollection))))
        updateColors(appearance: appearance)
        errorScreen?.updateAppearance(appearance)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            onDismiss?()
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
        addMessageHandler(OnLoaderStartMessageHandler { [analyticsClient, activityIndicator] _ in
            analyticsClient.logComponentLoaded(loadEnd: .now)
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
        addMessageHandler(OnLoadErrorMessageHandler { [weak self, analyticsClient] value in
            self?.didFailLoad(error: value.error.connectEmbedError(analyticsClient: analyticsClient))
        })
        addMessageHandler(DebugMessageHandler(analyticsClient: analyticsClient))
        addMessageHandler(FetchClientSecretMessageHandler { [weak self] _ in
            await self?.componentManager.fetchClientSecret()
        })
        addMessageHandler(PageDidLoadMessageHandler(analyticsClient: analyticsClient) { [weak self] payload in
            guard let self else { return }
            self.pageLoaded = true
            errorScreen?.removeFromSuperview()
            errorScreen = nil
            self.analyticsClient.pageViewId = payload.pageViewId
        })
        addMessageHandler(AccountSessionClaimedMessageHandler(analyticsClient: analyticsClient) { [analyticsClient] payload in
            analyticsClient.merchantId = payload.merchantId
            analyticsClient.logAccountSessionClaimed()
        })
        addMessageHandler(OpenAuthenticatedWebViewMessageHandler(analyticsClient: analyticsClient) { [weak self] payload in
            self?.openAuthenticatedWebView(payload)
        })
        addMessageHandler(OpenFinancialConnectionsMessageHandler(analyticsClient: analyticsClient) { [weak self] payload in
            self?.openFinancialConnections(payload)
        })
        addMessageHandler(CloseWebViewMessageHandler(analyticsClient: analyticsClient, didReceiveMessage: { [weak self] _ in
            self?.dismiss(animated: true)
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
        self.view.backgroundColor = appearance.colors.background
        webView.backgroundColor = appearance.colors.background
        webView.isOpaque = webView.backgroundColor == nil
        activityIndicator.tintColor = appearance.colors.loadingIndicatorColor

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        if let backgroundColor = appearance.colors.background {
            navAppearance.backgroundColor = backgroundColor
        }
        var titleAttributes: [NSAttributedString.Key: Any]  = [:]
        if let textColor = appearance.colors.text {
            titleAttributes[.foregroundColor] = textColor
        }
        if let font = appearance.typography.font {
            titleAttributes[.font] = font
        }
        navAppearance.titleTextAttributes = titleAttributes
        self.navigationController?.navigationBar.standardAppearance = navAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = navAppearance
    }

    func didFailLoad(error: Error) {
        didFailLoadWithError(error)
        activityIndicator.stopAnimating()
    }

    /// Opens the url in the given payload in an ASWebAuthenticationSession and sends the resulting redirect to
    func openAuthenticatedWebView(_ payload: OpenAuthenticatedWebViewMessageHandler.Payload) {
        Task { @MainActor in
            do {
                analyticsClient.logAuthenticatedWebViewOpenedEvent(id: payload.id)

                let returnUrl = try await authenticatedWebViewManager.present(with: payload.url, from: view)

                analyticsClient.logAuthenticatedWebViewEventComplete(id: payload.id, redirected: returnUrl != nil)

                sendMessage(ReturnedFromAuthenticatedWebViewSender(payload: .init(url: returnUrl, id: payload.id)))
            } catch {
                analyticsClient.logAuthenticatedWebViewEventComplete(id: payload.id, error: error)
            }
        }
    }

    func openFinancialConnections(_ args: OpenFinancialConnectionsMessageHandler.Payload) {
        Task { @MainActor in
            let result = await financialConnectionsPresenter.presentForToken(
                componentManager: componentManager,
                clientSecret: args.clientSecret,
                connectedAccountId: args.connectedAccountId,
                from: self
            )

            sendMessage(SetCollectMobileFinancialConnectionsResult.sender(
                value: result.toSenderValue(id: args.id, analyticsClient: analyticsClient)
            ))
        }
    }
}

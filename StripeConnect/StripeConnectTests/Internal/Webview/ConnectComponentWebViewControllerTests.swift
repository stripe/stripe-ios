//
//  ConnectComponentWebViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/20/24.
//

import Foundation
import SafariServices
@_spi(DashboardOnly) @_spi(PrivateBetaConnect) @testable import StripeConnect
@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnections
@_spi(STP) import StripeUICore
import WebKit
import XCTest

class ConnectComponentWebViewControllerTests: XCTestCase {

    typealias FontSource = EmbeddedComponentManager.CustomFontSource

    @MainActor
    func testFetchClientSecret() async throws {
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: {
            return "test"
        })
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })

        try await webVC.webView.evaluateMessageWithReply(name: "fetchClientSecret",
                                                         json: "{}",
                                                         expectedResponse: "test")
    }

    @MainActor
    func testFetchInitParams() async throws {
        let message = FetchInitParamsMessageHandler.Reply(locale: "fr-FR", appearance: .default)
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      webLocale: Locale(identifier: "fr_FR"))

        try await webVC.webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                         json: "{}",
                                                         expectedResponse: message)
    }

    @MainActor
    func testUpdateAppearance() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      webLocale: Locale(identifier: "fr_FR"))
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.spacingUnit = 5
        let expectation = try webVC.webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(
            locale: "fr-FR",
            appearance: .init(appearance: appearance, traitCollection: UITraitCollection()))
        ))
        componentManager.update(appearance: appearance)

        // Ensures the appearance on component manager was set.
        XCTAssertEqual(appearance.asDictionary(traitCollection: .init()), componentManager.appearance.asDictionary(traitCollection: .init()))

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitParamsTraitCollection() async throws {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.colors.actionPrimaryText = UIColor { $0.userInterfaceStyle == .light ? .black : .white }

        let componentManager = componentManagerAssertingOnFetch(appearance: appearance)

        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      webLocale: Locale(identifier: "fr_FR"))

        webVC.triggerTraitCollectionChange(style: .dark)

        try await webVC.webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                         json: "{}",
                                                         expectedResponse: """
            {"appearance":{"variables":{"actionPrimaryColorText":"rgb(255, 255, 255)","fontFamily":"-apple-system","fontSizeBase":"16px"}},"fonts":[],"locale":"fr-FR"}
            """)
    }

    @MainActor
    func testFetchInitComponentPropsMessageHandler() async throws {
        let componentManager = componentManagerAssertingOnFetch()

        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      webLocale: Locale(identifier: "fr_FR"))

        try await webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                         json: "{}",
                                                         expectedResponse: "{}")
    }

    @MainActor
    func testUpdateTraitCollection() async throws {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.colors.actionPrimaryText = UIColor { $0.userInterfaceStyle == .light ? .red : .green }

        let componentManager = componentManagerAssertingOnFetch(appearance: appearance)

        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      webLocale: Locale(identifier: "fr_FR"))

        let expectation = try webVC.webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(
            locale: "fr-FR",
            appearance: .init(appearance: appearance, traitCollection: UITraitCollection(userInterfaceStyle: .dark))
        )))

        webVC.triggerTraitCollectionChange(style: .dark)

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testLocale() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let notificationCenter = NotificationCenter()
        let webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .payouts,
            loadContent: false,
            analyticsClientFactory: MockComponentAnalyticsClient.init,
            didFailLoadWithError: { _ in },
            notificationCenter: notificationCenter,
            webLocale: Locale(identifier: "fr_FR"))

        let expectation = try webVC.webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(locale: "fr-FR", appearance: .default)))

        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitParamsWithFontSource() async throws {
        let testBundle = Bundle(for: type(of: self))
        let fileURL = try XCTUnwrap(testBundle.url(forResource: "FakeFont", withExtension: "txt"))
        let fontSource = try FontSource(font: .systemFont(ofSize: 12), fileUrl: fileURL)
        let componentManager = componentManagerAssertingOnFetch(fonts: [fontSource])
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      webLocale: Locale(identifier: "fr_FR"))

        try await webVC.webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                         json: "{}",
                                                         expectedResponse: """
                                                            {"appearance":{"variables":{"fontFamily":"-apple-system","fontSizeBase":"16px"}},"fonts":[{"family":".AppleSystemUIFont","src":"url(data:font\\/txt;charset=utf-8;base64,dGVzdAo=)","weight":"400"}],"locale":"fr-FR"}
                                                            """)
    }

    @MainActor
    func testLoaderStartShowsLoadingIndicator() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        // Mock that loading indicator is animating
        webVC.activityIndicator.startAnimating()

        try await webVC.webView.evaluateOnLoaderStart(elementTagName: "payouts")

        // Loading indicator should stop
        XCTAssertFalse(webVC.activityIndicator.isAnimating)
    }

    // MARK: - Errors

    @MainActor
    func testJSOnLoadError() async throws {
        var error: Error?
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { error = $0 })
        // Mock that loading indicator is animating
        webVC.activityIndicator.startAnimating()
        try await webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
        XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
        // Loading indicator should stop
        XCTAssertFalse(webVC.activityIndicator.isAnimating)
    }

    func testDidFailNavigationTriggersLoadError() {
        var error: Error?
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { error = $0 })
        // Mock that loading indicator is animating
        webVC.activityIndicator.startAnimating()
        webVC.webView.navigationDelegate?.webView?(webVC.webView, didFail: nil, withError: NSError(domain: "test_domain", code: 111))
        XCTAssertEqual((error as NSError?)?.domain, "test_domain")
        XCTAssertEqual((error as NSError?)?.code, 111)
        // Loading indicator should stop
        XCTAssertFalse(webVC.activityIndicator.isAnimating)
    }

    @MainActor
    func testDidReceiveNon200StatusTriggersLoadError() async {
        var error: Error?
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { error = $0 })
        _ = await webVC.webView(webVC.webView, decidePolicyFor: MockNavigationResponse(response: HTTPURLResponse(url: URL(string: "https://connect-js.stripe.com/v1.0/ios_webview.html")!, statusCode: 404, httpVersion: nil, headerFields: nil)!))
        XCTAssertEqual((error as? HTTPStatusError)?.errorCode, 404)
        // Loading indicator should stop
        XCTAssertFalse(webVC.activityIndicator.isAnimating)
    }

    // MARK: - Authenticated Web View

    @MainActor
    func testOpenAuthenticatedWebView() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let authenticatedWebViewManager = MockAuthenticatedWebViewManager { url, _ in
            XCTAssertEqual(url.absoluteString, "https://stripe.com/start")
            return URL(string: "stripe-connect://return_url")!
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      authenticatedWebViewManager: authenticatedWebViewManager)

        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: ReturnedFromAuthenticatedWebViewSender(payload: .init(
                url: URL(string: "stripe-connect://return_url"),
                id: "1234"
            ))
        )

        try await webVC.webView.evaluateOpenAuthenticatedWebView(url: "https://stripe.com/start", id: "1234")

        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient
        let openEvent = try analyticsClient.lastEvent(ofType: AuthenticatedWebViewOpenedEvent.self)
        XCTAssertEqual(openEvent.metadata.authenticatedWebViewId, "1234")

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)

        let redirectEvent = try analyticsClient.lastEvent(ofType: AuthenticatedWebViewRedirectedEvent.self)
        XCTAssertEqual(redirectEvent.metadata.authenticatedWebViewId, "1234")
    }

    @MainActor
    func testAuthenticatedWebViewCanceled() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let authenticatedWebViewManager = MockAuthenticatedWebViewManager { _, _ in
            return nil
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      authenticatedWebViewManager: authenticatedWebViewManager)

        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: ReturnedFromAuthenticatedWebViewSender(payload: .init(
                url: nil,
                id: "1234"
            ))
        )

        try await webVC.webView.evaluateOpenAuthenticatedWebView(url: "https://stripe.com/start", id: "1234")

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)

        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient
        let event = try analyticsClient.lastEvent(ofType: AuthenticatedWebViewCanceledEvent.self)
        XCTAssertEqual(event.metadata.authenticatedWebViewId, "1234")
    }

    @MainActor
    func testAuthenticatedWebViewErrored() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let authenticatedWebViewManager = MockAuthenticatedWebViewManager { _, _ in
            throw NSError(domain: "test_domain", code: 123)
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      authenticatedWebViewManager: authenticatedWebViewManager)

        try await webVC.webView.evaluateOpenAuthenticatedWebView(url: "https://stripe.com/start", id: "1234")

        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient
        let event = try analyticsClient.lastEvent(ofType: AuthenticatedWebViewErrorEvent.self)
        XCTAssertEqual(event.metadata.authenticatedWebViewId, "1234")
        XCTAssertEqual(event.metadata.error, "test_domain:123")
    }

    // MARK: - Analytics

    @MainActor
    func testLifecycleAnalytics() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient

        XCTAssertEqual(analyticsClient.loggedEvents.count, 1)
        XCTAssertEqual(analyticsClient.loggedEvents.last, ComponentCreatedEvent())

        // Mock that load started 10s ago
        analyticsClient.loadStart = .now.addingTimeInterval(-10)

        // Mock component is viewed
        webVC.viewDidAppear(true)
        XCTAssertEqual(analyticsClient.loggedEvents.count, 2)
        XCTAssertEqual(analyticsClient.loggedEvents.last, ComponentViewedEvent())

        // Mock that web page loads
        webVC.webViewDidFinishNavigation(to: StripeConnectConstants.connectJSBaseURL)
        XCTAssertEqual(analyticsClient.loggedEvents.count, 3)
        let pageLoadedEvent = try XCTUnwrap(analyticsClient.loggedEvents.last as? ComponentWebPageLoadedEvent)
        XCTAssertEqual(pageLoadedEvent.metadata.timeToLoad, 10, accuracy: 1.0)

        // Mock pageDidLoad event returns with ID
        try await webVC.webView.evaluatePageDidLoad(pageViewId: "1234")
        XCTAssertEqual(webVC.analyticsClient.pageViewId, "1234")

        // Mock that component loads
        try await webVC.webView.evaluateOnLoaderStart(elementTagName: "payouts")
        XCTAssertEqual(analyticsClient.loggedEvents.count, 4)
        let componentLoadedEvent = try XCTUnwrap(analyticsClient.loggedEvents.last as? ComponentLoadedEvent)
        XCTAssertEqual(componentLoadedEvent.metadata.timeToLoad, 10, accuracy: 1.0)
        XCTAssertEqual(componentLoadedEvent.metadata.pageViewId, "1234")
    }

    @MainActor
    func testAccountSessionClaimedSetsAnalyticMerchantId() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        try await webVC.webView.evaluateAccountSessionClaimed(merchantId: "acct_123")
        XCTAssertEqual(webVC.analyticsClient.merchantId, "acct_123")
    }

    @MainActor
    func testUnexpectedLoadErrorTypeAnalytic() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        try await webVC.webView.evaluateOnLoadError(type: "unexpected_error_type", message: "Error message")

        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient
        let event = try analyticsClient.lastEvent(ofType: UnexpectedLoadErrorTypeEvent.self)
        XCTAssertEqual(event.metadata.errorType, "unexpected_error_type")
    }

    @MainActor
    func testUnrecognizedSetterFunctionAnalytic() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        try await webVC.webView.evaluateMessage(name: "onSetterFunctionCalled",
                                                json: """
                                                {
                                                    "setter": "unknownSetter"
                                                }
                                                """)
        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient
        let event = try analyticsClient.lastEvent(ofType: UnrecognizedSetterEvent.self)
        XCTAssertEqual(event.metadata.setter, "unknownSetter")
    }

    @MainActor
    func testAllowedHosts() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        XCTAssertEqual(webVC.allowedHosts, StripeConnectConstants.allowedHosts + ["connect-js.stripe.com"])
    }

    @MainActor
    func testAllowedHostsWithModifiedBaseURL() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        componentManager.baseURL = URL(string: "https://test.stripe.com")!
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        XCTAssertEqual(webVC.allowedHosts, StripeConnectConstants.allowedHosts + ["test.stripe.com"])
    }

    @MainActor
    func testUnexpectedPageLoadAnalytic() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in })
        let analyticsClient = webVC.analyticsClient as! MockComponentAnalyticsClient

        // Mock that web page navigates to a URL that isn't the component wrapper
        webVC.webViewDidFinishNavigation(to: URL(string: "https://stripe.com?query=to#sanitize"))

        let event = try analyticsClient.lastEvent(ofType: UnexpectedNavigationEvent.self)
        XCTAssertEqual(event.metadata.url, "https://stripe.com")
    }

   // MARK: - openFinancialConnections

    func testOpenFinancialConnections_success() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let session = try FinancialConnectionsSessionMock.default.make()

        let financialConnectionsPresenter = MockFinancialConnectionsPresenter { compManager, secret, connectedAccountId, vc in
            XCTAssert(compManager.apiClient == componentManager.apiClient)
            XCTAssert(compManager.publicKeyOverride == componentManager.publicKeyOverride)
            XCTAssertEqual(secret, "client_secret_123")
            XCTAssertEqual(connectedAccountId, "acct_1234")
            XCTAssert(vc is ConnectComponentWebViewController)

            return .completed(session: session)
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      financialConnectionsPresenter: financialConnectionsPresenter)

        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: SetCollectMobileFinancialConnectionsResult
                .sender(value: .init(
                    id: "5678",
                    financialConnectionsSession: .init(accounts: session.accounts.data),
                    token: session.bankAccountToken,
                    error: nil
                ))
        )

        webVC.webView.evaluateOpenFinancialConnectionsWebView(
            clientSecret: "client_secret_123",
            id: "5678",
            connectedAccountId: "acct_1234"
        )

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    func testOpenFinancialConnections_canceled() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let financialConnectionsPresenter = MockFinancialConnectionsPresenter { _, _, _, _ in
            return .canceled
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      financialConnectionsPresenter: financialConnectionsPresenter)
        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: SetCollectMobileFinancialConnectionsResult
                .sender(value: .init(
                    id: "5678",
                    financialConnectionsSession: .init(accounts: []),
                    token: nil,
                    error: nil
                ))
        )

        webVC.webView.evaluateOpenFinancialConnectionsWebView(
            clientSecret: "client_secret_123",
            id: "5678",
            connectedAccountId: "acct_1234"
        )

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    func testOpenFinancialConnections_error() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let financialConnectionsPresenter = MockFinancialConnectionsPresenter { _, _, _, _ in
            return .failed(error: NSError(domain: "mock_error", code: 0))
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      analyticsClientFactory: MockComponentAnalyticsClient.init,
                                                      didFailLoadWithError: { _ in },
                                                      financialConnectionsPresenter: financialConnectionsPresenter)
        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: SetCollectMobileFinancialConnectionsResult
                .sender(value: .init(
                    id: "5678",
                    financialConnectionsSession: nil,
                    token: nil,
                    error: nil
                ))
        )

        webVC.webView.evaluateOpenFinancialConnectionsWebView(
            clientSecret: "client_secret_123",
            id: "5678",
            connectedAccountId: "acct_1234"
        )

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}

// MARK: - Helpers

private extension ConnectComponentWebViewControllerTests {
    func componentManagerAssertingOnFetch(appearance: Appearance = .default, fonts: [EmbeddedComponentManager.CustomFontSource] = []) -> EmbeddedComponentManager {
        EmbeddedComponentManager(apiClient: .init(publishableKey: "test"),
                                 appearance: appearance,
                                 fonts: fonts,
                                 fetchClientSecret: {
            XCTFail("Client secret should not be retrieved in this test")
            return ""
        })
    }
}

private class MockAuthenticatedWebViewManager: AuthenticatedWebViewManager {
    var overridePresent: (_ url: URL, _ view: UIView) async throws -> URL?

    init(overridePresent: @escaping (_ url: URL, _ view: UIView) async throws -> URL?) {
        self.overridePresent = overridePresent
        super.init()
    }

    @MainActor
    override func present(with url: URL, from view: UIView) async throws -> URL? {
        try await overridePresent(url, view)
    }
}

private class MockFinancialConnectionsPresenter: FinancialConnectionsPresenter {
    var overridePresentForToken: (
        _ componentManager: EmbeddedComponentManager,
        _ clientSecret: String,
        _ connectedAccountId: String,
        _ presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult

    init(overridePresentForToken: @escaping (
        _ componentManager: EmbeddedComponentManager,
        _ clientSecret: String,
        _ connectedAccountId: String,
        _ presentingViewController: UIViewController
    ) -> FinancialConnectionsSheet.TokenResult) {
        self.overridePresentForToken = overridePresentForToken
    }

    override func presentForToken(
        componentManager: EmbeddedComponentManager,
        clientSecret: String,
        connectedAccountId: String,
        from presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult {
        await overridePresentForToken(componentManager, clientSecret, connectedAccountId, presentingViewController)
    }
}

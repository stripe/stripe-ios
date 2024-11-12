//
//  ConnectComponentWebViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/20/24.
//

import SafariServices
@_spi(PrivateBetaConnect) @testable import StripeConnect
@_spi(STP) import StripeCore
@testable import StripeFinancialConnections
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
                                                      didFailLoadWithError: { _ in })
        // Mock that loading indicator is animating
        webVC.activityIndicator.startAnimating()

        try await webVC.webView.evaluateOnLoaderStart(elementTagName: "payouts")

        // Loading indicator should stop
        XCTAssertFalse(webVC.activityIndicator.isAnimating)
    }

    // MARK: - didFailLoadWithError

    @MainActor
    func testJSOnLoadError() async throws {
        var error: Error?
        let componentManager = componentManagerAssertingOnFetch()
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
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
                                                      didFailLoadWithError: { error = $0 })
        _ = await webVC.webView(webVC.webView, decidePolicyFor: MockNavigationResponse(response: HTTPURLResponse(url: URL(string: "https://stripe.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)!))
        XCTAssertEqual((error as? HTTPStatusError)?.errorCode, 404)
        // Loading indicator should stop
        XCTAssertFalse(webVC.activityIndicator.isAnimating)
    }

    // MARK: - openAuthenticatedWebView

    func testOpenAuthenticatedWebView() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let authenticatedWebViewManager = MockAuthenticatedWebViewManager { url, _ in
            XCTAssertEqual(url.absoluteString, "https://stripe.com/start")
            return URL(string: "stripe-connect://return_url")!
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      didFailLoadWithError: { _ in },
                                                      authenticatedWebViewManager: authenticatedWebViewManager)

        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: ReturnedFromAuthenticatedWebViewSender(payload: .init(
                url: URL(string: "stripe-connect://return_url"),
                id: "1234"
            ))
        )

        webVC.webView.evaluateOpenAuthenticatedWebView(url: "https://stripe.com/start", id: "1234")

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    // MARK: - openFinancialConnections

    func testOpenFinancialConnections_success() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let financialConnectionsPresenter = MockFinancialConnectionsPresenter { apiClient, secret, vc in
            XCTAssert(apiClient === componentManager.apiClient)
            XCTAssertEqual(secret, "client_secret_123")
            XCTAssert(vc is ConnectComponentWebViewController)

            return .completed(result: (
                session: StripeAPI.FinancialConnectionsSession(clientSecret: "", id: "", accounts: .init(data: [], hasMore: false), livemode: false, paymentAccount: nil, bankAccountToken: nil, status: nil, statusDetails: nil),
                token: StripeAPI.BankAccountToken(id: "bank_token", bankAccount: nil, clientIp: nil, livemode: false, used: false)
            ))
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      didFailLoadWithError: { _ in },
                                                      financialConnectionsPresenter: financialConnectionsPresenter)

        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: ReturnedFromFinancialConnectionsSender(payload: .init(
                bankToken: "bank_token",
                id: "5678"
            ))
        )

        webVC.webView.evaluateOpenFinancialConnectionsWebView(clientSecret: "client_secret_123", id: "5678")

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    func testOpenFinancialConnections_canceled() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let financialConnectionsPresenter = MockFinancialConnectionsPresenter { _, _, _ in
            return .canceled
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      didFailLoadWithError: { _ in },
                                                      financialConnectionsPresenter: financialConnectionsPresenter)
        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: ReturnedFromFinancialConnectionsSender(payload: .init(
                bankToken: nil,
                id: "5678"
            ))
        )

        webVC.webView.evaluateOpenFinancialConnectionsWebView(clientSecret: "client_secret_123", id: "5678")

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    func testOpenFinancialConnections_error() throws {
        let componentManager = componentManagerAssertingOnFetch()
        let financialConnectionsPresenter = MockFinancialConnectionsPresenter { _, _, _ in
            return .failed(error: NSError(domain: "mock_error", code: 0))
        }
        let webVC = ConnectComponentWebViewController(componentManager: componentManager,
                                                      componentType: .payouts,
                                                      loadContent: false,
                                                      didFailLoadWithError: { _ in },
                                                      financialConnectionsPresenter: financialConnectionsPresenter)
        let expectation = try webVC.webView.expectationForMessageReceived(
            sender: ReturnedFromFinancialConnectionsSender(payload: .init(
                bankToken: nil,
                id: "5678"
            ))
        )

        webVC.webView.evaluateOpenFinancialConnectionsWebView(clientSecret: "client_secret_123", id: "5678")

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
        _ apiClient: STPAPIClient,
        _ clientSecret: String,
        _ presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult

    init(overridePresentForToken: @escaping (
        _ apiClient: STPAPIClient,
        _ clientSecret: String,
        _ presentingViewController: UIViewController
    ) -> FinancialConnectionsSheet.TokenResult) {
        self.overridePresentForToken = overridePresentForToken
    }

    override func presentForToken(
        apiClient: STPAPIClient,
        clientSecret: String,
        from presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult {
        await overridePresentForToken(apiClient, clientSecret, presentingViewController)
    }
}

//
//  ConnectBridgeSourceValidationTests.swift
//  StripeConnectTests
//

import AuthenticationServices
@_spi(DashboardOnly) @testable import StripeConnect
@_spi(STP) import StripeCore
import UIKit
import WebKit
import XCTest

@MainActor
final class ConnectBridgeSourceValidationTests: XCTestCase {

    func testTrustedMainDocumentFetchesClientSecret() async throws {
        // Given a component WebView with a trusted main document
        let secretProvider = SecretProvider(secret: "trusted-test-secret")
        let controller = makeController(secretProvider: secretProvider)

        // When the document fetches a client secret through the real bridge
        let event = try await loadDocumentAndFetchClientSecret(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL
        )

        // Then WebKit reports the trusted document's origin and returns the secret
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com")
        recordJavaScriptLocationOrigin(event.locationOrigin)
        XCTAssertEqual(event.result, .resolved("trusted-test-secret"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 1)
    }

    func testCustomHTTPSBaseURLAuthorizesOnlyItsConfiguredOrigin() async throws {
        // Given a controller configured with a custom HTTPS component origin
        let secretProvider = SecretProvider(secret: "override-secret")
        let overrideURL = URL(string: "https://override.connect.test/component")!
        let controller = makeController(secretProvider: secretProvider, baseURL: overrideURL)

        // When the configured origin requests a secret
        let overrideEvent = try await loadDocumentAndFetchClientSecret(in: controller.webView, baseURL: overrideURL)

        // Then it is authorized
        XCTAssertEqual(overrideEvent.result, .resolved("override-secret"))

        // And the default production origin cannot use this controller's bridge
        let defaultEvent = try await loadDocumentAndFetchClientSecret(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL
        )
        XCTAssertEqual(defaultEvent.result, .rejected("Invalid message origin"))
    }

    func testTrustedThenForeignNavigationCannotFetchClientSecret() async throws {
        // Given a component WebView that first loads trusted content
        let secretProvider = SecretProvider(secret: "reload-secret")
        let controller = makeController(secretProvider: secretProvider)
        _ = try await loadDocumentAndFetchClientSecret(in: controller.webView, baseURL: StripeConnectConstants.connectJSBaseURL)

        // When the same WebView reloads foreign content
        let foreignEvent = try await loadDocumentAndFetchClientSecret(
            in: controller.webView,
            baseURL: URL(string: "https://foreign.test/reload.html")!
        )

        // Then the foreign document is denied by the existing source policy
        XCTAssertEqual(foreignEvent.result, .rejected("Invalid message origin"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 1)
    }

    func testContentHeightRequiresTrustedDocument() async throws {
        // Given a controller using the production content-height registration
        let trustedHeight = expectation(description: "Trusted content height is delivered")
        let foreignHeight = expectation(description: "Foreign content height is ignored")
        foreignHeight.isInverted = true
        var expectedHeight: CGFloat?
        let controller = makeController(
            secretProvider: SecretProvider(secret: "unused-secret"),
            layoutMode: .sizesToContent { height in
                if height == 321 {
                    expectedHeight = height
                    trustedHeight.fulfill()
                } else if height == 987 {
                    foreignHeight.fulfill()
                }
            }
        )

        // When trusted content posts the registered height message
        _ = try await loadBridgeFixture(in: controller.webView, baseURL: StripeConnectConstants.connectJSBaseURL, html: Self.contentHeightFixtureHTML(height: 321))
        await fulfillment(of: [trustedHeight], timeout: TestHelpers.defaultTimeout)

        // And foreign content posts the same message
        _ = try await loadBridgeFixture(in: controller.webView, baseURL: URL(string: "https://foreign.test/height.html")!, html: Self.contentHeightFixtureHTML(height: 987))
        await fulfillment(of: [foreignHeight], timeout: TestHelpers.defaultTimeout)
        XCTAssertEqual(expectedHeight, 321)
    }

    func testControllerAndWebViewAreNotRetainedBySourcePolicy() async throws {
        weak var controller: ConnectComponentWebViewController?
        weak var webView: WKWebView?
        var policy: STPWebMessageSourcePolicy!
        autoreleasepool {
            let createdController = makeController(secretProvider: SecretProvider(secret: "unused-secret"))
            controller = createdController
            webView = createdController.webView
            policy = createdController.messageSourcePolicy
        }
        XCTAssertNil(controller)
        try await TestHelpers.withTimeout {
            while webView != nil {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
        XCTAssertNil(webView)
        XCTAssertFalse(policy.isAuthorized(source: nil, scheme: "https", host: "connect-js.stripe.com", port: 443))
    }

    func testForeignNotificationBannerTaskMessageDoesNotPresentTask() async throws {
        let banner = makeNotificationBanner()
        let host = UIViewController()
        host.addChild(banner)
        host.view.addSubview(banner.view)
        banner.didMove(toParent: host)
        let window = UIWindow()
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            host.dismiss(animated: false)
            window.isHidden = true
        }

        XCTAssertNotNil(banner.view.window)
        _ = try await loadBridgeFixture(in: banner.webVC.webView, baseURL: URL(string: "https://foreign.test/banner.html")!, html: Self.notificationBannerTaskFixtureHTML)
        try await assertNoPresentationDuringWindow(from: host)
        XCTAssertNil(host.presentedViewController)
    }

    func testTrustedNotificationBannerTaskMessagePresentsTask() async throws {
        let banner = makeNotificationBanner()
        let host = UIViewController()
        host.addChild(banner)
        host.view.addSubview(banner.view)
        banner.didMove(toParent: host)
        let window = UIWindow()
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            host.dismiss(animated: false)
            window.isHidden = true
        }

        XCTAssertNotNil(banner.view.window)
        _ = try await withFixturePhase("trusted banner document and submission") {
            try await loadBridgeFixture(in: banner.webVC.webView, baseURL: StripeConnectConstants.connectJSBaseURL, html: Self.notificationBannerTaskFixtureHTML)
        }
        let taskNavigation = try await withFixturePhase("trusted banner task presentation") {
            try await waitForPresentation(from: host)
        }
        XCTAssertTrue(taskNavigation.topViewController is ConnectComponentWebViewController)
        taskNavigation.dismiss(animated: false)
        try await withFixturePhase("trusted banner task dismissal") {
            try await waitForNoPresentation(from: host)
        }
    }

    func testForeignMainDocumentCannotFetchClientSecret() async throws {
        // Given a component WebView with a foreign main document
        let secretProvider = SecretProvider(secret: "foreign-test-secret")
        let controller = makeController(secretProvider: secretProvider)

        // When the foreign document fetches a client secret through the real bridge
        let event = try await loadDocumentAndFetchClientSecret(
            in: controller.webView,
            baseURL: URL(string: "https://foreign.test/attack.html")!
        )

        // Then WebKit reports the foreign origin and the bridge rejects the request
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "foreign.test")
        recordJavaScriptLocationOrigin(event.locationOrigin)
        XCTAssertEqual(event.result, .rejected("Invalid message origin"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 0)
    }

    func testOpaqueChildFrameCannotFetchClientSecret() async throws {
        // Given a trusted component document containing an opaque child frame
        let secretProvider = SecretProvider(secret: "opaque-child-test-secret")
        let controller = makeController(secretProvider: secretProvider)

        // When the child frame directly fetches a client secret through its own bridge
        let event = try await loadOpaqueChildAndFetchClientSecret(in: controller.webView)

        // Then WebKit reports an untrusted child origin and the bridge rejects the request
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertUntrustedChildOrigin(event.document)
        recordJavaScriptLocationOrigin(event.locationOrigin)
        XCTAssertEqual(event.result, .rejected("Invalid message origin"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 0)
    }

    func testInheritedChildFrameCanFetchClientSecret() async throws {
        // Given a trusted component document containing an inherited-origin child frame
        let secretProvider = SecretProvider(secret: "inherited-child-test-secret")
        let controller = makeController(secretProvider: secretProvider)

        // When the child frame directly fetches a client secret through its own bridge
        let event = try await loadChildAndFetchClientSecret(
            in: controller.webView,
            html: Self.inheritedChildFixtureHTML
        )

        // Then the child retains the trusted origin and receives the secret
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com", isMainFrame: false)
        recordJavaScriptLocationOrigin(event.locationOrigin)
        XCTAssertEqual(event.result, .resolved("inherited-child-test-secret"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 1)
    }

    func testSameOriginSecondWebViewCannotFetchClientSecret() async throws {
        // Given a distinct WebView sharing the component's registered user-content controller
        let secretProvider = SecretProvider(secret: "second-webview-test-secret")
        let controller = makeController(secretProvider: secretProvider)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller.webView.configuration.userContentController
        let secondWebView = WKWebView(frame: .zero, configuration: configuration)
        XCTAssertTrue(secondWebView.configuration.userContentController === controller.webView.configuration.userContentController)
        XCTAssertFalse(secondWebView === controller.webView)

        // When the second WebView sends a message from the trusted origin
        let event = try await loadDocumentAndFetchClientSecret(
            in: secondWebView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            expectedComponentWebView: controller.webView
        )

        // Then source-view identity rejects the request before the provider runs
        XCTAssertFalse(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com", isExpectedSource: false)
        recordJavaScriptLocationOrigin(event.locationOrigin)
        XCTAssertEqual(event.result, .rejected("Invalid message origin"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 0)
    }

    func testForeignMainDocumentCannotChangeMerchantAnalyticsState() async throws {
        // Given a real component controller with foreign content
        let controller = makeController(secretProvider: SecretProvider(secret: "unused-secret"))

        // When the foreign document claims an account session
        _ = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: URL(string: "https://foreign.test/account.html")!,
            html: Self.accountSessionClaimedFixtureHTML
        )

        // Then the component analytics state remains unchanged
        XCTAssertNil(controller.analyticsClient.merchantId)
    }

    func testTrustedMainDocumentCanChangeMerchantAnalyticsState() async throws {
        // Given a real component controller with trusted content
        let controller = makeController(secretProvider: SecretProvider(secret: "unused-secret"))

        // When the trusted document claims an account session
        _ = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            html: Self.accountSessionClaimedFixtureHTML
        )

        // Then the component analytics state changes
        XCTAssertEqual(controller.analyticsClient.merchantId, "acct_source_validation")
    }

    func testForeignMainDocumentCannotInvokeOnExitCallback() async throws {
        // Given a component-specific setter callback and foreign content
        let controller = makeController(secretProvider: SecretProvider(secret: "unused-secret"))
        let didExit = expectation(description: "Foreign document does not invoke onExit")
        didExit.isInverted = true
        controller.addMessageHandler(OnExitMessageHandler(didReceiveMessage: {
            didExit.fulfill()
        }))

        // When the foreign document invokes setOnExit
        _ = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: URL(string: "https://foreign.test/on-exit.html")!,
            html: Self.onExitFixtureHTML
        )

        // Then the merchant callback is not invoked
        await fulfillment(of: [didExit], timeout: TestHelpers.defaultTimeout)
    }

    func testTrustedMainDocumentCanInvokeOnExitCallback() async throws {
        // Given a component-specific setter callback and trusted content
        let controller = makeController(secretProvider: SecretProvider(secret: "unused-secret"))
        let didExit = expectation(description: "Trusted document invokes onExit")
        controller.addMessageHandler(OnExitMessageHandler(didReceiveMessage: {
            didExit.fulfill()
        }))

        // When the trusted document invokes setOnExit
        _ = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            html: Self.onExitFixtureHTML
        )

        // Then the merchant callback is invoked
        await fulfillment(of: [didExit], timeout: TestHelpers.defaultTimeout)
    }

    func testMalformedNonReplyPayloadIsIgnoredBeforeDecodeForForeignDocument() async throws {
        let analyticsTransport = AnalyticsTransport()
        let controller = makeController(secretProvider: SecretProvider(secret: "unused-secret"), analyticsTransport: analyticsTransport)

        _ = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: URL(string: "https://foreign.test/malformed.html")!,
            html: Self.malformedAuthenticationFixtureHTML
        )

        XCTAssertFalse(analyticsTransport.events.contains { $0.name == "component.web.error.deserialize_message" })
    }

    func testMalformedNonReplyPayloadLogsDeserializeErrorForTrustedDocument() async throws {
        let analyticsTransport = AnalyticsTransport()
        let controller = makeController(secretProvider: SecretProvider(secret: "unused-secret"), analyticsTransport: analyticsTransport)

        _ = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            html: Self.malformedAuthenticationFixtureHTML
        )

        let event = try await analyticsTransport.waitForEvent(named: "component.web.error.deserialize_message")
        XCTAssertEqual(event.parameters["message"] as? String, "openAuthenticatedWebView")
    }

    func testForeignMainDocumentCannotOpenAuthenticationSession() async throws {
        // Given a foreign component document and a real manager with an external session factory probe
        let sessionFactory = AuthenticationSessionFactoryProbe()
        sessionFactory.completionResult = .success(URL(string: "stripe-connect://unexpected-return")!)
        let manager = AuthenticatedWebViewManager(sessionFactory: sessionFactory.makeSession)
        let secretProvider = SecretProvider(secret: "unused-secret")
        let controller = makeController(
            secretProvider: secretProvider,
            authenticatedWebViewManager: manager
        )
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let noFactoryCall = expectation(description: "Authentication session factory is not called")
        noFactoryCall.isInverted = true
        sessionFactory.didCreateSession = {
            noFactoryCall.fulfill()
        }

        // When the foreign document submits a non-reply authentication request
        let event = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: URL(string: "https://foreign.test/auth.html")!,
            html: Self.foreignAuthenticationFixtureHTML
        )

        // Then native receives the foreign submission but does not create an authentication session
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "foreign.test")
        XCTAssertEqual(event.result, .resolved("submitted"))
        await fulfillment(of: [noFactoryCall], timeout: 0.2)
        XCTAssertTrue(sessionFactory.createdURLs.isEmpty)
    }

    func testTrustedHTTPDestinationCannotOpenAuthenticationSession() async throws {
        // Given a trusted document, real manager, and captured analytics transport
        let sessionFactory = AuthenticationSessionFactoryProbe()
        sessionFactory.completionResult = .success(URL(string: "stripe-connect://unexpected-return")!)
        let manager = AuthenticatedWebViewManager(sessionFactory: sessionFactory.makeSession)
        let analyticsTransport = AnalyticsTransport()
        let noPageCallback = expectation(description: "No authenticated-web callback reaches the page")
        noPageCallback.isInverted = true
        let callbackObserver = AuthenticationCallbackObserver(expectation: noPageCallback)
        let controller = makeController(
            secretProvider: SecretProvider(secret: "unused-secret"),
            authenticatedWebViewManager: manager,
            analyticsTransport: analyticsTransport
        )
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: callbackObserver.name)
        }
        controller.webView.configuration.userContentController.add(callbackObserver, name: callbackObserver.name)

        // When the trusted document submits an HTTP authentication destination
        let event = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            html: Self.trustedHTTPAuthenticationFixtureHTML
        )
        let errorEvent = try await analyticsTransport.waitForEvent(named: "component.authenticated_web.error")

        // Then no external session or page callback occurs and analytics contains only fixed error metadata
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com")
        XCTAssertEqual(event.result, .resolved("submitted"))
        XCTAssertTrue(sessionFactory.createdURLs.isEmpty)
        XCTAssertEqual(errorEvent.parameters["authenticated_web_view_id"] as? String, "fixed-invalid-authentication-id")
        XCTAssertEqual(errorEvent.parameters["error"] as? String, "StripeConnect.AuthenticatedWebViewError:3")
        XCTAssertNil(errorEvent.parameters["url"])
        XCTAssertNil(errorEvent.parameters["host"])
        XCTAssertNil(errorEvent.parameters["query"])
        XCTAssertNil(errorEvent.parameters["page_view_id"] as? String)
        let serializedParameters = try JSONSerialization.data(withJSONObject: errorEvent.parameters)
        let serializedString = try XCTUnwrap(String(data: serializedParameters, encoding: .utf8))
        XCTAssertFalse(serializedString.contains("http://invalid.example.test/auth?secret=do-not-log"))
        XCTAssertFalse(serializedString.contains("invalid.example.test"))
        XCTAssertFalse(serializedString.contains("do-not-log"))
        await fulfillment(of: [noPageCallback], timeout: TestHelpers.defaultTimeout)
        let callbackCount = try await controller.webView.evaluateJavaScriptStrict("window.authenticationCallbackCount") as? Int
        XCTAssertEqual(callbackCount, 0)
    }

    func testPopupWebViewCannotFetchClientSecret() async throws {
        // Given a component controller displayed in a window
        let secretProvider = SecretProvider(secret: "popup-test-secret")
        let controller = makeController(secretProvider: secretProvider)
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        // When the production WKUIDelegate creates an allowed-host popup
        let popupController = try await withFixturePhase("popup creation and presentation") {
            try await openPopup(from: controller)
        }
        defer {
            if controller.presentedViewController != nil {
                popupController.webView.uiDelegate?.webViewDidClose?(popupController.webView)
            }
        }
        XCTAssertTrue(popupController.webView.configuration.userContentController === controller.webView.configuration.userContentController)

        // Then a popup WebView at the trusted origin cannot use the component bridge
        let event = try await withFixturePhase("popup document and rejected bridge reply") {
            try await loadDocumentAndFetchClientSecret(
                in: popupController.webView,
                baseURL: StripeConnectConstants.connectJSBaseURL,
                expectedComponentWebView: controller.webView
            )
        }
        XCTAssertFalse(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com", isExpectedSource: false)
        XCTAssertEqual(event.result, .rejected("Invalid message origin"))
        let fetchCount = await secretProvider.fetchCount
        XCTAssertEqual(fetchCount, 0)

        // And the production close path dismisses the popup UI
        popupController.webView.uiDelegate?.webViewDidClose?(popupController.webView)
        try await withFixturePhase("popup dismissal") {
            try await waitForPopupDismissal(from: controller)
        }
    }

    func testTrustedMainDocumentReceivesCanceledAuthenticationSession() async throws {
        // Given a trusted component document and a canceled external authentication session
        let sessionFactory = AuthenticationSessionFactoryProbe()
        sessionFactory.completionResult = .failure(ASWebAuthenticationSessionError(
            _nsError: NSError(
                domain: ASWebAuthenticationSessionError.errorDomain,
                code: ASWebAuthenticationSessionError.canceledLogin.rawValue
            )
        ))
        let manager = AuthenticatedWebViewManager(sessionFactory: sessionFactory.makeSession)
        let controller = makeController(
            secretProvider: SecretProvider(secret: "unused-secret"),
            authenticatedWebViewManager: manager
        )
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        // When the trusted document opens authentication and the user cancels
        let event = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            html: Self.trustedAuthenticationFixtureHTML
        )

        // Then the real manager omits the URL from the production page callback
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com")
        XCTAssertEqual(event.result, .resolved("undefined"))
        XCTAssertEqual(sessionFactory.createdURLs, [URL(string: "https://example.test/auth")!])
    }

    func testTrustedMainDocumentCompletesAuthenticationSession() async throws {
        // Given a trusted component document and a real manager with a controlled external session completion
        let sessionFactory = AuthenticationSessionFactoryProbe()
        sessionFactory.completionResult = .success(URL(string: "stripe-connect://trusted-return")!)
        let manager = AuthenticatedWebViewManager(sessionFactory: sessionFactory.makeSession)
        let secretProvider = SecretProvider(secret: "unused-secret")
        let controller = makeController(
            secretProvider: secretProvider,
            authenticatedWebViewManager: manager
        )
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        // When the trusted document opens authentication and receives the native completion callback
        let event = try await loadBridgeFixture(
            in: controller.webView,
            baseURL: StripeConnectConstants.connectJSBaseURL,
            html: Self.trustedAuthenticationFixtureHTML
        )

        // Then the real manager uses the factory and returns the controlled URL to the page
        XCTAssertTrue(event.wasSentByExpectedWebView)
        assertExpectedHTTPSOrigin(event.document, host: "connect-js.stripe.com")
        XCTAssertEqual(event.result, .resolved("stripe-connect://trusted-return"))
        XCTAssertEqual(sessionFactory.createdURLs, [URL(string: "https://example.test/auth")!])
    }
}

private extension ConnectBridgeSourceValidationTests {
    func makeController(
        secretProvider: SecretProvider,
        authenticatedWebViewManager: AuthenticatedWebViewManager = .init(),
        analyticsTransport: AnalyticsTransport = .init(),
        baseURL: URL = StripeConnectConstants.connectJSBaseURL,
        layoutMode: ConnectComponentWebViewController.LayoutMode = .fillsAvailableSpace
    ) -> ConnectComponentWebViewController {
        let componentManager = EmbeddedComponentManager(
            apiClient: .init(publishableKey: "test"),
            fetchClientSecret: {
                await secretProvider.fetch()
            }
        )
        componentManager.baseURL = baseURL
        return ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .payouts,
            loadContent: false,
            analyticsClientFactory: { commonFields in
                ComponentAnalyticsClient(
                    client: analyticsTransport,
                    commonFields: commonFields
                )
            },
            layoutMode: layoutMode,
            fetchInitProps: VoidPayload.init,
            didFailLoadWithError: { _ in },
            authenticatedWebViewManager: authenticatedWebViewManager
        )
    }

    func makeNotificationBanner() -> NotificationBannerViewController {
        let manager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: { nil })
        manager.shouldLoadContent = false
        manager.analyticsClientFactory = { ComponentAnalyticsClient(client: AnalyticsTransport(), commonFields: $0) }
        return manager.createNotificationBannerViewController()
    }

    func withFixturePhase<Value>(_ phase: String, operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch {
            throw BridgeFixturePhaseError(phase: phase, underlyingError: error)
        }
    }

    func waitForPresentation(from controller: UIViewController) async throws -> UINavigationController {
        try await TestHelpers.withTimeout {
            while true {
                if let navigation = controller.presentedViewController as? UINavigationController,
                   navigation.viewIfLoaded?.window != nil,
                   !navigation.isBeingPresented {
                    return navigation
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func assertNoPresentationDuringWindow(from controller: UIViewController) async throws {
        let deadline = Date().addingTimeInterval(0.2)
        while Date() < deadline {
            guard controller.presentedViewController == nil else {
                throw NotificationBannerPresentationError.unexpectedPresentation
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func waitForNoPresentation(from controller: UIViewController) async throws {
        try await TestHelpers.withTimeout {
            while controller.presentedViewController != nil {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func openPopup(from controller: ConnectComponentWebViewController) async throws -> PopupWebViewController {
        let triggerObserver = BridgeEventObserver(expectedWebView: controller.webView)
        controller.webView.configuration.userContentController.add(triggerObserver, name: triggerObserver.name)
        defer {
            triggerObserver.cancel()
            controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: triggerObserver.name)
        }

        controller.webView.loadHTMLString(Self.popupTriggerFixtureHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        _ = try await triggerObserver.waitForDocumentReady()
        _ = try await controller.webView.evaluateJavaScript("void window.open('https://connect.stripe.com/popup')")

        return try await TestHelpers.withTimeout {
            while true {
                if let navigationController = controller.presentedViewController as? UINavigationController,
                   navigationController.viewIfLoaded?.window != nil,
                   !navigationController.isBeingPresented,
                   let popupController = navigationController.topViewController as? PopupWebViewController {
                    return popupController
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func waitForPopupDismissal(from controller: ConnectComponentWebViewController) async throws {
        try await TestHelpers.withTimeout {
            while controller.presentedViewController != nil {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func loadDocumentAndFetchClientSecret(
        in webView: WKWebView,
        baseURL: URL,
        expectedComponentWebView: WKWebView? = nil
    ) async throws -> BridgeEvent {
        let observer = BridgeEventObserver(expectedWebView: expectedComponentWebView ?? webView)
        webView.configuration.userContentController.add(observer, name: observer.name)
        defer {
            observer.cancel()
            webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString(Self.fixtureHTML, baseURL: baseURL)
        let document = try await observer.waitForDocumentReady()
        try await webView.evaluateJavaScriptStrict("void window.runConnectBridgeFixture();")
        let event = try await observer.waitForEvent()
        XCTAssertEqual(event.document, document, "The bridge reply must have the same source metadata as the document-ready acknowledgement")
        return event
    }

    func loadOpaqueChildAndFetchClientSecret(in webView: WKWebView) async throws -> BridgeEvent {
        try await loadChildAndFetchClientSecret(in: webView, html: Self.opaqueChildFixtureHTML)
    }

    func loadChildAndFetchClientSecret(
        in webView: WKWebView,
        html: String
    ) async throws -> BridgeEvent {
        let observer = BridgeEventObserver(expectedWebView: webView)
        webView.configuration.userContentController.add(observer, name: observer.name)
        defer {
            observer.cancel()
            webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString(html, baseURL: StripeConnectConstants.connectJSBaseURL)
        let document = try await observer.waitForDocumentReady()
        let event = try await observer.waitForEvent()
        XCTAssertEqual(event.document, document, "The bridge reply must have the same child-frame metadata as the document-ready acknowledgement")
        return event
    }

    func loadBridgeFixture(
        in webView: WKWebView,
        baseURL: URL,
        html: String,
        expectedComponentWebView: WKWebView? = nil
    ) async throws -> BridgeEvent {
        let observer = BridgeEventObserver(expectedWebView: expectedComponentWebView ?? webView)
        webView.configuration.userContentController.add(observer, name: observer.name)
        defer {
            observer.cancel()
            webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString(html, baseURL: baseURL)
        let document = try await observer.waitForDocumentReady()
        let event = try await observer.waitForEvent()
        XCTAssertEqual(event.document, document, "The bridge acknowledgement must have the same source metadata as the ready acknowledgement")
        return event
    }

    func assertExpectedHTTPSOrigin(
        _ document: BridgeDocument,
        host: String,
        isMainFrame: Bool = true,
        isExpectedSource: Bool = true
    ) {
        XCTContext.runActivity(named: "Observed WebKit origin: \(document.securityOrigin.scheme)://\(document.securityOrigin.host):\(document.securityOrigin.port)") { _ in }
        XCTAssertEqual(document.wasSentByExpectedWebView, isExpectedSource)
        XCTAssertEqual(document.isMainFrame, isMainFrame)
        XCTAssertEqual(document.securityOrigin.scheme, "https")
        XCTAssertEqual(document.securityOrigin.host, host)
        XCTAssertTrue([0, 443].contains(document.securityOrigin.port), "Unexpected HTTPS port: \(document.securityOrigin.port)")
        XCTAssertEqual(document.securityOrigin.effectivePort, 443)
    }

    func recordJavaScriptLocationOrigin(_ locationOrigin: String) {
        XCTContext.runActivity(named: "Observed JavaScript location.origin: \(locationOrigin)") { _ in }
    }

    func assertUntrustedChildOrigin(_ document: BridgeDocument) {
        XCTContext.runActivity(named: "Observed child WebKit origin: \(document.securityOrigin.scheme)://\(document.securityOrigin.host):\(document.securityOrigin.port)") { _ in }
        XCTAssertFalse(document.isMainFrame)
        let matchesTrustedOrigin = document.securityOrigin.scheme.lowercased() == "https"
            && document.securityOrigin.host.lowercased() == "connect-js.stripe.com"
            && document.securityOrigin.effectivePort == 443
        XCTAssertFalse(matchesTrustedOrigin, "The sandboxed child must report an opaque or otherwise untrusted origin")
    }

    static let fixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.runConnectBridgeFixture = async () => {
      try {
        const result = await window.webkit.messageHandlers.fetchClientSecret.postMessage({});
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "resolved", value: result }
        });
      } catch (error) {
        const message = error && typeof error === "object" && "message" in error ? error.message : String(error);
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "rejected", value: String(message) }
        });
      }
    };
    </script>
    """

    static let opaqueChildFixtureHTML = """
    <!doctype html>
    <iframe sandbox="allow-scripts" srcdoc='<!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    (async () => {
      try {
        const result = await window.webkit.messageHandlers.fetchClientSecret.postMessage({});
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "resolved", value: result }
        });
      } catch (error) {
        const message = error && typeof error === "object" && "message" in error ? error.message : String(error);
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "rejected", value: String(message) }
        });
      }
    })();
    </script>'></iframe>
    """

    static let inheritedChildFixtureHTML = """
    <!doctype html>
    <iframe srcdoc='<!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    (async () => {
      try {
        const result = await window.webkit.messageHandlers.fetchClientSecret.postMessage({});
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "resolved", value: result }
        });
      } catch (error) {
        const message = error && typeof error === "object" && "message" in error ? error.message : String(error);
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "rejected", value: String(message) }
        });
      }
    })();
    </script>'></iframe>
    """

    static func contentHeightFixtureHTML(height: Int) -> String {
        """
        <!doctype html>
        <script>
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
        window.webkit.messageHandlers.connectContentHeight.postMessage({ height: \(height) });
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result",
          locationOrigin: window.location.origin,
          result: { kind: "resolved", value: "submitted" }
        });
        </script>
        """
    }

    static let accountSessionClaimedFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.webkit.messageHandlers.accountSessionClaimed.postMessage({ merchantId: "acct_source_validation" });
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
      kind: "result",
      locationOrigin: window.location.origin,
      result: { kind: "resolved", value: "submitted" }
    });
    </script>
    """

    static let onExitFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.webkit.messageHandlers.onSetterFunctionCalled.postMessage({ setter: "setOnExit" });
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
      kind: "result",
      locationOrigin: window.location.origin,
      result: { kind: "resolved", value: "submitted" }
    });
    </script>
    """

    static let notificationBannerTaskFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.webkit.messageHandlers.openNotificationBannerForm.postMessage({ testField: "fixture" });
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
      kind: "result",
      locationOrigin: window.location.origin,
      result: { kind: "resolved", value: "submitted" }
    });
    </script>
    """

    static let malformedAuthenticationFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({ url: 123, id: [] });
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
      kind: "result",
      locationOrigin: window.location.origin,
      result: { kind: "resolved", value: "submitted" }
    });
    </script>
    """

    static let foreignAuthenticationFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({
      url: "https://example.test/auth",
      id: "foreign-authentication"
    });
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
      kind: "result",
      locationOrigin: window.location.origin,
      result: { kind: "resolved", value: "submitted" }
    });
    </script>
    """

    static let trustedHTTPAuthenticationFixtureHTML = """
    <!doctype html>
    <script>
    window.authenticationCallbackCount = 0;
    window.returnedFromAuthenticatedWebView = () => {
      window.authenticationCallbackCount += 1;
      window.webkit.messageHandlers.authenticationCallbackObserver.postMessage({ kind: "callback" });
    };
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({
      url: "http://invalid.example.test/auth?secret=do-not-log",
      id: "fixed-invalid-authentication-id"
    });
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
      kind: "result",
      locationOrigin: window.location.origin,
      result: { kind: "resolved", value: "submitted" }
    });
    </script>
    """

    static let trustedAuthenticationFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    window.returnedFromAuthenticatedWebView = (message) => {
      if (message.id !== "trusted-authentication") {
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result", locationOrigin: window.location.origin,
          result: { kind: "rejected", value: "unexpected id" }
        });
        return;
      }
      if (message.url === undefined && Object.prototype.hasOwnProperty.call(message, "url")) {
        window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
          kind: "result", locationOrigin: window.location.origin,
          result: { kind: "rejected", value: "undefined url field" }
        });
        return;
      }
      window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({
        kind: "result",
        locationOrigin: window.location.origin,
        result: { kind: "resolved", value: String(message.url) }
      });
    };
    window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({
      url: "https://example.test/auth",
      id: "trusted-authentication"
    });
    </script>
    """

    static let popupTriggerFixtureHTML = """
    <!doctype html>
    <script>
    window.webkit.messageHandlers.connectBridgeTestObserver.postMessage({ kind: "ready" });
    </script>
    """
}

private actor SecretProvider {
    let secret: String
    private(set) var fetchCount = 0

    init(secret: String) {
        self.secret = secret
    }

    func fetch() -> String {
        fetchCount += 1
        return secret
    }
}

private final class AnalyticsTransport: AnalyticsClientV2Protocol {
    struct Event {
        let name: String
        let parameters: [String: Any]
    }

    let clientId = "test"
    private(set) var events: [Event] = []

    func log(eventName: String, parameters: [String: Any]) {
        events.append(.init(name: eventName, parameters: parameters))
    }

    @MainActor
    func waitForEvent(named name: String) async throws -> Event {
        try await TestHelpers.withTimeout {
            while true {
                if let event = self.events.last(where: { $0.name == name }) {
                    return event
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }
}

private final class AuthenticationCallbackObserver: NSObject, WKScriptMessageHandler {
    let name = "authenticationCallbackObserver"
    private let expectation: XCTestExpectation

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        expectation.fulfill()
    }
}

private final class AuthenticationSessionFactoryProbe {
    var didCreateSession: (() -> Void)?
    var completionResult: Result<URL?, Error>?
    private(set) var createdURLs: [URL] = []

    func makeSession(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> ASWebAuthenticationSession {
        createdURLs.append(url)
        didCreateSession?()
        return AuthenticationSessionDouble(
            url: url,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler,
            completionResult: completionResult
        )
    }
}

private final class AuthenticationSessionDouble: ASWebAuthenticationSession {
    private let completionHandler: CompletionHandler
    private let completionResult: Result<URL?, Error>?

    init(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping CompletionHandler,
        completionResult: Result<URL?, Error>?
    ) {
        self.completionHandler = completionHandler
        self.completionResult = completionResult
        super.init(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
    }

    override var canStart: Bool { true }

    override func start() -> Bool {
        if let completionResult {
            do {
                completionHandler(try completionResult.get(), nil)
            } catch {
                completionHandler(nil, error)
            }
        }
        return true
    }
}

private struct BridgeEvent: Equatable {
    enum Result: Equatable {
        case resolved(String?)
        case rejected(String)
    }

    let document: BridgeDocument
    let locationOrigin: String
    let result: Result

    var wasSentByExpectedWebView: Bool {
        document.wasSentByExpectedWebView
    }
}

private struct BridgeDocument: Equatable {
    struct SecurityOrigin: Equatable {
        let scheme: String
        let host: String
        let port: Int

        var effectivePort: Int {
            port == 0 && scheme.lowercased() == "https" ? 443 : port
        }
    }

    let wasSentByExpectedWebView: Bool
    let isMainFrame: Bool
    let securityOrigin: SecurityOrigin
}

private final class BridgeEventObserver: NSObject, WKScriptMessageHandler {
    let name = "connectBridgeTestObserver"

    private weak var expectedWebView: WKWebView?
    private let documentGate = FixtureGate<BridgeDocument>()
    private let eventGate = FixtureGate<BridgeEvent>()

    init(expectedWebView: WKWebView) {
        self.expectedWebView = expectedWebView
    }

    func waitForDocumentReady() async throws -> BridgeDocument {
        try await documentGate.wait()
    }

    func waitForEvent() async throws -> BridgeEvent {
        try await eventGate.wait()
    }

    func cancel() {
        documentGate.cancel()
        eventGate.cancel()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard let body = message.body as? [String: Any],
              let kind = body["kind"] as? String else {
            eventGate.finish(.failure(BridgeEventObserverError.invalidMessage))
            return
        }

        let document = BridgeDocument(
            wasSentByExpectedWebView: message.webView === expectedWebView,
            isMainFrame: message.frameInfo.isMainFrame,
            securityOrigin: .init(scheme: origin.protocol, host: origin.host, port: origin.port)
        )

        guard kind == "result" else {
            guard kind == "ready" else {
                documentGate.finish(.failure(BridgeEventObserverError.invalidMessage))
                return
            }
            documentGate.finish(.success(document))
            return
        }

        guard let locationOrigin = body["locationOrigin"] as? String,
              let result = body["result"] as? [String: Any],
              let resultKind = result["kind"] as? String,
              let value = result["value"] as? String else {
            eventGate.finish(.failure(BridgeEventObserverError.invalidMessage))
            return
        }

        let bridgeResult: BridgeEvent.Result
        switch resultKind {
        case "resolved":
            bridgeResult = .resolved(value)
        case "rejected":
            bridgeResult = .rejected(value)
        default:
            eventGate.finish(.failure(BridgeEventObserverError.invalidMessage))
            return
        }

        eventGate.finish(.success(BridgeEvent(
            document: document,
            locationOrigin: locationOrigin,
            result: bridgeResult
        )))
    }
}

private final class FixtureGate<Value> {
    private let lock = NSLock()
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?
    private var timeout: DispatchWorkItem?
    private var didRegisterWaiter = false

    func wait() async throws -> Value {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                defer { lock.unlock() }
                guard !didRegisterWaiter else {
                    continuation.resume(throwing: BridgeEventObserverError.duplicateWait)
                    return
                }
                didRegisterWaiter = true
                if let result {
                    continuation.resume(with: result)
                    return
                }
                self.continuation = continuation
                let timeout = DispatchWorkItem { [weak self] in
                    self?.finish(.failure(BridgeEventObserverError.timeout))
                }
                self.timeout = timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + TestHelpers.defaultTimeout, execute: timeout)
            }
        }, onCancel: {
            self.cancel()
        })
    }

    func cancel() {
        finish(.failure(CancellationError()))
    }

    func finish(_ result: Result<Value, Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let continuation = continuation
        self.continuation = nil
        let timeout = timeout
        self.timeout = nil
        lock.unlock()

        timeout?.cancel()
        continuation?.resume(with: result)
    }
}

private extension WKWebView {
    func evaluateJavaScriptStrict(_ script: String) async throws -> Any? {
        let gate = FixtureGate<Any?>()
        evaluateJavaScript(script) { result, error in
            if let error {
                gate.finish(.failure(error))
            } else {
                gate.finish(.success(result))
            }
        }
        return try await gate.wait()
    }
}

private struct BridgeFixturePhaseError: LocalizedError {
    let phase: String
    let underlyingError: Error

    var errorDescription: String? {
        "Connect bridge fixture failed during \(phase): \(underlyingError)"
    }
}

private enum NotificationBannerPresentationError: Error {
    case unexpectedPresentation
}

private enum BridgeEventObserverError: Error {
    case duplicateWait
    case invalidMessage
    case timeout
}

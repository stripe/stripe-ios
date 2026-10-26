//
//  ConnectOutboundSourceValidationTests.swift
//  StripeConnectTests
//

import AuthenticationServices
@testable import StripeConnect
@_spi(STP) import StripeCore
import UIKit
import WebKit
import XCTest

@MainActor
final class ConnectOutboundSourceValidationTests: XCTestCase {

    func testSerializationFailureRetainsDiagnosticIdentifierWithoutPayload() async throws {
        // Given a sensitive payload that fails encoding with private error details.
        let transport = OutboundAnalyticsTransport()
        let controller = makeController(analyticsTransport: transport)
        let sender = SupplementalFunctionCompletedSender(payload: .init(
            functionName: .handleCheckScanSubmitted,
            invocationId: "private-invocation",
            result: .error(FailingOutboundPayload())
        ))

        // When delivery fails and the caller reports the error.
        do {
            try await controller.sendSensitiveMessageAsync(sender, documentID: "fixture-document")
            XCTFail("Expected encoding to fail")
        } catch {
            controller.analyticsClient.logClientError(error)
        }

        // Then analytics retains the diagnostic identifier without private fields.
        let event = try XCTUnwrap(transport.lastClientError)
        XCTAssertEqual(event["error"] as? String, "OutboundEncodingFixture:42")
        XCTAssertFalse(String(describing: event).contains("private-"))
        XCTAssertNil(event["url"])
        XCTAssertNil(event["payload"])
    }

    func testLoggableSerializationFailureUsesSanitizedDeliveryFailure() async throws {
        // Given an encoding error that would add private fields to analytics.
        let transport = OutboundAnalyticsTransport()
        let controller = makeController(analyticsTransport: transport)
        let sender = SupplementalFunctionCompletedSender(payload: .init(
            functionName: .handleCheckScanSubmitted,
            invocationId: "private-invocation",
            result: .error(FailingOutboundPayload(error: LoggableOutboundEncodingError()))
        ))

        // When delivery fails and the caller reports the error.
        do {
            try await controller.sendSensitiveMessageAsync(sender, documentID: "fixture-document")
            XCTFail("Expected encoding to fail")
        } catch {
            controller.analyticsClient.logClientError(error)
        }

        // Then analytics distinguishes failure from refusal without the error's fields.
        let event = try XCTUnwrap(transport.lastClientError)
        XCTAssertEqual(event["error"] as? String, "StripeConnect.SensitiveDeliveryError:1")
        XCTAssertFalse(String(describing: event).contains("private-"))
        XCTAssertNil(event["url"])
        XCTAssertNil(event["payload"])
    }

    func testSensitiveDeliveryEvaluationFailureRetainsWebKitIdentifierWithoutPayload() async throws {
        // Given a controlled dispatcher fixture that causes a WebKit evaluation error.
        let transport = OutboundAnalyticsTransport()
        let controller = makeController(analyticsTransport: transport)
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let ready = expectation(description: "Throwing dispatcher fixture is ready")
        let callback = expectation(description: "Evaluation failure does not deliver the result")
        callback.isInverted = true
        let observer = CallbackObserver(name: "connectOutboundCallback", expectedWebView: controller.webView, expectedHost: "connect-js.stripe.com", ready: ready, callback: callback)
        let contentController = controller.webView.configuration.userContentController
        // Remove the protected production script rather than trying to overwrite it from page code.
        contentController.removeAllUserScripts()
        contentController.add(observer, name: observer.name)
        defer { contentController.removeScriptMessageHandler(forName: observer.name) }
        controller.webView.loadHTMLString("""
        <!doctype html><script>
        window.__stripeConnectDeliverSensitiveMessage = () => {
          throw new Error("private-exception https://example.test/private-url");
        };
        window.webkit.messageHandlers.connectOutboundCallback.postMessage({kind: "ready", dispatcher: "function"});
        </script>
        """, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [ready], timeout: TestHelpers.defaultTimeout)

        // When a sensitive result is evaluated by WebKit.
        let deliveryError: Error
        do {
            try await controller.sendSensitiveMessageAsync(ReturnedFromAuthenticatedWebViewSender(
                payload: .init(url: URL(string: "stripe-connect://return?secret=private-result")!, id: "outbound-test")
            ), documentID: "fixture-document")
            XCTFail("Expected a WebKit evaluation error")
            return
        } catch {
            deliveryError = error
        }

        // Then the delivery error, rather than any setup error, retains WebKit's identifier.
        XCTAssertEqual(deliveryError.analyticsIdentifier, "WKErrorDomain:4")
        controller.analyticsClient.logClientError(deliveryError)
        let event = try XCTUnwrap(transport.lastClientError)
        XCTAssertEqual(event["error"] as? String, "WKErrorDomain:4")
        XCTAssertFalse(String(describing: event).contains("private-"))
        XCTAssertNil(event["url"])
        XCTAssertNil(event["payload"])
        await fulfillment(of: [callback], timeout: 0.2)
    }

    func testMissingDocumentIdentifierRemainsRefusalBeforeEncoding() async throws {
        // Given a request without a document identifier and a payload that would fail encoding.
        let transport = OutboundAnalyticsTransport()
        let controller = makeController(analyticsTransport: transport)
        let sender = SupplementalFunctionCompletedSender(payload: .init(
            functionName: .handleCheckScanSubmitted,
            invocationId: "private-invocation",
            result: .error(FailingOutboundPayload(error: LoggableOutboundEncodingError()))
        ))

        // When delivery is requested without its initiating document.
        do {
            try await controller.sendSensitiveMessageAsync(sender, documentID: nil)
            XCTFail("Expected missing document identifier to refuse delivery")
        } catch {
            controller.analyticsClient.logClientError(error)
        }

        // Then refusal remains distinct from encoding and evaluation failures.
        let event = try XCTUnwrap(transport.lastClientError)
        XCTAssertEqual(event["error"] as? String, "StripeConnect.SensitiveDeliveryError:0")
        XCTAssertFalse(String(describing: event).contains("private-"))
        XCTAssertNil(event["url"])
        XCTAssertNil(event["payload"])
    }

    func testAuthenticationResultReachesOriginalTrustedDocument() async throws {
        try await assertAuthenticationResultReachesOriginalDocument(html: Self.trustedAuthenticationHTML)
    }

    func testTrustedChildAuthenticationResultReachesContainingDocument() async throws {
        let html = Self.trustedAuthenticationCallbackHTML + """
        <iframe srcdoc='<!doctype html><script>
        window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({url: "https://example.test/auth", id: "outbound-test"});
        </script>'></iframe>
        """
        try await assertAuthenticationResultReachesOriginalDocument(html: html)
    }

    private func assertAuthenticationResultReachesOriginalDocument(html: String) async throws {
        let factory = HeldAuthenticationSessionFactory()
        let controller = makeController(authenticationManager: .init(sessionFactory: factory.makeSession))
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let ready = expectation(description: "Trusted callback document is ready")
        let callback = expectation(description: "Trusted document receives authentication result")
        let observer = CallbackObserver(name: "connectOutboundCallback", expectedWebView: controller.webView, expectedHost: "connect-js.stripe.com", ready: ready, callback: callback, expectedCallbackURL: "stripe-connect://original-document")
        controller.webView.configuration.userContentController.add(observer, name: observer.name)
        defer { controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name) }

        controller.webView.loadHTMLString(html, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [ready, factory.created], timeout: TestHelpers.defaultTimeout)
        factory.complete(URL(string: "stripe-connect://original-document")!)
        await fulfillment(of: [callback], timeout: TestHelpers.defaultTimeout)
    }

    func testAuthenticationResultDoesNotReachForeignDocumentAfterNavigation() async throws {
        let factory = HeldAuthenticationSessionFactory()
        let analyticsTransport = OutboundAnalyticsTransport()
        let controller = makeController(
            authenticationManager: .init(sessionFactory: factory.makeSession),
            analyticsTransport: analyticsTransport
        )
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let trustedReady = expectation(description: "Trusted request document is ready")
        let foreignReady = expectation(description: "Foreign callback document is ready")
        let authorityDenied = expectation(description: "Foreign document authority is rejected")
        let callback = expectation(description: "Foreign document must not receive authentication result")
        callback.isInverted = true
        let observer = CallbackObserver(name: "connectOutboundCallback", expectedWebView: controller.webView, expectedHost: "connect-js.stripe.com", ready: trustedReady, callback: callback, foreignReady: foreignReady, authorityDenied: authorityDenied)
        controller.webView.configuration.userContentController.add(observer, name: observer.name)
        defer { controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name) }

        controller.webView.loadHTMLString(Self.trustedAuthenticationHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [trustedReady, factory.created], timeout: TestHelpers.defaultTimeout)
        controller.webView.loadHTMLString(Self.foreignCallbackHTML, baseURL: URL(string: "https://foreign.test/navigation.html")!)
        await fulfillment(of: [foreignReady, authorityDenied], timeout: TestHelpers.defaultTimeout)
        factory.complete(URL(string: "stripe-connect://must-not-deliver?secret=outbound-sentinel")!)
        let clientError = try await analyticsTransport.waitForClientError(identifier: "StripeConnect.SensitiveDeliveryError:0")
        XCTAssertEqual(clientError["error"] as? String, "StripeConnect.SensitiveDeliveryError:0")
        XCTAssertNil(clientError["url"])
        XCTAssertNil(clientError["payload"])
        let serializedClientError = String(describing: clientError)
        XCTAssertFalse(serializedClientError.contains("must-not-deliver"))
        XCTAssertFalse(serializedClientError.contains("outbound-sentinel"))
        await fulfillment(of: [callback], timeout: 0.2)
    }

    func testAuthenticationResultDoesNotReachReplacementTrustedDocument() async throws {
        try await assertAuthenticationResultIsWithheldAfterReplacement(reload: false)
    }

    func testAuthenticationResultDoesNotReachReloadedTrustedDocument() async throws {
        try await assertAuthenticationResultIsWithheldAfterReplacement(reload: true)
    }

    private func assertAuthenticationResultIsWithheldAfterReplacement(reload: Bool) async throws {
        // Given an authentication request whose result is still pending.
        let factory = HeldAuthenticationSessionFactory()
        let transport = OutboundAnalyticsTransport()
        let controller = makeController(authenticationManager: .init(sessionFactory: factory.makeSession), analyticsTransport: transport)
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let ready = expectation(description: "Original document is ready")
        let callback = expectation(description: "Replacement must not receive the original result")
        callback.isInverted = true
        let observer = CallbackObserver(name: "connectOutboundCallback", expectedWebView: controller.webView, expectedHost: "connect-js.stripe.com", ready: ready, callback: callback)
        let contentController = controller.webView.configuration.userContentController
        contentController.add(observer, name: observer.name)
        defer { contentController.removeScriptMessageHandler(forName: observer.name) }
        let requestHTML = Self.trustedAuthenticationCallbackHTML + """
        <script>
        if (window.name !== "authentication-requested") {
          window.name = "authentication-requested";
          window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({url: "https://example.test/auth", id: "outbound-test"});
        }
        </script>
        """
        controller.webView.loadHTMLString(requestHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [ready, factory.created], timeout: TestHelpers.defaultTimeout)

        // When a different document on the same trusted origin replaces it.
        let replacementReady = expectation(description: "Replacement document is ready")
        contentController.removeScriptMessageHandler(forName: observer.name)
        contentController.add(CallbackObserver(name: observer.name, expectedWebView: controller.webView, expectedHost: "connect-js.stripe.com", ready: replacementReady, callback: callback), name: observer.name)
        let reloadDelegate = OutboundHTMLReloadDelegate(html: requestHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        defer { withExtendedLifetime(reloadDelegate) {} }
        if reload {
            controller.webView.navigationDelegate = reloadDelegate
            XCTAssertNotNil(controller.webView.reload())
        } else {
            controller.webView.loadHTMLString(Self.trustedAuthenticationCallbackHTML, baseURL: URL(string: "https://connect-js.stripe.com/replacement")!)
        }
        await fulfillment(of: [replacementReady], timeout: TestHelpers.defaultTimeout)
        factory.complete(URL(string: "stripe-connect://original-document")!)

        // Then the original result is withheld despite the matching origin.
        _ = try await transport.waitForClientError(identifier: "StripeConnect.SensitiveDeliveryError:0")
        await fulfillment(of: [callback], timeout: 0.2)
    }

    func testAuthenticationResultSurvivesProtectedDispatcherAndBuiltinTampering() async throws {
        let factory = HeldAuthenticationSessionFactory()
        let controller = makeController(authenticationManager: .init(sessionFactory: factory.makeSession))
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let ready = expectation(description: "Tampered trusted callback document is ready")
        let callback = expectation(description: "Tampered trusted document receives authentication result")
        let observer = CallbackObserver(
            name: "connectOutboundCallback",
            expectedWebView: controller.webView,
            expectedHost: "connect-js.stripe.com",
            ready: ready,
            callback: callback,
            expectedCallbackURL: "stripe-connect://tamper-resistant",
            requiresProtectedDispatcher: true
        )
        controller.webView.configuration.userContentController.add(observer, name: observer.name)
        defer { controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name) }

        controller.webView.loadHTMLString(Self.tamperedTrustedAuthenticationHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [ready, factory.created], timeout: TestHelpers.defaultTimeout)
        factory.complete(URL(string: "stripe-connect://tamper-resistant")!)
        await fulfillment(of: [callback], timeout: TestHelpers.defaultTimeout)
    }

    func testOpaqueChildFrameCannotAuthorizeSensitiveDelivery() async throws {
        let controller = makeController()
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let ready = expectation(description: "Trusted parent is ready")
        let callback = expectation(description: "No callback is delivered")
        callback.isInverted = true
        let opaqueAuthorityDenied = expectation(description: "Opaque child authority is rejected")
        let observer = CallbackObserver(
            name: "connectOutboundCallback",
            expectedWebView: controller.webView,
            expectedHost: "connect-js.stripe.com",
            ready: ready,
            callback: callback,
            opaqueAuthorityDenied: opaqueAuthorityDenied
        )
        controller.webView.configuration.userContentController.add(observer, name: observer.name)
        defer { controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name) }

        controller.webView.loadHTMLString(Self.opaqueChildAuthorityHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [ready, opaqueAuthorityDenied], timeout: TestHelpers.defaultTimeout)
        await fulfillment(of: [callback], timeout: 0.2)
    }

    func testTrustedChildFrameCannotAuthorizeSensitiveDelivery() async throws {
        let controller = makeController()
        let window = UIWindow()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let ready = expectation(description: "Trusted parent is ready")
        let callback = expectation(description: "No callback is delivered")
        callback.isInverted = true
        let childAuthorityDenied = expectation(description: "Trusted child authority is rejected")
        let observer = CallbackObserver(
            name: "connectOutboundCallback",
            expectedWebView: controller.webView,
            expectedHost: "connect-js.stripe.com",
            ready: ready,
            callback: callback,
            childAuthorityDenied: childAuthorityDenied
        )
        controller.webView.configuration.userContentController.add(observer, name: observer.name)
        defer { controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name) }

        controller.webView.loadHTMLString(Self.trustedChildAuthorityHTML, baseURL: StripeConnectConstants.connectJSBaseURL)
        await fulfillment(of: [ready, childAuthorityDenied], timeout: TestHelpers.defaultTimeout)
        await fulfillment(of: [callback], timeout: 0.2)
    }
}

private extension ConnectOutboundSourceValidationTests {
    func makeController(
        authenticationManager: AuthenticatedWebViewManager = .init(),
        analyticsTransport: OutboundAnalyticsTransport = .init()
    ) -> ConnectComponentWebViewController {
        let manager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: { "unused" })
        return ConnectComponentWebViewController(
            componentManager: manager,
            componentType: .payouts,
            loadContent: false,
            analyticsClientFactory: { ComponentAnalyticsClient(client: analyticsTransport, commonFields: $0) },
            didFailLoadWithError: { _ in },
            authenticatedWebViewManager: authenticationManager
        )
    }

    static let trustedAuthenticationHTML = """
    <!doctype html>
    <script>
    window.returnedFromAuthenticatedWebView = (message) => {
      window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "callback", message });
    };
    window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "ready", dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage });
    window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({
      url: "https://example.test/auth",
      id: "outbound-test"
    });
    </script>
    """

    static let trustedAuthenticationCallbackHTML = """
    <!doctype html><script>
    window.returnedFromAuthenticatedWebView = (message) => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "callback", message });
    window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "ready", dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage });
    </script>
    """

    static let foreignCallbackHTML = """
    <!doctype html>
    <script>
    window.returnedFromAuthenticatedWebView = (message) => {
      window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "callback", message });
    };
    window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "foreignReady", dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage });
    window.webkit.messageHandlers.connectDocumentAuthority.postMessage({}).then(
      () => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "authorityAllowed" }),
      (error) => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "authorityDenied", error: String(error) })
    );
    </script>
    """

    static let tamperedTrustedAuthenticationHTML = """
    <!doctype html>
    <script>
    window.returnedFromAuthenticatedWebView = (message) => {
      window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "callback", message });
    };
    const dispatcher = this.__stripeConnectDeliverSensitiveMessage;
    const documentID = this.__stripeConnectDocumentID;
    this.__stripeConnectDocumentID = "caller-supplied";
    try { Object.defineProperty(this, "__stripeConnectDocumentID", { value: "caller-supplied" }); } catch (_) {}
    this.__stripeConnectDeliverSensitiveMessage = () => {
      window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "tamperSucceeded" });
    };
    try {
      Object.defineProperty(this, "__stripeConnectDeliverSensitiveMessage", { value: () => {} });
    } catch (_) {}
    Function.prototype.call = () => { throw new Error("tampered call"); };
    Promise.prototype.then = () => { throw new Error("tampered then"); };
    Reflect.apply = () => { throw new Error("tampered apply"); };
    const descriptor = Object.getOwnPropertyDescriptor(this, "__stripeConnectDeliverSensitiveMessage");
    window.webkit.messageHandlers.connectOutboundCallback.postMessage({
      kind: "ready",
      dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage,
      protected: documentID === this.__stripeConnectDocumentID && dispatcher === this.__stripeConnectDeliverSensitiveMessage && descriptor.configurable === false && descriptor.writable === false
    });
    window.webkit.messageHandlers.openAuthenticatedWebView.postMessage({
      url: "https://example.test/auth",
      id: "outbound-test",
      documentID: "caller-supplied"
    });
    </script>
    """

    static let opaqueChildAuthorityHTML = """
    <!doctype html>
    <script>
    window.returnedFromAuthenticatedWebView = () => {};
    window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "ready", dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage });
    </script>
    <iframe sandbox="allow-scripts" srcdoc='<!doctype html><script>
    window.webkit.messageHandlers.connectDocumentAuthority.postMessage({}).then(
      () => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "opaqueAuthorityAllowed" }),
      (error) => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "opaqueAuthorityDenied", error: String(error) })
    );
    </script>'></iframe>
    """

    static let trustedChildAuthorityHTML = """
    <!doctype html>
    <script>
    window.returnedFromAuthenticatedWebView = () => {};
    window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "ready", dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage });
    </script>
    <iframe srcdoc='<!doctype html><script>
    window.webkit.messageHandlers.connectDocumentAuthority.postMessage({}).then(
      () => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "childAuthorityAllowed" }),
      (error) => window.webkit.messageHandlers.connectOutboundCallback.postMessage({ kind: "childAuthorityDenied", error: String(error) })
    );
    </script>'></iframe>
    """
}

private final class CallbackObserver: NSObject, WKScriptMessageHandler {
    let name: String
    private weak var expectedWebView: WKWebView?
    private let expectedHost: String
    private let ready: XCTestExpectation
    private let callback: XCTestExpectation
    private let expectedCallbackURL: String?
    private let foreignReady: XCTestExpectation?
    private let authorityDenied: XCTestExpectation?
    private let opaqueAuthorityDenied: XCTestExpectation?
    private let childAuthorityDenied: XCTestExpectation?
    private let requiresProtectedDispatcher: Bool

    init(name: String, expectedWebView: WKWebView, expectedHost: String, ready: XCTestExpectation, callback: XCTestExpectation, expectedCallbackURL: String? = nil, foreignReady: XCTestExpectation? = nil, authorityDenied: XCTestExpectation? = nil, opaqueAuthorityDenied: XCTestExpectation? = nil, childAuthorityDenied: XCTestExpectation? = nil, requiresProtectedDispatcher: Bool = false) {
        self.name = name
        self.expectedWebView = expectedWebView
        self.expectedHost = expectedHost
        self.ready = ready
        self.callback = callback
        self.expectedCallbackURL = expectedCallbackURL
        self.foreignReady = foreignReady
        self.authorityDenied = authorityDenied
        self.opaqueAuthorityDenied = opaqueAuthorityDenied
        self.childAuthorityDenied = childAuthorityDenied
        self.requiresProtectedDispatcher = requiresProtectedDispatcher
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard message.webView === expectedWebView,
              let body = message.body as? [String: Any],
              let kind = body["kind"] as? String else {
            XCTFail("Invalid outbound fixture acknowledgement")
            return
        }
        if kind == "opaqueAuthorityDenied" {
            guard !message.frameInfo.isMainFrame,
                  origin.host.lowercased() != expectedHost,
                  let error = body["error"] as? String,
                  error.contains("Invalid message origin") else {
                XCTFail("Opaque child did not receive the main-frame source-policy rejection")
                return
            }
            opaqueAuthorityDenied?.fulfill()
            return
        }
        if kind == "childAuthorityDenied" {
            guard !message.frameInfo.isMainFrame,
                  origin.protocol.lowercased() == "https",
                  origin.host.lowercased() == expectedHost,
                  [0, 443].contains(origin.port),
                  let error = body["error"] as? String,
                  error.contains("Invalid message origin") else {
                XCTFail("Trusted child did not receive the main-frame source-policy rejection")
                return
            }
            childAuthorityDenied?.fulfill()
            return
        }
        guard message.frameInfo.isMainFrame,
              origin.protocol.lowercased() == "https",
              [0, 443].contains(origin.port) else {
            XCTFail("Invalid outbound fixture acknowledgement")
            return
        }
        switch kind {
        case "ready":
            guard origin.host.lowercased() == expectedHost else { XCTFail("Unexpected trusted acknowledgement origin"); return }
            guard body["dispatcher"] as? String == "function" else { XCTFail("Protected dispatcher is unavailable"); return }
            if requiresProtectedDispatcher, body["protected"] as? Bool != true {
                XCTFail("Protected dispatcher was changed by page script")
                return
            }
            ready.fulfill()
        case "foreignReady":
            guard origin.host.lowercased() == "foreign.test", body["dispatcher"] as? String == "function" else { XCTFail("Invalid foreign acknowledgement"); return }
            foreignReady?.fulfill()
        case "authorityDenied":
            guard origin.host.lowercased() == "foreign.test",
                  let error = body["error"] as? String,
                  error.contains("Invalid message origin") else {
                XCTFail("Foreign document did not receive the source-policy rejection")
                return
            }
            authorityDenied?.fulfill()
        case "authorityAllowed": XCTFail("Foreign document authority was unexpectedly allowed")
        case "opaqueAuthorityAllowed": XCTFail("Opaque child authority was unexpectedly allowed")
        case "childAuthorityAllowed": XCTFail("Trusted child authority was unexpectedly allowed")
        case "tamperSucceeded": XCTFail("Page replaced the protected dispatcher")
        case "callback":
            if let expectedCallbackURL {
                guard let payload = body["message"] as? [String: Any],
                      payload["id"] as? String == "outbound-test",
                      payload["url"] as? String == expectedCallbackURL else {
                    XCTFail("Unexpected outbound callback payload")
                    return
                }
            }
            callback.fulfill()
        default: XCTFail("Unexpected outbound fixture acknowledgement")
        }
    }
}

private final class HeldAuthenticationSessionFactory {
    let created = XCTestExpectation(description: "Authentication session is created")
    private var session: HeldAuthenticationSession?

    func makeSession(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) -> ASWebAuthenticationSession {
        let session = HeldAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
        self.session = session
        created.fulfill()
        return session
    }

    func complete(_ url: URL) {
        session?.complete(url)
    }
}

private final class HeldAuthenticationSession: ASWebAuthenticationSession {
    private let completionHandler: CompletionHandler

    override init(url: URL, callbackURLScheme: String?, completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
        super.init(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
    }

    override var canStart: Bool { true }
    override func start() -> Bool { true }

    func complete(_ url: URL) {
        completionHandler(url, nil)
    }
}

private final class OutboundAnalyticsTransport: AnalyticsClientV2Protocol {
    let clientId = "outbound-source-validation"
    private var events: [(name: String, parameters: [String: Any])] = []

    var lastClientError: [String: Any]? {
        events.last(where: { $0.name == "client_error" })?.parameters
    }

    func log(eventName: String, parameters: [String: Any]) {
        events.append((name: eventName, parameters: parameters))
    }

    @MainActor
    func waitForClientError(identifier: String) async throws -> [String: Any] {
        try await TestHelpers.withTimeout {
            while true {
                if let event = self.events.last(where: {
                    $0.name == "client_error" && $0.parameters["error"] as? String == identifier
                }) {
                    return event.parameters
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }
}

private struct FailingOutboundPayload: Encodable {
    let error: Error

    init(error: Error = NSError(domain: "OutboundEncodingFixture", code: 42, userInfo: [
        NSLocalizedDescriptionKey: "private-payload",
        "url": "https://example.test/private-url",
    ])) {
        self.error = error
    }

    func encode(to encoder: Encoder) throws {
        throw error
    }
}

private struct LoggableOutboundEncodingError: CustomNSError, AnalyticLoggableErrorV2 {
    static let errorDomain = "OutboundEncodingFixture"
    var errorCode: Int { 43 }

    func analyticLoggableSerializeForLogging() -> [String: Any] {
        ["payload": "private-payload", "url": "https://example.test/private-url"]
    }
}

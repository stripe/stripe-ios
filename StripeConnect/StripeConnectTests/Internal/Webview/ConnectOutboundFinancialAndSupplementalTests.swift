//
//  ConnectOutboundFinancialAndSupplementalTests.swift
//  StripeConnectTests
//

@_spi(PrivatePreviewConnect) @testable import StripeConnect
@_spi(STP) import StripeCore
import StripeFinancialConnections
import UIKit
import WebKit
import XCTest

@MainActor
final class ConnectOutboundFinancialAndSupplementalTests: XCTestCase {

    func testFinancialConnectionsResultReachesTrustedDocument() async throws {
        let presenter = FinancialSupplementalHeldPresenter()
        defer { presenter.cancel() }
        let controller = makeController(presenter: presenter)
        let observer = installObserver(on: controller.webView)
        defer { remove(observer, from: controller.webView) }

        load(Self.trustedFinancialConnectionsHTML, in: controller.webView, observer: observer, host: "connect-js.stripe.com")
        try await observer.waitForReady(host: "connect-js.stripe.com")
        await fulfillment(of: [presenter.started], timeout: TestHelpers.defaultTimeout)

        presenter.complete(.canceled)
        let callback = try await observer.waitForCallback()
        XCTAssertEqual(callback.kind, "financialConnections")
        XCTAssertEqual(callback.id, "financial-result")
        let session = try XCTUnwrap(callback.payload?["financialConnectionsSession"] as? [String: Any])
        XCTAssertTrue((session["accounts"] as? [Any])?.isEmpty == true)
        XCTAssertNil(callback.payload?["token"])
        XCTAssertNil(callback.payload?["error"])
    }

    func testFinancialConnectionsResultDoesNotReachForeignDocumentAfterNavigation() async throws {
        let presenter = FinancialSupplementalHeldPresenter()
        defer { presenter.cancel() }
        let controller = makeController(presenter: presenter)
        let observer = installObserver(on: controller.webView)
        defer { remove(observer, from: controller.webView) }

        load(Self.trustedFinancialConnectionsHTML, in: controller.webView, observer: observer, host: "connect-js.stripe.com")
        try await observer.waitForReady(host: "connect-js.stripe.com")
        await fulfillment(of: [presenter.started], timeout: TestHelpers.defaultTimeout)

        load(Self.foreignHTML, in: controller.webView, observer: observer, host: "foreign.test")
        try await observer.waitForReady(host: "foreign.test")
        try await observer.waitForAuthorityDenial()
        presenter.complete(.canceled)
        try await observer.assertNoCallback()
    }

    func testSupplementalResultReachesTrustedDocument() async throws {
        let callback = FinancialSupplementalHeldCallback()
        defer { callback.cancel() }
        let controller = makeController(supplementalCallback: callback)
        let observer = installObserver(on: controller.webView)
        defer { remove(observer, from: controller.webView) }

        load(Self.trustedSupplementalHTML, in: controller.webView, observer: observer, host: "connect-js.stripe.com")
        try await observer.waitForReady(host: "connect-js.stripe.com")
        await fulfillment(of: [callback.started], timeout: TestHelpers.defaultTimeout)

        callback.complete()
        let result = try await observer.waitForCallback()
        XCTAssertEqual(result.kind, "supplemental")
        XCTAssertEqual(result.id, "supplemental-result")
        XCTAssertEqual(result.payload?["result"] as? String, "success")
        let returnValue = try XCTUnwrap(result.payload?["returnValue"] as? [String: Any])
        XCTAssertTrue(returnValue.isEmpty)
    }

    func testSupplementalResultDoesNotReachForeignDocumentAfterNavigation() async throws {
        let callback = FinancialSupplementalHeldCallback()
        defer { callback.cancel() }
        let controller = makeController(supplementalCallback: callback)
        let observer = installObserver(on: controller.webView)
        defer { remove(observer, from: controller.webView) }

        load(Self.trustedSupplementalHTML, in: controller.webView, observer: observer, host: "connect-js.stripe.com")
        try await observer.waitForReady(host: "connect-js.stripe.com")
        await fulfillment(of: [callback.started], timeout: TestHelpers.defaultTimeout)

        load(Self.foreignHTML, in: controller.webView, observer: observer, host: "foreign.test")
        try await observer.waitForReady(host: "foreign.test")
        try await observer.waitForAuthorityDenial()
        callback.complete()
        try await observer.assertNoCallback()
    }
}

private extension ConnectOutboundFinancialAndSupplementalTests {
    struct Props: HasSupplementalFunctions {
        enum CodingKeys: CodingKey {}
        let supplementalFunctions: SupplementalFunctions
    }

    func makeController(
        presenter: FinancialConnectionsPresenter = FinancialConnectionsPresenter(),
        supplementalCallback: FinancialSupplementalHeldCallback? = nil
    ) -> ConnectComponentWebViewController {
        let manager = EmbeddedComponentManager(apiClient: .init(publishableKey: "pk_test_outbound"), fetchClientSecret: { "unused" })
        let functions = SupplementalFunctions(handleCheckScanSubmitted: { details in
            guard let supplementalCallback else { return }
            XCTAssertEqual(details.checkScanToken, "check_token")
            try await supplementalCallback.wait()
        })
        return ConnectComponentWebViewController(
            componentManager: manager,
            componentType: .checkScanning,
            loadContent: false,
            analyticsClientFactory: { ComponentAnalyticsClient(client: FinancialSupplementalAnalyticsTransport(), commonFields: $0) },
            fetchInitProps: { Props(supplementalFunctions: functions) },
            didFailLoadWithError: { _ in },
            financialConnectionsPresenter: presenter
        )
    }

    func installObserver(on webView: WKWebView) -> FinancialSupplementalObserver {
        let observer = FinancialSupplementalObserver(expectedWebView: webView)
        webView.configuration.userContentController.add(observer, name: observer.name)
        return observer
    }

    func remove(_ observer: FinancialSupplementalObserver, from webView: WKWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: observer.name)
        observer.cancel()
    }

    func load(_ html: String, in webView: WKWebView, observer: FinancialSupplementalObserver, host: String) {
        observer.beginDocument(host: host)
        webView.loadHTMLString(html, baseURL: URL(string: "https://\(host)/fixture")!)
    }

    static let trustedFinancialConnectionsHTML = """
    <!doctype html><script>
    window.callSetterWithSerializableValue = (message) => window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'callback', callback: 'financialConnections', id: message.value.id, payload: message.value});
    window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'ready', dispatcher: typeof window.__stripeConnectDeliverSensitiveMessage});
    window.webkit.messageHandlers.openFinancialConnections.postMessage({clientSecret: 'fcs_test', id: 'financial-result', connectedAccountId: 'acct_test'});
    </script>
    """

    static let trustedSupplementalHTML = """
    <!doctype html><script>
    window.supplementalFunctionCompleted = (payload) => window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'callback', callback: 'supplemental', id: payload.invocationId, payload});
    window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'ready', dispatcher: typeof window.__stripeConnectDeliverSensitiveMessage});
    window.webkit.messageHandlers.fetchInitComponentProps.postMessage({}).then(() => window.webkit.messageHandlers.callSupplementalFunction.postMessage({functionName: 'handleCheckScanSubmitted', invocationId: 'supplemental-result', args: [{checkScanToken: 'check_token'}]}));
    </script>
    """

    static let foreignHTML = """
    <!doctype html><script>
    window.callSetterWithSerializableValue = (message) => window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'callback', callback: 'financialConnections', id: message.value.id, payload: message.value});
    window.supplementalFunctionCompleted = (payload) => window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'callback', callback: 'supplemental', id: payload.invocationId, payload});
    window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'ready', dispatcher: typeof window.__stripeConnectDeliverSensitiveMessage});
    window.webkit.messageHandlers.connectDocumentAuthority.postMessage({}).then(() => window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'authorityUnexpectedlyAccepted'}), (error) => window.webkit.messageHandlers.financialSupplementalObserver.postMessage({kind: 'authorityDenied', error: String(error)}));
    </script>
    """
}

private final class FinancialSupplementalHeldPresenter: FinancialConnectionsPresenter {
    let started = XCTestExpectation(description: "Financial Connections presentation starts")
    private var continuation: CheckedContinuation<FinancialConnectionsSheet.TokenResult, Never>?

    override func presentForToken(componentManager: EmbeddedComponentManager, clientSecret: String, connectedAccountId: String, from presentingViewController: UIViewController) async -> FinancialConnectionsSheet.TokenResult {
        started.fulfill()
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete(_ result: FinancialConnectionsSheet.TokenResult) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    func cancel() { complete(.canceled) }
}

private final class FinancialSupplementalHeldCallback {
    let started = XCTestExpectation(description: "Supplemental callback starts")
    private var continuation: CheckedContinuation<Void, Error>?

    func wait() async throws {
        started.fulfill()
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete() {
        continuation?.resume(returning: ())
        continuation = nil
    }

    func cancel() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

private struct FinancialSupplementalCallback {
    let kind: String
    let id: String?
    let payload: [String: Any]?
}

private final class FinancialSupplementalObserver: NSObject, WKScriptMessageHandler {
    let name = "financialSupplementalObserver"
    private weak var expectedWebView: WKWebView?
    private var ready = FinancialSupplementalGate<Void>()
    private var authority = FinancialSupplementalGate<Void>()
    private var callback = FinancialSupplementalGate<FinancialSupplementalCallback>()
    private var expectedHost = "connect-js.stripe.com"
    private var isForeign = false

    init(expectedWebView: WKWebView) {
        self.expectedWebView = expectedWebView
    }

    func beginDocument(host: String) {
        expectedHost = host
        isForeign = expectedHost == "foreign.test"
        ready.cancel()
        authority.cancel()
        callback.cancel()
        ready = FinancialSupplementalGate()
        authority = FinancialSupplementalGate()
        callback = FinancialSupplementalGate()
    }

    func waitForReady(host: String) async throws {
        expectedHost = host
        try await ready.wait()
    }

    func waitForAuthorityDenial() async throws { try await authority.wait() }
    func waitForCallback() async throws -> FinancialSupplementalCallback { try await callback.wait() }

    func assertNoCallback() async throws {
        try await callback.assertEmpty()
    }

    func cancel() {
        ready.cancel()
        authority.cancel()
        callback.cancel()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard message.webView === expectedWebView,
              message.frameInfo.isMainFrame,
              origin.protocol == "https",
              origin.host == expectedHost,
              [0, 443].contains(origin.port),
              let body = message.body as? [String: Any],
              let kind = body["kind"] as? String else {
            failAll(FinancialSupplementalFixtureError.invalidObserverMessage)
            return
        }
        switch kind {
        case "ready":
            guard body["dispatcher"] as? String == "function" else {
                failAll(FinancialSupplementalFixtureError.missingDispatcher)
                return
            }
            ready.finish(.success(()))
        case "authorityDenied" where isForeign:
            guard let error = body["error"] as? String,
                  error.contains("Invalid message origin") else {
                failAll(FinancialSupplementalFixtureError.unexpectedAuthorityError)
                return
            }
            authority.finish(.success(()))
        case "authorityUnexpectedlyAccepted": failAll(FinancialSupplementalFixtureError.authorityUnexpectedlyAccepted)
        case "callback":
            callback.finish(.success(.init(kind: body["callback"] as? String ?? "", id: body["id"] as? String, payload: body["payload"] as? [String: Any])))
        default: failAll(FinancialSupplementalFixtureError.invalidObserverMessage)
        }
    }

    private func failAll(_ error: Error) {
        ready.finish(.failure(error))
        authority.finish(.failure(error))
        callback.finish(.failure(error))
    }
}

private enum FinancialSupplementalFixtureError: Error {
    case invalidObserverMessage
    case missingDispatcher
    case unexpectedAuthorityError
    case authorityUnexpectedlyAccepted
    case unexpectedCallback
}

private final class FinancialSupplementalGate<Value> {
    private let lock = NSLock()
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?
    private var timeout: DispatchWorkItem?

    func wait() async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            defer { lock.unlock() }
            if let result {
                continuation.resume(with: result)
            } else {
                self.continuation = continuation
                let timeout = DispatchWorkItem { [weak self] in
                    self?.finish(.failure(TestHelperError.timeout(seconds: TestHelpers.defaultTimeout)))
                }
                self.timeout = timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + TestHelpers.defaultTimeout, execute: timeout)
            }
        }
    }

    func finish(_ result: Result<Value, Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let storedContinuation = continuation
        continuation = nil
        let storedTimeout = timeout
        self.timeout = nil
        lock.unlock()
        storedTimeout?.cancel()
        storedContinuation?.resume(with: result)
    }

    func cancel() { finish(.failure(CancellationError())) }

    func assertEmpty() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        lock.lock()
        let result = self.result
        lock.unlock()
        guard let result else { return }
        switch result {
        case .success: throw FinancialSupplementalFixtureError.unexpectedCallback
        case .failure(let error): throw error
        }
    }
}

private final class FinancialSupplementalAnalyticsTransport: AnalyticsClientV2Protocol {
    let clientId = "financial-supplemental-outbound"
    func log(eventName: String, parameters: [String: Any]) {}
}

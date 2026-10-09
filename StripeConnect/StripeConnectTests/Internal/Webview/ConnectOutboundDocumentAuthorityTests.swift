//
//  ConnectOutboundDocumentAuthorityTests.swift
//  StripeConnectTests
//

@testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

@MainActor
final class ConnectOutboundDocumentAuthorityTests: XCTestCase {
    func testPendingTrustedAuthorityDeliversAfterRelease() async throws {
        try await run(host: "connect-js.stripe.com", navigate: false, tamper: false, expectCallback: true)
    }

    func testPendingForeignAuthorityCannotDeliverWithArraySetterTamper() async throws {
        try await run(host: "foreign.test", navigate: false, tamper: true, expectCallback: false)
    }

    func testNavigationBeforeTrustedAuthorityReleaseDoesNotDeliver() async throws {
        try await run(host: "connect-js.stripe.com", navigate: true, tamper: false, expectCallback: false)
    }

    func testMissingAuthorityHandlerDoesNotPermitFakeDispatcher() async throws {
        try await run(host: "connect-js.stripe.com", navigate: false, tamper: false, expectCallback: false, installProxy: false)
    }

    func testMissingCallbackRefusesSensitiveDelivery() async throws {
        try await run(host: "connect-js.stripe.com", navigate: false, tamper: false, expectCallback: false, hasCallback: false)
    }

    func testMissingDispatcherRefusesSensitiveDelivery() async throws {
        try await run(host: "connect-js.stripe.com", navigate: false, tamper: false, expectCallback: false, hasDispatcher: false)
    }

    private func run(
        host: String,
        navigate: Bool,
        tamper: Bool,
        expectCallback: Bool,
        installProxy: Bool = true,
        hasCallback: Bool = true,
        hasDispatcher: Bool = true
    ) async throws {
        // Given a real component dispatcher whose native authorization reply can be held.
        let manager = EmbeddedComponentManager(apiClient: .init(publishableKey: "pk_test"), fetchClientSecret: { "unused" })
        let controller = ConnectComponentWebViewController(
            componentManager: manager,
            componentType: .payouts,
            loadContent: false,
            analyticsClientFactory: { ComponentAnalyticsClient(client: DocumentAuthorityTransport(), commonFields: $0) },
            didFailLoadWithError: { _ in }
        )
        let observer = DocumentAuthoritySourceObserver(webView: controller.webView, host: host, expectsDispatcher: hasDispatcher)
        let contentController = controller.webView.configuration.userContentController
        if !hasDispatcher {
            contentController.removeAllUserScripts()
        }
        contentController.add(observer, name: observer.name)
        let proxy = DocumentAuthorityReplyProxy(
            handler: ScriptMessageHandlerWithReply<VoidPayload, Bool>(
                name: "connectDocumentAuthority", sourcePolicy: controller.messageSourcePolicy, requiresMainFrame: true
            ) { _ in true },
            webView: controller.webView
        )
        contentController.removeScriptMessageHandler(forName: proxy.name, contentWorld: .page)
        if installProxy {
            contentController.addScriptMessageHandler(proxy, contentWorld: .page, name: proxy.name)
        }
        defer {
            proxy.release()
            proxy.cancel()
            observer.cancel()
            contentController.removeScriptMessageHandler(forName: observer.name)
            contentController.removeScriptMessageHandler(forName: proxy.name, contentWorld: .page)
            controller.webView.stopLoading()
        }
        controller.webView.loadHTMLString(
            DocumentAuthoritySourceObserver.html(tamper: tamper, replaceDispatcher: !installProxy, hasCallback: hasCallback, expectsDispatcher: hasDispatcher),
            baseURL: URL(string: "https://\(host)/fixture")!
        )
        if installProxy && hasDispatcher {
            let captured = try await proxy.firstRequest.wait()
            try captured.assertSource(host: host)
            if host == "connect-js.stripe.com" {
                XCTAssertEqual(captured.body as? Bool, true)
                XCTAssertNil(captured.error)
            } else {
                XCTAssertNil(captured.body)
                XCTAssertEqual(captured.error, "Invalid message origin")
            }
        }
        try await observer.ready.wait()

        // When delivery is requested before the held authorization reply is released.
        let documentID = try await controller.webView.evaluateJavaScript("this.__stripeConnectDocumentID") as? String
        let delivery = Task {
            try await controller.sendSensitiveMessageAsync(ReturnedFromAuthenticatedWebViewSender(
                payload: .init(url: URL(string: "stripe-connect://return")!, id: "timing")
            ), documentID: documentID)
        }
        try await observer.callback.assertEmpty()
        if navigate {
            observer.reset(host: "foreign.test")
            controller.webView.loadHTMLString(
                DocumentAuthoritySourceObserver.html(tamper: false, replaceDispatcher: false, hasCallback: true, expectsDispatcher: true),
                baseURL: URL(string: "https://foreign.test/fixture")!
            )
            let captured = try await proxy.secondRequest.wait()
            try captured.assertSource(host: "foreign.test")
            XCTAssertNil(captured.body)
            XCTAssertEqual(captured.error, "Invalid message origin")
            try await observer.ready.wait()
        }
        proxy.release()

        // Then only the original authorized document receives the exact result.
        if expectCallback {
            let payload = try await observer.callback.wait()
            XCTAssertEqual(payload["id"] as? String, "timing")
            XCTAssertEqual(payload["url"] as? String, "stripe-connect://return")
            try await delivery.value
        } else {
            try await observer.callback.assertEmpty()
            do {
                try await delivery.value
                XCTFail("Sensitive delivery unexpectedly succeeded")
            } catch {
                let refusal = error as NSError
                XCTAssertEqual(refusal.domain, "StripeConnect.SensitiveDeliveryError")
                XCTAssertEqual(refusal.code, 0)
            }
        }
    }
}

private enum DocumentAuthorityFixtureError: Error {
    case timeout
    case invalidMessage
    case unexpectedCallback
    case cancelled
}

@MainActor
private final class DocumentAuthorityReplyProxy: NSObject, WKScriptMessageHandlerWithReply {
    struct CapturedReply {
        let body: Any?
        let error: String?
        let expectedView: Bool
        let mainFrame: Bool
        let scheme: String
        let host: String
        let port: Int

        func assertSource(host expectedHost: String) throws {
            guard expectedView, mainFrame, scheme == "https", host == expectedHost, [0, 443].contains(port) else {
                throw DocumentAuthorityFixtureError.invalidMessage
            }
        }
    }

    let name = "connectDocumentAuthority"
    let firstRequest = DocumentAuthorityResultGate<CapturedReply>()
    let secondRequest = DocumentAuthorityResultGate<CapturedReply>()
    private let handler: ScriptMessageHandlerWithReply<VoidPayload, Bool>
    private weak var webView: WKWebView?
    private let releaseSignal = DocumentAuthoritySignal()
    private var requestCount = 0

    init(handler: ScriptMessageHandlerWithReply<VoidPayload, Bool>, webView: WKWebView) {
        self.handler = handler
        self.webView = webView
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        // Keep each production result local: navigation can create concurrent requests.
        let result = await handler.userContentController(controller, didReceive: message)
        let origin = message.frameInfo.securityOrigin
        let captured = CapturedReply(
            body: result.0, error: result.1, expectedView: message.webView === webView,
            mainFrame: message.frameInfo.isMainFrame,
            scheme: origin.protocol, host: origin.host, port: origin.port
        )
        requestCount += 1
        if requestCount == 1 {
            firstRequest.finish(captured)
        } else if requestCount == 2 {
            secondRequest.finish(captured)
        } else {
            firstRequest.fail(DocumentAuthorityFixtureError.invalidMessage)
            secondRequest.fail(DocumentAuthorityFixtureError.invalidMessage)
        }
        await releaseSignal.wait()
        return result
    }

    func release() { releaseSignal.release() }
    func cancel() {
        releaseSignal.release()
        firstRequest.fail(DocumentAuthorityFixtureError.cancelled)
        secondRequest.fail(DocumentAuthorityFixtureError.cancelled)
    }
}

@MainActor
private final class DocumentAuthoritySourceObserver: NSObject, WKScriptMessageHandler {
    let name = "documentAuthoritySourceObserver"
    private weak var webView: WKWebView?
    private var host: String
    private var expectsDispatcher: Bool
    private(set) var ready = DocumentAuthorityResultGate<Void>()
    private(set) var callback = DocumentAuthorityResultGate<[String: Any]>()

    init(webView: WKWebView, host: String, expectsDispatcher: Bool = true) {
        self.webView = webView
        self.host = host
        self.expectsDispatcher = expectsDispatcher
    }

    func reset(host: String, expectsDispatcher: Bool = true) {
        cancel()
        self.host = host
        self.expectsDispatcher = expectsDispatcher
        ready = DocumentAuthorityResultGate<Void>()
        callback = DocumentAuthorityResultGate<[String: Any]>()
    }

    func cancel() {
        ready.fail(DocumentAuthorityFixtureError.cancelled)
        callback.fail(DocumentAuthorityFixtureError.cancelled)
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard message.webView === webView, message.frameInfo.isMainFrame,
              origin.protocol == "https", origin.host == host, [0, 443].contains(origin.port),
              let body = message.body as? [String: Any] else {
            fail()
            return
        }
        if body["ready"] as? Bool == true,
           body["dispatcher"] as? String == (expectsDispatcher ? "function" : "undefined"),
           body["protected"] as? Bool == expectsDispatcher {
            ready.finish(())
        } else if let payload = body["callback"] as? [String: Any] {
            callback.finish(payload)
        } else {
            fail()
        }
    }

    private func fail() {
        ready.fail(DocumentAuthorityFixtureError.invalidMessage)
        callback.fail(DocumentAuthorityFixtureError.invalidMessage)
    }

    static func html(tamper: Bool, replaceDispatcher: Bool, hasCallback: Bool, expectsDispatcher: Bool) -> String {
        let arraySetter = tamper ? """
        Object.defineProperty(Array.prototype, "0", {
          configurable: true,
          set: function(candidate) {
            if (typeof candidate === "function") { candidate(); }
          }
        });
        """ : ""
        let replace = replaceDispatcher ? """
        this.__stripeConnectDeliverSensitiveMessage = function(_, payload) {
          window.webkit.messageHandlers.documentAuthoritySourceObserver.postMessage({ callback: payload });
        };
        try {
          Object.defineProperty(this, "__stripeConnectDeliverSensitiveMessage", { value: function() {} });
        } catch (_) {}
        """ : ""
        let callback = hasCallback ? """
        window.returnedFromAuthenticatedWebView = function(payload) {
          window.webkit.messageHandlers.documentAuthoritySourceObserver.postMessage({ callback: payload });
        };
        """ : ""
        let protected = expectsDispatcher ? """
        this.__stripeConnectDeliverSensitiveMessage === originalDispatcher &&
                     descriptor.configurable === false && descriptor.writable === false
        """ : "false"
        return """
        <!doctype html>
        <script>
        \(callback)
        const originalDispatcher = this.__stripeConnectDeliverSensitiveMessage;
        \(arraySetter)
        \(replace)
        const descriptor = Object.getOwnPropertyDescriptor(this, "__stripeConnectDeliverSensitiveMessage");
        window.webkit.messageHandlers.documentAuthoritySourceObserver.postMessage({
          ready: true,
          dispatcher: typeof this.__stripeConnectDeliverSensitiveMessage,
          protected: \(protected)
        });
        </script>
        """
    }
}

@MainActor
private final class DocumentAuthorityResultGate<Value> {
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?
    private var timer: Task<Void, Never>?

    func wait() async throws -> Value {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            if let result { return try result.get() }
            return try await withCheckedThrowingContinuation { continuation in
                precondition(self.continuation == nil, "A fixture gate supports one waiter")
                self.continuation = continuation
                timer = Task { [weak self] in
                    do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
                    self?.fail(DocumentAuthorityFixtureError.timeout)
                }
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                self?.fail(DocumentAuthorityFixtureError.cancelled)
            }
        }
    }

    func finish(_ value: Value) { resolve(.success(value)) }
    func fail(_ error: Error) { resolve(.failure(error)) }

    private func resolve(_ value: Result<Value, Error>) {
        guard result == nil else { return }
        result = value
        timer?.cancel()
        timer = nil
        continuation?.resume(with: value)
        continuation = nil
    }

    func assertEmpty() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        if let result {
            switch result {
            case .success: throw DocumentAuthorityFixtureError.unexpectedCallback
            case .failure(let error): throw error
            }
        }
    }
}

@MainActor
private final class DocumentAuthoritySignal {
    private var released = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if released { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func release() {
        guard !released else { return }
        released = true
        let waiting = continuations
        continuations.removeAll()
        for continuation in waiting { continuation.resume() }
    }
}

private final class DocumentAuthorityTransport: AnalyticsClientV2Protocol {
    let clientId = "authority"
    func log(eventName: String, parameters: [String: Any]) {}
}

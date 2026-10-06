//
//  IntentConfirmationChallengeViewControllerTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 5/14/26.
//

import WebKit
import XCTest

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments

class IntentConfirmationChallengeViewControllerTests: XCTestCase {

    private func makeVC(
        intentType: IntentType = .paymentIntent(id: "pi_test123"),
        apiClient: STPAPIClient = STPAPIClient(publishableKey: "pk_test_abc"),
        stripeJs: STPIntentActionUseStripeSDK.StripeJS? = nil,
        loadContent: Bool = true,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) -> IntentConfirmationChallengeViewController {
        let vc = IntentConfirmationChallengeViewController(
            publishableKey: "pk_test_abc",
            clientSecret: "pi_test123_secret_test456",
            intentType: intentType,
            apiClient: apiClient,
            stripeJs: stripeJs,
            loadContent: loadContent,
            completion: completion
        )
        _ = vc.view
        return vc
    }

    // MARK: - handleSuccess

    func testHandleSuccessCallsCompletionWithSuccess() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.handleSuccess()

        guard case .success = result else {
            XCTFail("Expected .success, got \(String(describing: result))")
            return
        }
    }

    // MARK: - handleError

    func testHandleErrorCallsCompletionWithFailure() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.handleError(ChallengeError.webError(message: "failed", type: "arkose_error", code: "ERR_1"))

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .webError(let msg, _, _) = challengeError else {
            XCTFail("Expected .failure(.webError), got \(String(describing: result))")
            return
        }
        XCTAssertEqual(msg, "failed")
    }

    // MARK: - closeButtonTapped

    func testCloseButtonTappedCompletesWithUserCanceled() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.closeButtonTapped()

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .userCanceled = challengeError else {
            XCTFail("Expected .failure(.userCanceled), got \(String(describing: result))")
            return
        }
    }

    // MARK: - WKNavigationDelegate

    func testWebViewNavigationFailureCallsCompletionWithNavigationFailed() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.webView(WKWebView(), didFail: nil, withError: underlyingError)

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .navigationFailed = challengeError else {
            XCTFail("Expected .failure(.navigationFailed), got \(String(describing: result))")
            return
        }
    }

    func testWebViewProvisionalNavigationFailureCallsCompletionWithNavigationFailed() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost)
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: underlyingError)

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .navigationFailed = challengeError else {
            XCTFail("Expected .failure(.navigationFailed), got \(String(describing: result))")
            return
        }
    }

    // MARK: - ChallengeError: analyticsErrorCode

    func testWebErrorAnalyticsCodeNilDefaultsToUnknown() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: nil)
        XCTAssertEqual(error.analyticsErrorCode, "unknown")
    }

    // MARK: - ChallengeError: errorDescription

    func testNavigationFailedDescriptionIncludesUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        XCTAssertEqual(ChallengeError.navigationFailed(underlying).errorDescription, "Navigation failed: Connection lost")
    }

    func testUserCanceledDescriptionIsNil() {
        XCTAssertNil(ChallengeError.userCanceled.errorDescription)
    }

    // MARK: - WebView message source validation

    func testHTTPChallengeDocumentCannotRetrieveInitializationParameters() throws {
        let webView = try makeBridgeWebView()

        // Given a document loaded from the configured challenge origin
        let trustedReply = try retrieveInitializationParameters(
            from: webView,
            baseURL: URL(string: "https://b.stripecdn.com/challenge")!
        )

        // Then it receives the initialization parameters
        XCTAssertEqual(trustedReply.parameters?["clientSecret"] as? String, "pi_test123_secret_test456")
        XCTAssertEqual(trustedReply.parameters?["publishableKey"] as? String, "pk_test_abc")
        XCTAssertNil(trustedReply.error)

        // When a same-host HTTP document invokes the actual bridge
        let untrustedReply = try retrieveInitializationParameters(
            from: webView,
            baseURL: URL(string: "http://b.stripecdn.com/challenge")!
        )

        // Then it receives a fixed error without initialization parameters
        XCTAssertNil(untrustedReply.parameters)
        XCTAssertTrue(untrustedReply.error?.contains("Invalid message origin") == true)
        XCTAssertFalse(untrustedReply.error?.contains("b.stripecdn.com") == true)
    }

    func testNonDefaultPortChallengeDocumentCannotRetrieveInitializationParameters() throws {
        let webView = try makeBridgeWebView()

        let reply = try retrieveInitializationParameters(
            from: webView,
            baseURL: URL(string: "https://b.stripecdn.com:8443/challenge")!
        )

        XCTAssertNil(reply.parameters)
        XCTAssertTrue(reply.error?.contains("Invalid message origin") == true)
    }

    func testSecondWebViewAtChallengeOriginCannotRetrieveInitializationParameters() throws {
        let challengeWebView = try makeBridgeWebView()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = challengeWebView.configuration.userContentController
        let secondWebView = WKWebView(frame: .zero, configuration: configuration)

        // When a second WebView shares the registered bridge and loads the configured origin
        let reply = try retrieveInitializationParameters(
            from: secondWebView,
            baseURL: URL(string: "https://b.stripecdn.com/challenge")!
        )

        // Then the controller does not disclose initialization parameters to that WebView
        XCTAssertNil(reply.parameters)
        XCTAssertTrue(reply.error?.contains("Invalid message origin") == true)
        XCTAssertFalse(reply.error?.contains("b.stripecdn.com") == true)
    }

    func testForeignChallengeDocumentCannotCompleteChallenge() throws {
        let completion = expectation(description: "Challenge completion")
        completion.isInverted = true
        let webView = try makeBridgeWebView { _ in completion.fulfill() }

        // When a foreign document invokes the actual success-message handler
        try submitSuccessMessage(
            from: webView,
            baseURL: URL(string: "https://attacker.example/challenge")!
        )

        // Then it cannot complete the challenge
        wait(for: [completion], timeout: 0.25)
    }

    func testOpaqueChildFrameCannotCompleteChallenge() throws {
        let completion = expectation(description: "Challenge completion")
        completion.isInverted = true
        let webView = try makeBridgeWebView { _ in completion.fulfill() }

        // When a sandboxed child frame under a trusted document invokes the success-message handler
        let source = try submitOpaqueChildSuccessMessage(from: webView)

        // Then its opaque origin cannot complete the challenge
        XCTAssertFalse(source.isMainFrame)
        XCTAssertTrue(source.wasSentByExpectedWebView)
        XCTAssertFalse(
            source.scheme.lowercased() == "https"
                && source.host.lowercased() == "b.stripecdn.com"
        )
        wait(for: [completion], timeout: 0.25)
    }

    func testTrustedChallengeDocumentCanCompleteChallenge() throws {
        let completion = expectation(description: "Challenge completion")
        let webView = try makeBridgeWebView { result in
            guard case .success = result else {
                return XCTFail("Expected successful challenge completion")
            }
            completion.fulfill()
        }

        try submitMessage(
            named: "onSuccess",
            body: "{}",
            from: webView,
            baseURL: URL(string: "https://b.stripecdn.com/challenge")!
        )

        wait(for: [completion], timeout: 5)
    }

    func testTrustedChallengeDocumentReportsWebError() throws {
        let completion = expectation(description: "Challenge error")
        let webView = try makeBridgeWebView { result in
            guard case .failure(let error) = result,
                  case .webError(let message, _, _) = error as? ChallengeError else {
                return XCTFail("Expected a web error")
            }
            XCTAssertEqual(message, "trusted error")
            completion.fulfill()
        }

        try submitMessage(
            named: "onError",
            body: #"{ message: "trusted error", type: "test" }"#,
            from: webView,
            baseURL: URL(string: "https://b.stripecdn.com/challenge")!
        )

        wait(for: [completion], timeout: 5)
    }

    func testForeignChallengeDocumentCannotReportWebError() throws {
        let completion = expectation(description: "Challenge error")
        completion.isInverted = true
        let webView = try makeBridgeWebView { _ in completion.fulfill() }

        try submitMessage(
            named: "onError",
            body: #"{ message: "foreign error", type: "test" }"#,
            from: webView,
            baseURL: URL(string: "https://attacker.example/challenge")!
        )

        wait(for: [completion], timeout: 0.25)
    }

    private func makeBridgeWebView(
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) throws -> WKWebView {
        let vc = makeVC(loadContent: false, completion: completion)
        let webView = try XCTUnwrap(vc.view.subviews.compactMap { $0 as? WKWebView }.first)
        webView.navigationDelegate = nil
        webView.stopLoading()
        return webView
    }

    private func retrieveInitializationParameters(
        from webView: WKWebView,
        baseURL: URL
    ) throws -> ChallengeBridgeReply {
        let observer = ChallengeBridgeReplyObserver(expectedWebView: webView)
        let contentController = webView.configuration.userContentController
        contentController.add(observer, name: observer.name)
        defer {
            contentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString("""
        <!doctype html>
        <script>
        window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "ready" });
        </script>
        """, baseURL: baseURL)
        wait(for: [observer.readyExpectation], timeout: 5)
        try assertReady(observer, expectedBaseURL: baseURL)

        try evaluateJavaScriptStrict("""
        window.webkit.messageHandlers.getInitParams.postMessage({}).then(
            function(parameters) {
                window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "reply", parameters: parameters });
            },
            function(error) {
                window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "error", error: String(error) });
            }
        );
        """, in: webView)
        wait(for: [observer.replyExpectation], timeout: 5)
        try assertReplyReceived(observer)
        return observer.reply
    }

    private func submitSuccessMessage(from webView: WKWebView, baseURL: URL) throws {
        let observer = ChallengeBridgeReplyObserver(expectedWebView: webView)
        let contentController = webView.configuration.userContentController
        contentController.add(observer, name: observer.name)
        defer {
            contentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString("""
        <!doctype html>
        <script>
        window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "ready" });
        </script>
        """, baseURL: baseURL)
        wait(for: [observer.readyExpectation], timeout: 5)
        try assertReady(observer, expectedBaseURL: baseURL)
        try submitMessage(named: "onSuccess", body: "{}", using: observer, in: webView)
    }

    private func submitOpaqueChildSuccessMessage(from webView: WKWebView) throws -> ChallengeBridgeSource {
        let observer = ChallengeBridgeReplyObserver(expectedWebView: webView)
        let contentController = webView.configuration.userContentController
        contentController.add(observer, name: observer.name)
        defer {
            contentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString("""
        <!doctype html>
        <body>
        <script>
        window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "ready" });
        const frame = document.createElement("iframe");
        frame.setAttribute("sandbox", "allow-scripts");
        frame.srcdoc = '<script>window.webkit.messageHandlers.onSuccess.postMessage({});window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "submitted" });<\\/script>';
        document.body.appendChild(frame);
        </script>
        </body>
        """, baseURL: URL(string: "https://b.stripecdn.com/challenge")!)
        wait(for: [observer.readyExpectation], timeout: 5)
        try assertReady(observer, expectedBaseURL: URL(string: "https://b.stripecdn.com/challenge")!)
        wait(for: [observer.replyExpectation], timeout: 5)
        try assertReplyReceived(observer)
        return observer.replySource
    }

    private func submitMessage(named name: String, body: String, from webView: WKWebView, baseURL: URL) throws {
        let observer = ChallengeBridgeReplyObserver(expectedWebView: webView)
        let contentController = webView.configuration.userContentController
        contentController.add(observer, name: observer.name)
        defer {
            contentController.removeScriptMessageHandler(forName: observer.name)
        }

        webView.loadHTMLString("""
        <!doctype html>
        <script>
        window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "ready" });
        </script>
        """, baseURL: baseURL)
        wait(for: [observer.readyExpectation], timeout: 5)
        try assertReady(observer, expectedBaseURL: baseURL)
        try submitMessage(named: name, body: body, using: observer, in: webView)
    }

    private func submitMessage(
        named name: String,
        body: String,
        using observer: ChallengeBridgeReplyObserver,
        in webView: WKWebView
    ) throws {
        try evaluateJavaScriptStrict("""
        window.webkit.messageHandlers.\(name).postMessage(\(body));
        window.webkit.messageHandlers.\(observer.name).postMessage({ kind: "submitted" });
        """, in: webView)
        wait(for: [observer.replyExpectation], timeout: 5)
        try assertReplyReceived(observer)
    }

    private func assertReady(_ observer: ChallengeBridgeReplyObserver, expectedBaseURL: URL) throws {
        guard observer.didReceiveReady else {
            throw ChallengeFixtureError.timedOutWaitingForReady
        }
        XCTAssertTrue(observer.readySource.wasSentByExpectedWebView)
        XCTAssertTrue(observer.readySource.isMainFrame)
        XCTAssertEqual(observer.readySource.scheme.lowercased(), expectedBaseURL.scheme?.lowercased())
        XCTAssertEqual(observer.readySource.host.lowercased(), expectedBaseURL.host?.lowercased())
        if let expectedPort = expectedBaseURL.port {
            XCTAssertEqual(observer.readySource.port, expectedPort)
        } else if expectedBaseURL.scheme?.lowercased() == "https" {
            XCTAssertTrue([0, 443].contains(observer.readySource.port))
        }
        XCTContext.runActivity(named: "Observed WebKit origin: \(observer.readySource.scheme)://\(observer.readySource.host):\(observer.readySource.port), main frame: \(observer.readySource.isMainFrame)") { _ in }
    }

    private func assertReplyReceived(_ observer: ChallengeBridgeReplyObserver) throws {
        guard observer.didReceiveReply else {
            throw ChallengeFixtureError.timedOutWaitingForBridgeSubmission
        }
    }

    private func evaluateJavaScriptStrict(_ script: String, in webView: WKWebView) throws {
        let completed = expectation(description: "JavaScript execution")
        var evaluationError: Error?
        var didComplete = false
        webView.evaluateJavaScript(script) { _, error in
            evaluationError = error
            didComplete = true
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
        guard didComplete else {
            throw ChallengeFixtureError.timedOutEvaluatingJavaScript
        }
        if let evaluationError {
            throw evaluationError
        }
    }
}

private enum ChallengeFixtureError: Error {
    case timedOutWaitingForReady
    case timedOutWaitingForBridgeSubmission
    case timedOutEvaluatingJavaScript
}

private struct ChallengeBridgeReply {
    let parameters: [String: Any]?
    let error: String?
}

private struct ChallengeBridgeSource {
    let scheme: String
    let host: String
    let port: Int
    let isMainFrame: Bool
    let wasSentByExpectedWebView: Bool
}

private final class ChallengeBridgeReplyObserver: NSObject, WKScriptMessageHandler {
    let name = "intentConfirmationChallengeReplyObserver"
    let readyExpectation = XCTestExpectation(description: "Challenge fixture is ready")
    let replyExpectation = XCTestExpectation(description: "Challenge bridge replied")

    private weak var expectedWebView: WKWebView?

    private(set) var didReceiveReady = false
    private(set) var didReceiveReply = false
    private(set) var readySource = ChallengeBridgeSource(
        scheme: "",
        host: "",
        port: 0,
        isMainFrame: true,
        wasSentByExpectedWebView: false
    )
    private(set) var replySource = ChallengeBridgeSource(
        scheme: "",
        host: "",
        port: 0,
        isMainFrame: true,
        wasSentByExpectedWebView: false
    )
    private(set) var reply = ChallengeBridgeReply(parameters: nil, error: nil)

    init(expectedWebView: WKWebView) {
        self.expectedWebView = expectedWebView
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let securityOrigin = message.frameInfo.securityOrigin
        let source = ChallengeBridgeSource(
            scheme: securityOrigin.protocol,
            host: securityOrigin.host,
            port: securityOrigin.port,
            isMainFrame: message.frameInfo.isMainFrame,
            wasSentByExpectedWebView: message.webView === expectedWebView
        )

        guard let body = message.body as? [String: Any],
              let kind = body["kind"] as? String else {
            return
        }

        switch kind {
        case "ready":
            guard !didReceiveReady else {
                return
            }
            didReceiveReady = true
            readySource = source
            readyExpectation.fulfill()
        case "reply":
            guard !didReceiveReply else {
                return
            }
            reply = ChallengeBridgeReply(parameters: body["parameters"] as? [String: Any], error: nil)
            didReceiveReply = true
            replySource = source
            replyExpectation.fulfill()
        case "error":
            guard !didReceiveReply else {
                return
            }
            reply = ChallengeBridgeReply(parameters: nil, error: body["error"] as? String)
            didReceiveReply = true
            replySource = source
            replyExpectation.fulfill()
        case "submitted":
            guard !didReceiveReply else {
                return
            }
            didReceiveReply = true
            replySource = source
            replyExpectation.fulfill()
        default:
            break
        }
    }
}

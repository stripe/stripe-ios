//
//  ScriptWebTestBase.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import WebKit
import XCTest

class ScriptWebTestBase: XCTestCase {

    var webView: WKWebView!

    override func setUp() {
        super.setUp()
        webView = WKWebView(frame: .zero, configuration: .init())
    }

    override func tearDown() {
        webView = nil
        super.tearDown()
    }

    func loadTrustedDocument() async throws {
        let navigationObserver = NavigationObserver()
        webView.navigationDelegate = navigationObserver
        defer {
            navigationObserver.cancel()
            webView.navigationDelegate = nil
        }

        try await navigationObserver.loadTrustedDocument(in: webView)
    }

    func validateMessageSent<Sender: MessageSender>(sender: Sender) throws {
        let expectation = try webView.expectationForMessageReceived(sender: sender)
        try webView.sendMessage(sender: sender)

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}

private final class NavigationObserver: NSObject, WKNavigationDelegate {
    private let result = NavigationResult<Void>()

    func loadTrustedDocument(in webView: WKWebView) async throws {
        webView.loadHTMLString("<!doctype html>", baseURL: StripeConnectConstants.connectJSBaseURL)
        try await result.wait()
    }

    func cancel() {
        result.cancel()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        result.finish(.success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        result.finish(.failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        result.finish(.failure(error))
    }
}

private final class NavigationResult<Value> {
    private let lock = NSLock()
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?
    private var timeout: DispatchWorkItem?

    func wait() async throws -> Value {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                defer { lock.unlock() }
                if let result {
                    continuation.resume(with: result)
                    return
                }
                self.continuation = continuation
                let timeout = DispatchWorkItem { [weak self] in
                    self?.finish(.failure(TestHelperError.timeout(seconds: TestHelpers.defaultTimeout)))
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

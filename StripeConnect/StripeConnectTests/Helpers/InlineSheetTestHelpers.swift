//
//  InlineSheetTestHelpers.swift
//  StripeConnectTests
//

@testable import StripeConnect
import UIKit
import WebKit
import XCTest

enum InlineSheetTestURLs {
    static let accessoryLayer = URL(string: "https://connect-js.stripe.com/accessory_layer_0123abcdef.html#layer_type=overlay&component=stripe-connect-notification-banner&os_sheet=true&os_sheet_id=sheet-1")!

    static func accessoryLayer(sheetId: String) -> URL {
        URL(string: "https://connect-js.stripe.com/accessory_layer_0123abcdef.html#layer_type=overlay&os_sheet=true&os_sheet_id=\(sheetId)")!
    }
}

/// Frame info with a real WebKit security origin, for creating windows outside of a real `window.open`
final class InlineSheetMockFrameInfo: WKFrameInfo {
    private let isMainFrameOverride: Bool
    private let securityOriginOverride: WKSecurityOrigin

    init(isMainFrame: Bool, securityOrigin: WKSecurityOrigin) {
        isMainFrameOverride = isMainFrame
        securityOriginOverride = securityOrigin
        super.init()
    }

    override var isMainFrame: Bool { isMainFrameOverride }
    override var securityOrigin: WKSecurityOrigin { securityOriginOverride }
}

final class InlineSheetMockNavigationAction: WKNavigationAction {
    private let requestOverride: URLRequest
    private let sourceFrameOverride: WKFrameInfo
    private let targetFrameOverride: WKFrameInfo?
    private let navigationTypeOverride: WKNavigationType

    init(url: URL,
         sourceFrame: WKFrameInfo = WKFrameInfo(),
         targetFrame: WKFrameInfo? = nil,
         navigationType: WKNavigationType = .other) {
        requestOverride = URLRequest(url: url)
        sourceFrameOverride = sourceFrame
        targetFrameOverride = targetFrame
        navigationTypeOverride = navigationType
        super.init()
    }

    override var request: URLRequest { requestOverride }
    override var sourceFrame: WKFrameInfo { sourceFrameOverride }
    override var targetFrame: WKFrameInfo? { targetFrameOverride }
    override var navigationType: WKNavigationType { navigationTypeOverride }
}

final class InlineSheetMockTargetFrame: WKFrameInfo {
    private let isMainFrameOverride: Bool

    init(isMainFrame: Bool) {
        isMainFrameOverride = isMainFrame
        super.init()
    }

    override var isMainFrame: Bool { isMainFrameOverride }
}

/// Loads a document at `baseURL` and returns the security origin WebKit reports for it
@MainActor
func inlineSheetSecurityOrigin(for baseURL: URL) async throws -> WKSecurityOrigin {
    let observer = SecurityOriginObserver()
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(observer, name: SecurityOriginObserver.name)
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.loadHTMLString("""
    <!doctype html>
    <script>window.webkit.messageHandlers.\(SecurityOriginObserver.name).postMessage({});</script>
    """, baseURL: baseURL)
    let origin = try await TestHelpers.withTimeout {
        try await observer.wait()
    }
    configuration.userContentController.removeScriptMessageHandler(forName: SecurityOriginObserver.name)
    return origin
}

/// Loads a document whose sandboxed child frame has an opaque origin, and returns that origin
@MainActor
func inlineSheetOpaqueSecurityOrigin() async throws -> WKSecurityOrigin {
    let observer = SecurityOriginObserver()
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(observer, name: SecurityOriginObserver.name)
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.loadHTMLString("""
    <!doctype html>
    <iframe sandbox="allow-scripts" srcdoc='<script>window.webkit.messageHandlers.\(SecurityOriginObserver.name).postMessage({});</script>'></iframe>
    """, baseURL: StripeConnectConstants.connectJSBaseURL)
    let origin = try await TestHelpers.withTimeout {
        try await observer.wait()
    }
    configuration.userContentController.removeScriptMessageHandler(forName: SecurityOriginObserver.name)
    return origin
}

private final class SecurityOriginObserver: NSObject, WKScriptMessageHandler {
    static let name = "inlineSheetSecurityOriginObserver"

    private var origin: WKSecurityOrigin?
    private var continuation: CheckedContinuation<WKSecurityOrigin, Error>?

    @MainActor
    func wait() async throws -> WKSecurityOrigin {
        if let origin {
            return origin
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard origin == nil else { return }
        origin = message.frameInfo.securityOrigin
        continuation?.resume(returning: message.frameInfo.securityOrigin)
        continuation = nil
    }
}

// Captures UIKit presentation requests in hostless XCTest.
final class InlineSheetHostController: ConnectComponentWebViewController {
    private(set) var presentedControllers: [UIViewController] = []

    var lastPresentedController: UIViewController? {
        presentedControllers.last
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedControllers.append(viewControllerToPresent)
        completion?()
    }

    func clearPresentedControllers() {
        presentedControllers.removeAll()
    }
}

extension WKWebView {
    /// Runs JavaScript and waits until WebKit has delivered every bridge message it posted
    @discardableResult
    func evaluateJavaScriptAndWait(_ script: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            evaluateJavaScript(script) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

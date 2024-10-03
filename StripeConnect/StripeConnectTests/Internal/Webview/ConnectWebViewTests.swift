//
//  ConnectWebViewTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation

import QuickLook
import SafariServices
@testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class ConnectWebViewTests: XCTestCase {

    private var mockURLOpener: MockURLOpener!
    private var mockFileManager: MockFileManager!
    var webView: ConnectWebView!

    override func setUp() {
        super.setUp()
        mockFileManager = .init()
        mockURLOpener = .init()
        webView = ConnectWebView(frame: .zero,
                                 configuration: .init(),
                                 urlOpener: mockURLOpener,
                                 fileManager: mockFileManager,
                                 sdkVersion: "1.2.3")
    }

    func testUserAgent() {
        // Create an expectation for the asynchronous operation
        let expectation = XCTestExpectation(description: "User Agent Fetched")
        webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
            defer {
                expectation.fulfill()
            }

            if let error = error {
                XCTFail("Error fetching user agent: \(error.localizedDescription)")
                return
            }

            guard let userAgent = result as? String else {
                XCTFail("User agent is not a string")
                return
            }

            XCTAssertTrue(userAgent.hasSuffix("- stripe-ios/1.2.3"), "User agent should include the SDK identifier but value was: \(String(describing: result))")
        }
        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    /// HTTP/HTTPS navigations with no target from a non-allowlisted host should open in a SafariVC
    func testPopupOpenSafariVCIfNotInAllowedHosts() {
        var safariVC: SFSafariViewController?
        webView.presentPopup = { vc in
            safariVC = vc as? SFSafariViewController
        }
        let webView = webView.webView(webView,
                        createWebViewWith: webView.configuration,
                        for: MockNavigationAction(request: .init(url: URL(string: "https://stripe.com")!)),
                        windowFeatures: .init())

        XCTAssertNil(webView)
        XCTAssertNotNil(safariVC)
    }

    /// HTTP/HTTPS navigations with no target and an allowlisted host should open in a popup webview
    func testOpenAsPopUpIfInAllowedHosts() {
        for url in [
            "https://connect-js.stripe.com",
            "https://connect-js.stripe.com/hello",
            "https://connect.stripe.com/",
            "https://connect.stripe.com/test",
            "http://connect-js.stripe.com",
            "http://connect-js.stripe.com/hello",
            "http://connect.stripe.com/",
            "http://connect.stripe.com/test",
        ] {
            var popUp: PopupWebViewController?
            webView.presentPopup = { vc in
                popUp = (vc as? UINavigationController)?.viewControllers.first as? PopupWebViewController

            }
            let webView = webView.webView(webView,
                                          createWebViewWith: webView.configuration,
                                          for: MockNavigationAction(request: .init(url: URL(string: url)!)),
                                          windowFeatures: .init())

            XCTAssertEqual(popUp?.webView, webView, url)
            XCTAssertNotNil(popUp?.navigationItem.rightBarButtonItem, url)
            XCTAssertEqual(popUp?.webView.sdkVersion, "1.2.3", url)
        }
    }

    /// Non-HTTP/HTTPS navigations with no target should use the system's URL routing
    func testPopupWithCustomURLScheme() {
        let url = URL(string: "connect://test")!
        let canOpenURLExpectation = XCTestExpectation(description: "Can open url called")
        let openURLExpectation = XCTestExpectation(description: "Open url called")

        mockURLOpener.canOpenURLOverride = { _ in
            canOpenURLExpectation.fulfill()
            return true
        }
        mockURLOpener.openURLOverride = { openURL, _, _ in
            XCTAssertEqual(url, openURL)
            openURLExpectation.fulfill()
        }
        webView.presentPopup = { _ in
            XCTFail("Present pop up should not be called")
        }
        let webView = webView.webView(webView,
                                      createWebViewWith: webView.configuration,
                                      for: MockNavigationAction(request: .init(url: url)),
                                      windowFeatures: .init())

        XCTAssertNil(webView)
        wait(for: [canOpenURLExpectation, openURLExpectation], timeout: TestHelpers.defaultTimeout)
    }

    /// Any navigation request with a non-nil target should not open a popup
    func testNonPopupNavigations() {
        let url = URL(string: "connect://test")!
        mockURLOpener.canOpenURLOverride = { _ in
            XCTFail("Can open url should not be called")
            return true
        }
        mockURLOpener.openURLOverride = { _, _, _ in
            XCTFail("Open url should not be called")
        }
        webView.presentPopup = { _ in
            XCTFail("Present pop up should not be called")
        }
        let webView = webView.webView(webView,
                                      createWebViewWith: webView.configuration,
                                      for: MockNavigationAction(request: .init(url: url), targetFrame: .init()),
                                      windowFeatures: .init())

        XCTAssertNil(webView)
    }

    /// `window.close()` should close the view
    func testWindowCloseDismissesView() {
        var didCloseCalled = false
        webView.didClose = { wv in
            XCTAssertEqual(wv, self.webView)
            didCloseCalled = true
        }
        webView.uiDelegate?.webViewDidClose?(webView)
        XCTAssertTrue(didCloseCalled)
    }

    /// Download if `Content-Disposition` header is an attachment
    @MainActor
    func testResponsePolicyForAttachments() async {
        // Use a non-allow listed URL to ensure these can be treated as a download
        let response = HTTPURLResponse(
            url: URL(string: "https://stripe-s3.com/path")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Disposition": "attachment; filename=payouts.csv"]
        )!

        let policy = await webView.webView(
            webView,
            decidePolicyFor: MockNavigationResponse(
                response: response,
                canShowMIMEType: true
            )
        )
        XCTAssertEqual(policy, .download)
    }

    /// Non-download and non-HTTP/HTTPS responses should use the system's URL routing
    @MainActor
    func testResponsePolicyForCustomURLScheme() async {
        let response = URLResponse(
            url: URL(string: "connect://test")!,
            mimeType: nil,
            expectedContentLength: 100,
            textEncodingName: nil
        )

        let canOpenURLExpectation = XCTestExpectation(description: "Can open url called")
        let openURLExpectation = XCTestExpectation(description: "Open url called")

        mockURLOpener.canOpenURLOverride = { _ in
            canOpenURLExpectation.fulfill()
            return true
        }
        mockURLOpener.openURLOverride = { openURL, _, _ in
            XCTAssertEqual(response.url, openURL)
            openURLExpectation.fulfill()
        }
        webView.presentPopup = { _ in
            XCTFail("Present pop up should not be called")
        }

        let policy = await webView.webView(
            webView,
            decidePolicyFor: MockNavigationResponse(
                response: response,
                canShowMIMEType: true
            )
        )
        XCTAssertEqual(policy, .cancel)

        await fulfillment(of: [canOpenURLExpectation, openURLExpectation], timeout: TestHelpers.defaultTimeout)
    }

    /// Non-download HTTP/HTTPS responses with from a non-allowlisted host should open in a SafariVC
    @MainActor
    func testResponsePolicyForDisallowedHosts() async {
        var safariVC: SFSafariViewController?
        webView.presentPopup = { vc in
            safariVC = vc as? SFSafariViewController
        }
        let response = URLResponse(
            url: URL(string: "https://stripe.com")!,
            mimeType: nil,
            expectedContentLength: 100,
            textEncodingName: nil
        )

        let policy = await webView.webView(
            webView,
            decidePolicyFor: MockNavigationResponse(
                response: response,
                canShowMIMEType: true
            )
        )
        XCTAssertEqual(policy, .cancel)
        XCTAssertNotNil(safariVC)
    }

    /// Non-download HTTP/HTTPS responses with an allowlisted host should be allowed
    @MainActor
    func testResponsePolicyForNonAttachmentAllowedHosts() async {
        for url in [
            "https://connect-js.stripe.com",
            "https://connect-js.stripe.com/hello",
            "https://connect.stripe.com/",
            "https://connect.stripe.com/test",
            "http://connect-js.stripe.com",
            "http://connect-js.stripe.com/hello",
            "http://connect.stripe.com/",
            "http://connect.stripe.com/test",
        ] {
            let response = URLResponse(
                url: URL(string: url)!,
                mimeType: nil,
                expectedContentLength: 100,
                textEncodingName: nil
            )

            let policy = await webView.webView(
                webView,
                decidePolicyFor: MockNavigationResponse(
                    response: response,
                    canShowMIMEType: true
                )
            )
            XCTAssertEqual(policy, .allow)
        }
    }

    @MainActor
    func testDownloadDestination() async {
        let destination = await webView.download(
            decideDestinationUsing: .init(),
            suggestedFilename: "example.csv"
        )

        XCTAssertEqual(destination?.lastPathComponent, "example.csv")
        XCTAssert(destination?.absoluteString.starts(with: "file:///temp/") == true, String(describing: destination ))

        XCTAssertEqual(webView.downloadedFile, destination)
    }

    @MainActor
    func testDownloadDestinationIsTempUniqueFolder() async {
        let destination1 = await webView.download(
            decideDestinationUsing: .init(),
            suggestedFilename: "example.csv"
        )
        let destination2 = await webView.download(
            decideDestinationUsing: .init(),
            suggestedFilename: "example.csv"
        )

        // Different file path is created for repeating the same download
        XCTAssertNotEqual(destination1, destination2)

        // Filename matches suggestion
        XCTAssertEqual(destination1?.lastPathComponent, "example.csv")
        XCTAssertEqual(destination2?.lastPathComponent, "example.csv")

        // File located in temp directory
        XCTAssertEqual(destination1?.absoluteString.starts(with: "file:///temp/"), true, String(describing: destination1?.absoluteString ))
        XCTAssertEqual(destination2?.absoluteString.starts(with: "file:///temp/"), true, String(describing: destination2?.absoluteString ))
    }

    @MainActor
    func testErrorCreatingDownloadDestinationShowsAlert() async {
        var alertController: UIAlertController?
        webView.presentPopup = { vc in
            alertController = vc as? UIAlertController
        }
        mockFileManager.overrideCreateDirectory = { _, _, _ in
            throw NSError(domain: "Test", code: 0)
        }

        let destination = await webView.download(
            decideDestinationUsing: .init(),
            suggestedFilename: "example.csv"
        )
        XCTAssertNil(destination)
        XCTAssertNotNil(alertController)
        XCTAssertEqual(alertController?.message,
                       "There was an unexpected error -- try again in a few seconds")
        XCTAssertEqual(alertController?.preferredStyle, .alert)
    }

    func testDownloadFailedShowsAlert() {
        var alertController: UIAlertController?
        webView.presentPopup = { vc in
            alertController = vc as? UIAlertController
        }
        webView.download(
            didFailWithError: NSError(domain: "Test", code: 0),
            resumeData: nil
        )
        XCTAssertNotNil(alertController)
        XCTAssertEqual(alertController?.message,
                       "There was an unexpected error -- try again in a few seconds")
        XCTAssertEqual(alertController?.preferredStyle, .alert)
    }

    func testDownloadFinishedShowsPreview() {
        let mockFileURL = URL(string: "file:///temp/example.csv")!

        var previewController: QLPreviewController?
        webView.presentPopup = { vc in
            previewController = vc as? QLPreviewController
        }
        webView.downloadedFile = mockFileURL

        webView.downloadDidFinish()
        XCTAssertNotNil(previewController)
    }
}

private class MockNavigationAction: WKNavigationAction {
    let requestOverride: URLRequest
    let targetFrameOverride: WKFrameInfo?

    override var request: URLRequest {
        requestOverride
    }

    override var targetFrame: WKFrameInfo? {
        targetFrameOverride
    }

    init(request: URLRequest, targetFrame: WKFrameInfo? = nil) {
        self.requestOverride = request
        self.targetFrameOverride = targetFrame
        super.init()
    }
}

private class MockNavigationResponse: WKNavigationResponse {
    let responseOverride: URLResponse
    let canShowMIMETypeOverride: Bool

    override var response: URLResponse {
        responseOverride
    }

    override var canShowMIMEType: Bool {
        canShowMIMETypeOverride
    }

    init(response: URLResponse,
         canShowMIMEType: Bool) {
        self.responseOverride = response
        self.canShowMIMETypeOverride = canShowMIMEType
        super.init()
    }
}

private class MockURLOpener: ApplicationURLOpener {
    var canOpenURLOverride: ((_ url: URL) -> Bool)?
    var openURLOverride: ((_ url: URL, _ options: [UIApplication.OpenExternalURLOptionsKey: Any], _ completion: OpenCompletionHandler?) -> Void)?

    func canOpenURL(_ url: URL) -> Bool {
        canOpenURLOverride?(url) ?? false
    }

    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: OpenCompletionHandler?) {
        openURLOverride?(url, options, completion)
    }
}

private class MockFileManager: FileManager {
    override var temporaryDirectory: URL {
        URL(string: "file:///temp")!
    }

    var overrideCreateDirectory: ((_ url: URL, _ createIntermediates: Bool, _ attributes: [FileAttributeKey: Any]?) throws -> Void)?

    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        try overrideCreateDirectory?(url, createIntermediates, attributes)
    }
}

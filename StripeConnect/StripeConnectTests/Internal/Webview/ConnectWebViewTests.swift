//
//  ConnectWebViewTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation

@_spi(STP) import StripeCore
@testable import StripeConnect
import XCTest
import WebKit
import SafariServices

class ConnectWebViewTests: XCTestCase {
    
    var mockURLOpener: MockURLOpener!
    var webView: ConnectWebView!
    
    override func setUp() {
        mockURLOpener = .init()
        webView = ConnectWebView(frame: .zero,
                                 configuration: .init(),
                                 urlOpener: mockURLOpener,
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
    
    func testOpenSafariVCIfNotInAllowedHosts() {
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
    
    func testOpenAsPopUpIfInAllowedHosts() {
        for url in [
            "https://connect-js.stripe.com",
            "https://connect-js.stripe.com/hello",
            "https://connect.stripe.com/",
            "https://connect.stripe.com/test",
            "http://connect-js.stripe.com",
            "http://connect-js.stripe.com/hello",
            "http://connect.stripe.com/",
            "http://connect.stripe.com/test"
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
    
    func testCustomURLScheme() {
        let url = URL(string: "connect://test")!
        let canOpenURLExpectation = XCTestExpectation(description: "Can open url called")
        let openURLExpectation = XCTestExpectation(description: "Open url called")

        mockURLOpener.canOpenURLOverride = { url in
            canOpenURLExpectation.fulfill()
            return true
        }
        mockURLOpener.openURLOverride = { openURL, _, _ in
            XCTAssertEqual(url, openURL)
            openURLExpectation.fulfill()
        }
        webView.presentPopup = { vc in
            XCTFail("Present pop up should not be called")
        }
        let webView = webView.webView(webView,
                                      createWebViewWith: webView.configuration,
                                      for: MockNavigationAction(request: .init(url: url)),
                                      windowFeatures: .init())
        
        XCTAssertNil(webView)
        wait(for: [canOpenURLExpectation, openURLExpectation], timeout: 0.1)
    }
    
    func testJavascriptPopupHandling() {
        let url = URL(string: "connect://test")!
        mockURLOpener.canOpenURLOverride = { url in
            XCTFail("Can open url should not be called")
            return true
        }
        mockURLOpener.openURLOverride = { openURL, _, _ in
            XCTFail("Open url should not be called")
        }
        webView.presentPopup = { vc in
            XCTFail("Present pop up should not be called")
        }
        let webView = webView.webView(webView,
                                      createWebViewWith: webView.configuration,
                                      for: MockNavigationAction(request: .init(url: url), targetFrame: .init()),
                                      windowFeatures: .init())
        
        XCTAssertNil(webView)
    }
}


class MockNavigationAction: WKNavigationAction {
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

class MockURLOpener: ApplicationURLOpener {
    var canOpenURLOverride: ((_ url: URL) -> Bool)?
    var openURLOverride: ((_ url: URL, _ options: [UIApplication.OpenExternalURLOptionsKey : Any], _ completion: ((Bool) -> Void)?) -> Void)?
    
    func canOpenURL(_ url: URL) -> Bool {
        canOpenURLOverride?(url) ?? false
    }

    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler completion: ((Bool) -> Void)?) {
        openURLOverride?(url, options, completion)
    }
}

//
//  HCaptchaWebViewManager__HTML__Tests.swift
//  HCaptcha_Tests
//
//  Created by Aleksey Berezka on 17.08.2021.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

@_spi(STP) @testable import StripePayments

import WebKit
import XCTest

class HCaptchaWebViewManager__HTML__Tests: XCTestCase {
    var webViewContentIsAvailable: XCTestExpectation!
    var webViewContent: String?

    override func setUpWithError() throws {
        try super.setUpWithError()

        webViewContentIsAvailable = expectation(description: "get webview content")
        _ = HCaptchaDebugInfo.json
    }

    override func tearDownWithError() throws {
        webViewContentIsAvailable = nil

        try super.tearDownWithError()
    }

    func test__Size_Is_Mapped_Into_HTML() throws {
        let config = try HCaptchaConfig(html: "size: ${size}", size: .compact)
        let manager = HCaptchaWebViewManager(config: config)
        waitForWebViewContent(manager: manager)
        XCTAssertEqual(webViewContent, "size: compact")
    }

    func test__Orientation_Is_Mapped_Into_HTML() throws {
        let config = try HCaptchaConfig(html: "orientation: ${orientation}",
                                        orientation: .portrait)
        let manager = HCaptchaWebViewManager(config: config)
        waitForWebViewContent(manager: manager)
        XCTAssertEqual(webViewContent, "orientation: portrait")
    }
}

extension HCaptchaWebViewManager__HTML__Tests: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.innerHTML",
                                   completionHandler: { [weak self] (result: Any?, _) in
                                    self?.webViewContentIsAvailable.fulfill()
                                    self?.webViewContent = result as? String
                                   })
    }
}

extension HCaptchaWebViewManager__HTML__Tests {
    func waitForWebViewContent(manager: HCaptchaWebViewManager) {
        manager.webView.navigationDelegate = self
        wait(for: [webViewContentIsAvailable], timeout: 5)
    }
}

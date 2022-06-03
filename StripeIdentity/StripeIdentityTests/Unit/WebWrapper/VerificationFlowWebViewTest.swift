//
//  VerificationFlowWebViewTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity

@available(iOS 14.3, *)
final class VerificationFlowWebViewTest: XCTestCase {

    private var verificationWebView: VerificationFlowWebView!
    private var didFinishLoadingExpectation: XCTestExpectation!
    private var mockFileURL: URL!

    private var urlFromDelegateCallback: URL?

    override func setUp() {
        super.setUp()

        // Reset expectation
        didFinishLoadingExpectation = XCTestExpectation(description: "WebView finished loading")

        // Reset url
        urlFromDelegateCallback = nil

        // Create VerificationFlowWebView
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "mock", withExtension: "html") else {
            return XCTFail("Could not load mock html file")
        }
        mockFileURL = url
        
        verificationWebView = VerificationFlowWebView(initialURL: url)
        verificationWebView.delegate = self
    }

    func testURLChange() {
        XCTAssertNil(urlFromDelegateCallback)
        verificationWebView.load()
        XCTAssertEqual(urlFromDelegateCallback, mockFileURL)

        let newURL = URL(string: "https://stripe.com/")!
        verificationWebView.webView.load(URLRequest(url: newURL))
        XCTAssertEqual(urlFromDelegateCallback, newURL)
    }
}

@available(iOS 14.3, *)
extension VerificationFlowWebViewTest: VerificationFlowWebViewDelegate {
    func verificationFlowWebView(_ view: VerificationFlowWebView, didChangeURL url: URL?) {
        urlFromDelegateCallback = url
    }

    func verificationFlowWebViewDidClose(_ view: VerificationFlowWebView) { }

    func verificationFlowWebViewDidFinishLoading(_ view: VerificationFlowWebView) {
        didFinishLoadingExpectation.fulfill()
    }

    func verificationFlowWebView(_ view: VerificationFlowWebView, didOpenURLInNewTarget url: URL) { }
}

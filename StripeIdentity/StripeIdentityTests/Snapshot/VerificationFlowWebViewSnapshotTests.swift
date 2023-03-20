//
//  VerificationFlowWebViewSnapshotTests.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import WebKit
import FBSnapshotTestCase
@_spi(STP) import StripeCore

@testable import StripeIdentity

@available(iOS 14.3, *)
final class VerificationFlowWebViewSnapshotTests: FBSnapshotTestCase {

    private var verificationWebView: VerificationFlowWebView!
    private var didFinishLoadingExpectation: XCTestExpectation!

    override func setUp() {
        super.setUp()
//        recordMode = true

        // Reset expectation
        didFinishLoadingExpectation = XCTestExpectation(description: "WebView finished loading")

        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "mock", withExtension: "html") else {
            return XCTFail("Could not load mock html file")
        }

        verificationWebView = VerificationFlowWebView(initialURL: url)
        verificationWebView.delegate = self

        // Size to device for snapshot
        verificationWebView.frame = UIScreen.main.bounds

        UIActivityIndicatorView.stp_isAnimationEnabled = false
    }

    override func tearDown() {
        UIActivityIndicatorView.stp_isAnimationEnabled = true
        super.tearDown()
    }

    func testLoading() {
        verificationWebView.load()
        STPSnapshotVerifyView(verificationWebView)
    }

    func testLoaded() {
        verificationWebView.load()

        wait(for: [
            didFinishLoadingExpectation,
        ], timeout: 5)

        /*
         NOTE(mludowise): The WKWebView takes additional time to render the html
         after it's finished loading, and does not provide a delegate callback
         to know when this is completed. So for the sake of this test, we'll just
         set the background color of the webView to ensure it's visible and not
         obstructed after load finishes.
         */
        verificationWebView.webView.backgroundColor = .purple

        STPSnapshotVerifyView(verificationWebView)
    }

    func testError() {
        verificationWebView.displayRetryMessage()
        STPSnapshotVerifyView(verificationWebView)
    }
}

@available(iOS 14.3, *)
extension VerificationFlowWebViewSnapshotTests: VerificationFlowWebViewDelegate {
    func verificationFlowWebView(_ view: VerificationFlowWebView, didChangeURL url: URL?) { }

    func verificationFlowWebViewDidFinishLoading(_ view: VerificationFlowWebView) {
        didFinishLoadingExpectation.fulfill()
    }

    func verificationFlowWebViewDidClose(_ view: VerificationFlowWebView) { }

    func verificationFlowWebView(_ view: VerificationFlowWebView, didOpenURLInNewTarget url: URL) { }
}

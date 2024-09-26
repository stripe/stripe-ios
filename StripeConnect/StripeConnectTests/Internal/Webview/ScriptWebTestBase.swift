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

    func validateMessageSent<Sender: MessageSender>(sender: Sender) throws {
        let expectation = try webView.expectationForMessageReceived(sender: sender)
        try webView.sendMessage(sender: sender)

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}

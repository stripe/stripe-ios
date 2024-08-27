//
//  ReturnedFromAuthenticatedWebViewSenderTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation
@testable import StripeConnect
import XCTest

class ReturnedFromAuthenticatedWebViewSenderTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: ReturnedFromAuthenticatedWebViewSender(payload: .init(url: "https://dashboard.stripe.com")))
    }
    
    func testSenderSignature() {
        XCTAssertEqual(
            ReturnedFromAuthenticatedWebViewSender(payload: .init(url: "https://dashboard.stripe.com")).javascriptMessage,
            """
            window.returnedFromAuthenticatedWebView({"url":"https:\\/\\/dashboard.stripe.com"});
            """
        )
    }
}

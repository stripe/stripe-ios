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
        try validateMessageSent(sender: ReturnedFromAuthenticatedWebViewSender(payload: .init(url: URL(string: "https://dashboard.stripe.com")!, id: "123")))
    }

    func testSenderSignature() {
        XCTAssertEqual(
            try ReturnedFromAuthenticatedWebViewSender(payload: .init(url: URL(string: "https://dashboard.stripe.com")!, id: "123")).javascriptMessage(),
            """
            window.returnedFromAuthenticatedWebView({"id":"123","url":"https:\\/\\/dashboard.stripe.com"});
            """
        )
    }
}

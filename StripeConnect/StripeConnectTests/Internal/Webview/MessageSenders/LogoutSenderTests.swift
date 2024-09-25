//
//  LogoutSenderTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/24/24.
//

@testable import StripeConnect
import XCTest

class LogoutSenderTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: LogoutSender())
    }

    func testSenderSignature() {
        XCTAssertEqual(
            LogoutSender().javascriptMessage,
            """
            window.logout({});
            """
        )
    }
}

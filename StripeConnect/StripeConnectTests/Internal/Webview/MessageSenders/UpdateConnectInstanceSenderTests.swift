//
//  UpdateConnectInstanceSenderTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation
@testable import StripeConnect
import XCTest

class UpdateConnectInstanceSenderTests: MessageSenderTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: UpdateConnectInstanceSender(payload: .init(locale: "en")))
    }
    
    func testSenderSignature() {
        XCTAssertEqual(
            UpdateConnectInstanceSender(payload: .init(locale: "en")).javascriptMessage,
            """
            window.updateConnectInstance({"locale":"en"});
            """
        )
    }
}

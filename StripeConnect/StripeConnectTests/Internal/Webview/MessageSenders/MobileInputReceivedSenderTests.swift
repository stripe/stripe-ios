//
//  MobileInputReceivedSenderTests.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/12/25.
//

import Foundation
@testable import StripeConnect
import XCTest

class MobileInputReceivedSenderTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: MobileInputReceivedSender())
    }

    func testSenderSignature() {
        XCTAssertEqual(
            try MobileInputReceivedSender().javascriptMessage(),
            """
            window.mobileInputReceived({"input":"closeButtonPressed"});
            """
        )
    }
}

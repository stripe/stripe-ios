//
//  UpdateConnectInstanceSenderTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation
@testable import StripeConnect
import XCTest

class UpdateConnectInstanceSenderTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: UpdateConnectInstanceSender(payload: .init(locale: "en", appearance: .default)))
    }

    func testSenderSignature() {
        XCTAssertEqual(
            try UpdateConnectInstanceSender(payload: .init(locale: "en", appearance: .default)).javascriptMessage(),
            """
            window.updateConnectInstance({"appearance":{"variables":{"fontFamily":"-apple-system","fontSizeBase":"16px"}},"locale":"en"});
            """
        )
    }
}

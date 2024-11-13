//
//  CallSetterWithSerializableValueSenderTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation
@testable import StripeConnect
import XCTest

class CallSetterWithSerializableValueSenderTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: CallSetterWithSerializableValueSender(payload: .init(setter: "setPayment", value: "pi_1234")))
    }

    func testSenderSignature() throws {
        XCTAssertEqual(
            try CallSetterWithSerializableValueSender(payload: .init(setter: "setPayment", value: "pi_1234")).javascriptMessage(),
            """
            window.callSetterWithSerializableValue({"setter":"setPayment","value":"pi_1234"});
            """
        )
    }
}

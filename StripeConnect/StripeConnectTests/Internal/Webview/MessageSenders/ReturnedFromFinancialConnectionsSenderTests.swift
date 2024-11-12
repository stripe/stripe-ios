//
//  ReturnedFromFinancialConnectionsSenderTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

@testable import StripeConnect
import XCTest

class ReturnedFromFinancialConnectionsSenderTests: ScriptWebTestBase {
    func testSendMessage() throws {
        try validateMessageSent(sender: ReturnedFromFinancialConnectionsSender(payload: .init(bankToken: "bank_token", id: "1234")))
    }

    func testSenderSignature() {
        XCTAssertEqual(
            ReturnedFromFinancialConnectionsSender(payload: .init(bankToken: "bank_token", id: "1234")).javascriptMessage,
            """
            window.returnedFromFinancialConnections({"bankToken":"bank_token","id":"1234"});
            """
        )
    }
}

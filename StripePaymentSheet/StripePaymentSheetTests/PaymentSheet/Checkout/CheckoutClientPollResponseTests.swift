//
//  CheckoutClientPollResponseTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

final class CheckoutClientPollResponseTests: XCTestCase {
    func testRejectsUnknownConfirmationStatus() throws {
        var json = pollJSON
        json["confirmation_status"] = "new_status"

        XCTAssertThrowsError(try decode(json)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                return XCTFail("Expected dataCorrupted, got \(error)")
            }
            XCTAssertEqual(context.codingPath.last?.stringValue, "confirmation_status")
        }
    }

    private var pollJSON: [String: Any] {
        [
            "id": "cs_test_123",
            "livemode": false,
            "ui_mode": "mobile_elements",
            "confirmation_status": "succeeded",
            "status": "complete",
            "payment_status": "unpaid",
        ]
    }

    private func decode(_ json: [String: Any]) throws -> CheckoutClientPollResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try StripeJSONDecoder().decode(CheckoutClientPollResponse.self, from: data)
    }
}

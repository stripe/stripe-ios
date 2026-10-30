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
        let data = try JSONSerialization.data(withJSONObject: [
            "id": "cs_test_123",
            "confirmation_status": "new_status",
            "status": "open",
            "payment_status": "unpaid",
        ])

        XCTAssertThrowsError(try StripeJSONDecoder().decode(CheckoutClientPollResponse.self, from: data)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                return XCTFail("Expected dataCorrupted, got \(error)")
            }
            XCTAssertEqual(context.codingPath.last?.stringValue, "confirmation_status")
        }
    }
}

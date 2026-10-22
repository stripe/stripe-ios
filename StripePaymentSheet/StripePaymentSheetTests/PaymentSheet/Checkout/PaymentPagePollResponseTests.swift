//
//  PaymentPagePollResponseTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentPagePollResponseTests: XCTestCase {
    func testDecodesEveryState() throws {
        let cases: [(String, PaymentPagePollResponse.State)] = [
            ("active", .active),
            ("failed_async_payment", .failedAsyncPayment),
            ("pending_async_customer_action", .pendingAsyncCustomerAction),
            ("processing_subscription", .processingSubscription),
            ("processing_async_payment", .processingAsyncPayment),
            ("processing_sync_payment", .processingSyncPayment),
            ("succeeded", .succeeded),
            ("invalid", .invalid),
            ("expired", .expired),
        ]

        for (rawValue, expected) in cases {
            let response = try decode(state: rawValue)
            XCTAssertEqual(response.state, expected, rawValue)
        }
    }

    func testUnknownStateFailsToDecode() throws {
        XCTAssertThrowsError(try decode(state: "new_state")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testPaymentObjectStatusOnlyDistinguishesRequiresPaymentMethod() throws {
        XCTAssertEqual(
            try decode(paymentObjectStatus: "requires_payment_method").paymentObjectStatus,
            .requiresPaymentMethod
        )

        for rawValue in [
            "canceled",
            "expired",
            "processing",
            "processing_sync",
            "requires_action",
            "requires_capture",
            "requires_confirmation",
            "requires_reauthorization",
            "succeeded",
            "new_status",
        ] {
            XCTAssertEqual(
                try decode(paymentObjectStatus: rawValue).paymentObjectStatus,
                .other,
                rawValue
            )
        }
    }

    func testPaymentObjectStatusCanBeNullOrMissing() throws {
        XCTAssertNil(try decode(paymentObjectStatus: nil).paymentObjectStatus)

        let json: [String: Any] = [
            "session_id": "cs_test_123",
            "state": "active",
        ]
        XCTAssertNil(try decode(json).paymentObjectStatus)
    }

    private func decode(
        state: String = "active",
        paymentObjectStatus: String? = nil
    ) throws -> PaymentPagePollResponse {
        var json: [String: Any] = [
            "session_id": "cs_test_123",
            "state": state,
            "payment_object_status": NSNull(),
        ]
        if let paymentObjectStatus {
            json["payment_object_status"] = paymentObjectStatus
        }
        return try decode(json)
    }

    private func decode(_ json: [String: Any]) throws -> PaymentPagePollResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try StripeJSONDecoder().decode(PaymentPagePollResponse.self, from: data)
    }
}

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
    func testDecodesEveryConfirmationStatus() throws {
        let cases: [(String, CheckoutClientPollResponse.ConfirmationStatus)] = [
            ("not_started", .notStarted),
            ("pending", .pending),
            ("succeeded", .succeeded),
            ("failed", .failed),
        ]

        for (rawValue, expected) in cases {
            var json = pollJSON
            json["confirmation_status"] = rawValue

            let response = try decode(json)

            XCTAssertEqual(response.sessionId, "cs_test_123")
            XCTAssertEqual(response.confirmationStatus, expected, rawValue)
        }
    }

    func testDecodesSessionStatusAndPaymentStatus() throws {
        let paymentStatuses: [(String, CheckoutController.Session.Status.PaymentStatus)] = [
            ("paid", .paid),
            ("unpaid", .unpaid),
            ("no_payment_required", .noPaymentRequired),
        ]

        for (rawPaymentStatus, expectedPaymentStatus) in paymentStatuses {
            let statuses: [(String, CheckoutController.Session.Status)] = [
                ("open", .open),
                ("complete", .complete(expectedPaymentStatus)),
                ("expired", .expired),
            ]
            for (rawStatus, expectedStatus) in statuses {
                var json = pollJSON
                json["status"] = rawStatus
                json["payment_status"] = rawPaymentStatus

                let response = try decode(json)

                XCTAssertEqual(response.status, expectedStatus)
                XCTAssertEqual(response.paymentStatus, expectedPaymentStatus)
            }
        }
    }

    func testFailedConfirmationCanHaveACompleteSession() throws {
        // Given an async payment failed after the Session became complete
        var json = pollJSON
        json["confirmation_status"] = "failed"
        json["status"] = "complete"
        json["state"] = "complete"

        // When decoding the poll response
        let response = try decode(json)

        // Then confirmation failure is preserved independently of Session completion
        XCTAssertEqual(response.confirmationStatus, .failed)
        XCTAssertEqual(response.status, .complete(.unpaid))
        XCTAssertEqual(response.paymentStatus, .unpaid)
    }

    func testSuccessfulConfirmationDoesNotImplyPaymentIsPaid() throws {
        // Given checkout is client-complete while an async payment is still unpaid
        var json = pollJSON
        json["confirmation_status"] = "succeeded"
        json["status"] = "complete"

        let response = try decode(json)

        XCTAssertEqual(response.confirmationStatus, .succeeded)
        XCTAssertEqual(response.status, .complete(.unpaid))
        XCTAssertEqual(response.paymentStatus, .unpaid)
    }

    func testIgnoresInternalStateAndUnrelatedFields() throws {
        var json = pollJSON
        json["state"] = "new_internal_state"
        json["future_field"] = ["value": true]

        XCTAssertEqual(try decode(json), try decode(pollJSON))
    }

    func testRequiredFieldsCannotBeMissingOrNull() throws {
        for key in ["id", "confirmation_status", "status", "payment_status"] {
            var json = pollJSON
            json.removeValue(forKey: key)
            XCTAssertThrowsError(try decode(json), "Missing \(key)") { error in
                XCTAssertTrue(error is DecodingError)
            }

            json[key] = NSNull()
            XCTAssertThrowsError(try decode(json), "Null \(key)") { error in
                XCTAssertTrue(error is DecodingError)
            }
        }
    }

    func testUnknownStatusesFailToDecode() throws {
        for key in ["confirmation_status", "status", "payment_status"] {
            var json = pollJSON
            json[key] = "new_status"

            XCTAssertThrowsError(try decode(json), key) { error in
                guard case DecodingError.dataCorrupted(let context) = error else {
                    return XCTFail("Expected dataCorrupted, got \(error)")
                }
                XCTAssertEqual(context.codingPath.last?.stringValue, key)
            }
        }
    }

    private var pollJSON: [String: Any] {
        [
            "id": "cs_test_123",
            "livemode": false,
            "ui_mode": "mobile_elements",
            "confirmation_status": "pending",
            "status": "open",
            "payment_status": "unpaid",
        ]
    }

    private func decode(_ json: [String: Any]) throws -> CheckoutClientPollResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try StripeJSONDecoder().decode(CheckoutClientPollResponse.self, from: data)
    }
}

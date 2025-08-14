//
//  STPErrorTests.swift
//  StripeCoreTests
//

@testable @_spi(STP) import StripeCore
import XCTest

class STPErrorTests: XCTestCase {

    func testLocalizedUserMessage() {
        // Test common error codes
        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "incorrect_number"),
            NSError.stp_cardErrorInvalidNumberUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "invalid_number"),
            NSError.stp_cardErrorInvalidNumberUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "invalid_expiry_month"),
            NSError.stp_cardErrorInvalidExpMonthUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "invalid_expiry_year"),
            NSError.stp_cardErrorInvalidExpYearUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "invalid_cvc"),
            NSError.stp_cardInvalidCVCUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "expired_card"),
            NSError.stp_cardErrorExpiredCardUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "card_declined"),
            NSError.stp_cardErrorDeclinedUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "processing_error"),
            NSError.stp_cardErrorProcessingErrorUserMessage()
        )
    }

    func testLocalizedUserMessageWithDeclineCode() {
        // Test decline codes (which should map correctly through the same API)
        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "card_declined"),
            NSError.stp_cardErrorDeclinedUserMessage()
        )

        XCTAssertEqual(
            STPError.localizedUserMessage(forErrorCode: "generic_decline"),
            NSError.stp_genericDeclineErrorUserMessage()
        )
    }

    func testLocalizedUserMessageWithInvalidCode() {
        // Test non-existent code returns nil
        XCTAssertNil(STPError.localizedUserMessage(forErrorCode: "non_existent_code"))
    }
}

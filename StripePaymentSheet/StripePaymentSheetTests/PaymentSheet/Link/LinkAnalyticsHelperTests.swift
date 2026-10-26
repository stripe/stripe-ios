//
//  LinkAnalyticsHelperTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class LinkAnalyticsHelperTests: XCTestCase {
    func testLinkAnalyticsHelpersKeepTheirOwnCheckoutContext() throws {
        // Given two flows sharing the same analytics client
        let client = STPTestingAnalyticsClient()
        let checkout = LinkAnalyticsHelper(analyticsClient: client, checkoutSessionID: "cs_test_123")
        let standalone = LinkAnalyticsHelper(analyticsClient: client)

        // When their popup events interleave
        checkout.logPopupShow(sessionType: .ephemeral)
        standalone.logPopupShow(sessionType: .ephemeral)
        checkout.logPopupSuccess(sessionType: .ephemeral)

        // Then the standalone event has no Checkout context, and Checkout keeps its own
        let events = client._testLogHistory
        XCTAssertEqual(events.compactMap { $0["event"] as? String }, [
            "link.popup.show", "link.popup.show", "link.popup.success",
        ])
        XCTAssertEqual(try XCTUnwrap(events.first)["checkout_session_id"] as? String, "cs_test_123")
        XCTAssertNil(try XCTUnwrap(events.dropFirst().first)["checkout_session_id"])
        XCTAssertEqual(try XCTUnwrap(events.last)["checkout_session_id"] as? String, "cs_test_123")
    }
}

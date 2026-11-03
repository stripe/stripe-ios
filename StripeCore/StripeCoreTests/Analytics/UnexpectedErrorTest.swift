//
//  UnexpectedErrorTest.swift
//  StripeCoreTests
//
//  Created by Yuki on 11/2/26.
//

import Foundation
@testable@_spi(InternalOnlyAPI) import StripeCore
import XCTest

class UnexpectedErrorTest: XCTestCase {
    func testSerialization() {
        let error: Error = UnexpectedError(nonPIIErrorMessage: "Payment option out of sync.")

        let params = error.serializeForV1Analytics()

        XCTAssertEqual(params["error_type"] as? String, "UnexpectedError")
        XCTAssertEqual(params["error_code"] as? String, "unexpected")
        let errorDetails = params["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["error_message"] as? String, "Payment option out of sync.")
    }

    func testDescriptions() {
        let error = UnexpectedError(nonPIIErrorMessage: "Payment option out of sync.")

        // Localized descriptions are for users; string interpolation is for diagnostics.
        XCTAssertEqual((error as Error).localizedDescription, NSError.stp_unexpectedErrorMessage())
        XCTAssertEqual("\(error)", "Payment option out of sync.")
    }

    func testLogUnexpectedError() {
        let analyticsClient = STPAnalyticsClient()
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true

        let error = logUnexpectedError(
            "Could not find a presenting view controller.",
            event: .unexpectedCheckoutElementsError,
            code: "missing_presenting_view_controller",
            analyticsClient: analyticsClient
        )

        XCTAssertEqual(analyticsClient._testLogHistory.count, 1)
        let event = analyticsClient._testLogHistory.first
        XCTAssertEqual(event?["event"] as? String, "unexpected_error.checkout_elements")
        XCTAssertEqual(event?["error_code"] as? String, "missing_presenting_view_controller")
        // Dashboards use the top-level message; later serialization preserves error_details.
        XCTAssertEqual(event?["error_message"] as? String, "Could not find a presenting view controller.")
        let errorDetails = event?["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["error_message"] as? String, "Could not find a presenting view controller.")
        XCTAssertFalse(STPAssertTestUtil.shouldSuppressNextSTPAlert)
        XCTAssertEqual(error.nonPIIErrorMessage, "Could not find a presenting view controller.")
        XCTAssertEqual(error.code, "missing_presenting_view_controller")
    }
}

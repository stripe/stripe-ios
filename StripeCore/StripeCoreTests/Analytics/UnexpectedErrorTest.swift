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
    func testSerializeForV1Analytics_defaultsCodeAndCarriesMessage() {
        // Given an UnexpectedError with no explicit code...
        let error = UnexpectedError(nonPIIErrorMessage: "Something that should never happen happened.")

        // When serialized directly (as ErrorAnalytic does at the original log call)...
        let params = error.serializeForV1Analytics()

        // Then the message survives under error_details, unlike a plain Swift enum
        // error's associated value, which serializeForV1Analytics() would otherwise drop.
        XCTAssertEqual(params["error_type"] as? String, "UnexpectedError")
        XCTAssertEqual(params["error_code"] as? String, "unexpected")
        let errorDetails = params["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["error_message"] as? String, "Something that should never happen happened.")
    }

    func testSerializeForV1Analytics_customCodeForDashboardBucketing() {
        // Given a caller that wants a stable, specific bucket instead of the generic default...
        let error = UnexpectedError(nonPIIErrorMessage: "Failed to parse response.", code: "response_parsing_failed")

        // Then error_code reflects the custom code, and the message is still preserved.
        let params = error.serializeForV1Analytics()
        XCTAssertEqual(params["error_code"] as? String, "response_parsing_failed")
        let errorDetails = params["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["error_message"] as? String, "Failed to parse response.")
    }

    func testSerializeForV1Analytics_survivesReserialization() {
        // Given an UnexpectedError that gets wrapped as a generic `Error` somewhere downstream
        // (simulating code that catches/rethrows it and later calls serializeForV1Analytics()
        // again for an unrelated analytic, the way CheckoutControllerAnalyticsHelper.logFailed does)...
        let error: Error = UnexpectedError(nonPIIErrorMessage: "Payment option out of sync.")

        // Then the message is still recovered, because it lives on the type via
        // AnalyticLoggableError, not on a one-time `additionalNonPIIParams` passed at the
        // original call site.
        let params = error.serializeForV1Analytics()
        let errorDetails = params["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["error_message"] as? String, "Payment option out of sync.")
    }

    func testErrorDescription_isGenericAndLocalized_notTheDiagnosticMessage() {
        // Given a message containing internal diagnostic detail...
        let error = UnexpectedError(nonPIIErrorMessage: "Could not present Apple Pay. Check Apple Pay setup in Wallet.")

        // Then the merchant/customer-facing description is the SDK's generic, actually-localized
        // string, not the raw diagnostic text — unlike CheckoutError.unknown's errorDescription,
        // which returned debugDescription verbatim.
        XCTAssertEqual(error.errorDescription, NSError.stp_unexpectedErrorMessage())
        XCTAssertEqual((error as Error).localizedDescription, NSError.stp_unexpectedErrorMessage())
        XCTAssertNotEqual(error.errorDescription, error.nonPIIErrorMessage)
    }

    func testDescription_isTheDiagnosticMessage() {
        // `description` (CustomStringConvertible) is for engineers — interpolating the error in a
        // log statement or assertion message should surface the diagnostic detail.
        let error = UnexpectedError(nonPIIErrorMessage: "Checkout Session unexpectedly expired after confirmation.")
        XCTAssertEqual(error.description, "Checkout Session unexpectedly expired after confirmation.")
        XCTAssertEqual("\(error)", "Checkout Session unexpectedly expired after confirmation.")
    }

    func testLogUnexpectedError_logsAndReturnsTheError() {
        // Given a non-shared analytics client, so this test doesn't pollute global state...
        let analyticsClient = STPAnalyticsClient()

        // When logging an unexpected error for a given event (suppressing the SDK assertion that
        // log() fires for any "unexpected_error"-prefixed event, same as other Checkout tests)...
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        let returnedError = logUnexpectedError(
            "Could not find a presenting view controller.",
            event: .unexpectedCheckoutElementsError,
            code: "missing_presenting_view_controller",
            analyticsClient: analyticsClient
        )

        // Then the analytic fires exactly once, carrying the event, code, and message...
        let events = analyticsClient._testLogHistory.filter { $0["event"] as? String == "unexpected_error.checkout_elements" }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?["error_code"] as? String, "missing_presenting_view_controller")
        let errorDetails = events.first?["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["error_message"] as? String, "Could not find a presenting view controller.")

        // ...and the SDK assertion fired with the diagnostic message...
        XCTAssertFalse(STPAssertTestUtil.shouldSuppressNextSTPAlert)
        XCTAssertTrue(STPAssertTestUtil.lastAssertMessage.contains("Could not find a presenting view controller."))

        // ...and the returned error is usable directly as a `throw` site's thrown value.
        XCTAssertEqual(returnedError.nonPIIErrorMessage, "Could not find a presenting view controller.")
        XCTAssertEqual(returnedError.code, "missing_presenting_view_controller")
    }
}

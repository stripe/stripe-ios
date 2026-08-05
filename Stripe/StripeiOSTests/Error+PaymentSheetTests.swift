//
//  Error+PaymentSheetTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 3/21/23.
//

import Foundation
import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet

class Error_PaymentSheetTests: XCTestCase {

    private enum TestableError: LocalizedError {
        case generic
        case custom(String)

        var errorDescription: String? {
            switch self {
            case .generic:
                return NSError.stp_unexpectedErrorMessage()
            case .custom(let errorMessage):
                return errorMessage
            }
        }
    }

    func testPaymentSheetError_UsesDebugDescription() {
        let error = PaymentSheetError.unknown(debugDescription: "Test debugDescription")

        XCTAssertEqual("An unknown error occurred in PaymentSheet. Test debugDescription", error.nonGenericDescription)
    }

    func testError_HasGenericLocalizedDescription_NoSeverError() {
        XCTAssertEqual(NSError.stp_unexpectedErrorMessage(), TestableError.generic.nonGenericDescription)
    }

    // MARK: - Direct API errors (from STPAPIClient network responses)

    func testError_CardError_ShowsMessage() {
        // Simulates a real card_error from the Stripe API (e.g. card declined).
        // stp_error sets localizedDescription = stripeErrorMessage for card_error types.
        let error = NSError.stp_error(
            errorType: "card_error",
            stripeErrorCode: "card_declined",
            stripeErrorMessage: "Your card was declined.",
            errorParam: nil,
            declineCode: nil,
            intent: nil,
            httpResponse: nil
        )

        XCTAssertEqual("Your card was declined.", error.nonGenericDescription)
    }

    func testError_InvalidRequestError_LiveMode_ShowsGenericMessageWithRequestId() {
        // Non-card errors in live mode should show a generic message with the request ID.
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: ["request-id": "req_livetest123"]
        )
        let intent: [String: Any] = ["object": "payment_intent", "livemode": true]
        let error = NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: nil,
            stripeErrorMessage: "This Connect account cannot currently make live charges.",
            errorParam: nil,
            declineCode: nil,
            intent: intent,
            httpResponse: httpResponse
        )

        XCTAssertEqual("Something went wrong. Request ID: req_livetest123", error.nonGenericDescription)
    }

    func testError_InvalidRequestError_LiveMode_NoRequestId_ShowsGenericFallback() {
        // Non-card errors in live mode without a request ID fall back to the generic error string.
        let intent: [String: Any] = ["object": "payment_intent", "livemode": true]
        let error = NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: nil,
            stripeErrorMessage: "This Connect account cannot currently make live charges.",
            errorParam: nil,
            declineCode: nil,
            intent: intent,
            httpResponse: nil
        )

        XCTAssertEqual(NSError.stp_unexpectedErrorMessage(), error.nonGenericDescription)
    }

    func testError_InvalidRequestError_TestMode_ShowsRawMessage() {
        // Non-card errors in test mode preserve the raw server message so developers can diagnose issues.
        let intent: [String: Any] = ["object": "payment_intent", "livemode": false]
        let error = NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: nil,
            stripeErrorMessage: "This Connect account cannot currently make live charges.",
            errorParam: nil,
            declineCode: nil,
            intent: intent,
            httpResponse: nil
        )

        XCTAssertEqual("This Connect account cannot currently make live charges.", error.nonGenericDescription)
    }

    func testError_NoErrorType_ShowsMessage() {
        // SDK-internal errors (e.g. connection failures) don't go through stp_error() and have no
        // stripeErrorTypeKey in userInfo. When the key is absent, errorMessageKey is assumed user-facing.
        let error = NSError(
            domain: STPError.stripeDomain,
            code: STPErrorCode.connectionError.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
                STPError.errorMessageKey: "There was an error connecting to Stripe.",
            ]
        )

        XCTAssertEqual("There was an error connecting to Stripe.", error.nonGenericDescription)
    }

    // MARK: - PaymentHandler wrapped errors (from STPPaymentHandler confirmation flow)

    func testError_CardError_LiveMode_StillShowsCardMessage() {
        // card_error messages should always be shown regardless of live/test mode.
        let intent: [String: Any] = ["object": "payment_intent", "livemode": true]
        let error = NSError.stp_error(
            errorType: "card_error",
            stripeErrorCode: "card_declined",
            stripeErrorMessage: "Your card was declined.",
            errorParam: nil,
            declineCode: nil,
            intent: intent,
            httpResponse: nil
        )

        XCTAssertEqual("Your card was declined.", error.nonGenericDescription)
    }

    func testError_PaymentHandlerWrapped_CardError_ShowsMessage() {
        // Simulates STPPaymentHandler wrapping a card_error API response as NSUnderlyingError
        // (e.g. after payment confirmation fails with "insufficient funds").
        let underlyingError = NSError.stp_error(
            errorType: "card_error",
            stripeErrorCode: "insufficient_funds",
            stripeErrorMessage: "Your card has insufficient funds.",
            errorParam: nil,
            declineCode: nil,
            intent: nil,
            httpResponse: nil
        )
        let error = NSError(
            domain: "STPPaymentHandlerErrorDomain",
            code: 2,
            userInfo: [NSUnderlyingErrorKey: underlyingError]
        )

        XCTAssertEqual("Your card has insufficient funds.", error.nonGenericDescription)
    }

    func testError_PaymentHandlerWrapped_NonCardError_LiveMode_ShowsGenericMessage() {
        // Simulates STPPaymentHandler wrapping an invalid_request_error as NSUnderlyingError
        // (e.g. disabled Connect account error during confirmation) in live mode.
        let intent: [String: Any] = ["object": "payment_intent", "livemode": true]
        let underlyingError = NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: nil,
            stripeErrorMessage: "This Connect account cannot currently make live charges.",
            errorParam: nil,
            declineCode: nil,
            intent: intent,
            httpResponse: nil
        )
        let error = NSError(
            domain: "STPPaymentHandlerErrorDomain",
            code: 2,
            userInfo: [NSUnderlyingErrorKey: underlyingError]
        )

        XCTAssertEqual(NSError.stp_unexpectedErrorMessage(), error.nonGenericDescription)
    }

    func testError_PaymentHandlerWrapped_NonCardError_TestMode_ShowsRawMessage() {
        // Simulates STPPaymentHandler wrapping an invalid_request_error as NSUnderlyingError
        // in test mode; the raw server message is preserved for developer debugging.
        let intent: [String: Any] = ["object": "payment_intent", "livemode": false]
        let underlyingError = NSError.stp_error(
            errorType: "invalid_request_error",
            stripeErrorCode: nil,
            stripeErrorMessage: "This Connect account cannot currently make live charges.",
            errorParam: nil,
            declineCode: nil,
            intent: intent,
            httpResponse: nil
        )
        let error = NSError(
            domain: "STPPaymentHandlerErrorDomain",
            code: 2,
            userInfo: [NSUnderlyingErrorKey: underlyingError]
        )

        XCTAssertEqual("This Connect account cannot currently make live charges.", error.nonGenericDescription)
    }

    // MARK: - Non-generic localizedDescription

    func testError_HasLocalizedDescription() {
        let errorMessage = "Test errorMessage"
        let error = TestableError.custom(errorMessage)

        XCTAssertEqual(errorMessage, error.nonGenericDescription)
    }
}

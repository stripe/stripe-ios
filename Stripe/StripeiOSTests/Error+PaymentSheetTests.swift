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

    func testError_HasGenericLocalizedDescription_WithServerError_CardError() {
        let serverErrorMessage = "Your card was declined."
        let info: [String: Any] = [
            NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: serverErrorMessage,
            STPError.stripeErrorTypeKey: "card_error",
        ]
        let error = NSError(domain: "Test error domain", code: 123, userInfo: info)

        XCTAssertEqual(serverErrorMessage, error.nonGenericDescription)
    }

    func testError_HasGenericLocalizedDescription_WithServerError_NonCardError() {
        let serverErrorMessage = "This Connect account cannot currently make live charges."
        let info: [String: Any] = [
            NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: serverErrorMessage,
            STPError.stripeErrorTypeKey: "invalid_request_error",
        ]
        let error = NSError(domain: "Test error domain", code: 123, userInfo: info)

        // Non-card errors should NOT expose raw API messages to users
        XCTAssertEqual(NSError.stp_unexpectedErrorMessage(), error.nonGenericDescription)
    }

    func testError_HasGenericLocalizedDescription_WithServerError_NoErrorType() {
        let serverErrorMessage = "There was an error connecting to Stripe."
        let info: [String: Any] = [
            NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(),
            STPError.errorMessageKey: serverErrorMessage,
        ]
        let error = NSError(domain: "Test error domain", code: 123, userInfo: info)

        // When no stripeErrorTypeKey is present (e.g. SDK-internal connection errors),
        // the errorMessageKey is assumed to be intentionally user-facing
        XCTAssertEqual(serverErrorMessage, error.nonGenericDescription)
    }

    func testError_PaymentHandlerDomain_CardError() {
        let serverErrorMessage = "Your card has insufficient funds."
        let underlyingInfo: [String: Any] = [
            STPError.errorMessageKey: serverErrorMessage,
            STPError.stripeErrorTypeKey: "card_error",
        ]
        let underlyingError = NSError(domain: "STPAPIError", code: 0, userInfo: underlyingInfo)
        let info: [String: Any] = ["NSUnderlyingError": underlyingError]
        let error = NSError(domain: "STPPaymentHandlerErrorDomain", code: 2, userInfo: info)

        XCTAssertEqual(serverErrorMessage, error.nonGenericDescription)
    }

    func testError_PaymentHandlerDomain_NonCardError() {
        let serverErrorMessage = "This Connect account cannot currently make live charges."
        let underlyingInfo: [String: Any] = [
            STPError.errorMessageKey: serverErrorMessage,
            STPError.stripeErrorTypeKey: "invalid_request_error",
        ]
        let underlyingError = NSError(domain: "STPAPIError", code: 0, userInfo: underlyingInfo)
        let info: [String: Any] = ["NSUnderlyingError": underlyingError]
        let error = NSError(domain: "STPPaymentHandlerErrorDomain", code: 2, userInfo: info)

        // Non-card errors should NOT expose raw API messages to users
        XCTAssertEqual(NSError.stp_unexpectedErrorMessage(), error.nonGenericDescription)
    }

    func testError_HasLocalizedDescription() {
        let errorMessage = "Test errorMessage"
        let error = TestableError.custom(errorMessage)

        XCTAssertEqual(errorMessage, error.nonGenericDescription)
    }
}

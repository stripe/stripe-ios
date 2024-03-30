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

    func testError_HasGenericLocalizedDescription_WithServerError() {
        let serverErrorMessage = "Test failed server response error messasge"
        let info = [NSLocalizedDescriptionKey: NSError.stp_unexpectedErrorMessage(), STPError.errorMessageKey: serverErrorMessage]
        let error = NSError(domain: "Test error domain", code: 123, userInfo: info)

        XCTAssertEqual(serverErrorMessage, error.nonGenericDescription)
    }

    func testError_HasLocalizedDescription() {
        let errorMessage = "Test errorMessage"
        let error = TestableError.custom(errorMessage)

        XCTAssertEqual(errorMessage, error.nonGenericDescription)
    }
}

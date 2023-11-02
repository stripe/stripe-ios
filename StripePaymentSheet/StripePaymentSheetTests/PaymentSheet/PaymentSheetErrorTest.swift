//
//  PaymentSheetErrorTest.swift
//  StripePaymentSheetTests
//
//  Created by Chris Mays on 11/2/23.
//

@testable@_spi(STP) import StripeCore
@testable import StripePaymentSheet
import XCTest

final class PaymentSheetErrorTest: XCTestCase {
    func testLocalizedDescription() throws {
        // Upcasting to Error to ensure localizedDescription is implemented properly.
        // Context: https://github.com/stripe/stripe-ios/pull/3038
        XCTAssertEqual((PaymentSheetError.accountLinkFailure as Error).localizedDescription, NSError.stp_unexpectedErrorMessage())
    }
}

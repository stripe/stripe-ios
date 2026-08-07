//
//  PaymentPagesAPIResponse+LineItemTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

class STPCheckoutSessionLineItemTest: XCTestCase {

    func testDecodedObjectWithNoLineItems() {
        let session = CheckoutTestHelpers.makeSession()

        XCTAssertEqual(session.lineItems.count, 0)
    }
}

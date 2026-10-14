//
//  CheckoutErrorSPITests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(ReactNativeSDK) import StripePaymentSheet
import XCTest

final class CheckoutErrorSPITests: XCTestCase {
    func testCheckoutErrorCanBeClassifiedOutsideStripePaymentSheet() {
        let error: Error = CheckoutError.invalidClientSecret
        guard let checkoutError = error as? CheckoutError else {
            XCTFail("Expected a CheckoutError")
            return
        }
        if case .invalidClientSecret = checkoutError {} else {
            XCTFail("Expected invalidClientSecret")
        }
    }
}

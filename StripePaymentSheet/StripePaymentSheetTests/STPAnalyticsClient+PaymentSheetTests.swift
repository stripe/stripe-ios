//
//  STPAnalyticsClient+PaymentSheetTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePaymentSheet
import XCTest

class STPAnalyticsClientPaymentSheetTest: XCTestCase {
    func testPaymentSheetSDKVariantPayload() throws {
        // setup
        let analytic = PaymentSheetAnalytic(
            event: .paymentMethodCreation,
            productUsage: [],
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("paymentsheet", payload["pay_var"] as? String)
    }

    enum MyError: Error, CustomDebugStringConvertible {
        var debugDescription: String {
            return "Some debug description that accidentally contains PII"
        }
        
        case foo
    }
    
    func testMakeSafeLoggingString() {
        let testCases: [(Error, String)] = [
            // List of inputs and expected outputs
            (NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut),
             "NSURLErrorDomain, -1001"),
            (PaymentSheetError.errorHandlingNextAction,
             "errorHandlingNextAction"),
            (NSError(domain: STPError.stripeDomain, code: STPErrorCode.cardError.rawValue),
             "cardError"),
            (NSError(domain: STPError.stripeDomain, code: STPErrorCode.invalidRequestError.rawValue),
             "invalidRequestError"),
            (NSError(domain: STPError.stripeDomain, code: STPErrorCode.invalidRequestError.rawValue, userInfo: [STPError.errorMessageKey: "rate_limit_exceeded"]),
             "rate_limit_exceeded"),
            (MyError.foo,
             "StripePaymentSheetTests.STPAnalyticsClientPaymentSheetTest.MyError"),

        ]
        for testCase in testCases {
            XCTAssertEqual(STPAnalyticsClient().makeSafeLoggingString(from: testCase.0), testCase.1)
        }
    }
}

//
//  PaymentAnalyticTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(STP) import StripeCore
@testable import Stripe

final class PaymentAnalyticTest: XCTestCase {

    func testParams() {
        let analytic = GenericPaymentAnalytic(
            event: .cardScanCancelled,
            paymentConfiguration: STPPaymentConfiguration(),
            productUsage: [
                STPPaymentContext.stp_analyticsIdentifier,
            ],
            additionalParams: [:]
        )

        XCTAssertEqual(analytic.params["ui_usage_level"] as? String, "full")
        XCTAssertNotNil(analytic.params["apple_pay_enabled"] as? NSNumber)
        XCTAssertNotNil(analytic.params["ocr_type"] as? String)
    }
}

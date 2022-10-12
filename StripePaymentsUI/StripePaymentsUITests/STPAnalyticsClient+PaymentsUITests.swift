//
//  STPAnalyticsClient+PaymentsUITests.swift
//  StripePaymentsUITests
//

import Foundation
import XCTest
@_spi(STP) @testable import StripePaymentsUI
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripeCore

class STPAnalyticsClientPaymentsUITest: XCTestCase {
    func testPaymentsUISDKVariantPayload() throws {
        // setup
        let analytic = GenericPaymentAnalytic(
            event: .paymentMethodCreation,
            paymentConfiguration: nil,
            productUsage: [],
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("payments-ui", payload["pay_var"] as? String)
    }
}

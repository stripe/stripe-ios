//
//  IntentConfirmParamsTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 10/11/23.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

final class IntentConfirmParamsTest: XCTestCase {

    func testMakeDashboardParams() {
        let params = IntentConfirmParams.makeDashboardParams(paymentIntentClientSecret: "test_client_secret",
                                                             paymentMethodID: "test_payment_method_id",
                                                             shouldSave: true,
                                                             paymentMethodType: .card,
                                                             customer: .init(id: "test_id",
                                                                             ephemeralKeySecret: "test_key"))

        XCTAssertEqual(params.clientSecret, "test_client_secret")
        XCTAssertEqual(params.paymentMethodId, "test_payment_method_id")
        XCTAssertEqual(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["setup_future_usage"] as? String, "off_session")
        XCTAssertTrue(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["moto"] as? Bool ?? false)
    }

}

//
//  STPIntentWithPreferencesTest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) @_spi(ExternalPaymentMethodsPrivateBeta) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPAPIClient_PaymentSheetTest: XCTestCase {
    func testElementsSessionParameters_DeferredPayment() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 2000,
                                                                           currency: "USD",
                                                                           setupFutureUsage: .onSession,
                                                                           captureMethod: .automaticAsync),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            confirmHandler: { _, _, _ in })
        var config = PaymentSheet.Configuration()
        config.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_foo", "external_bar"], externalPaymentMethodConfirmHandler: { _, _, _ in })

        let payload = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(mode: .deferredIntent(intentConfig), configuration: config)
        XCTAssertEqual(payload["key"] as? String, "pk_test")
        XCTAssertEqual(payload["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(payload["external_payment_methods"] as? [String], ["external_foo", "external_bar"])

        let deferredIntent = try XCTUnwrap(payload["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card", "cashapp"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
        XCTAssertEqual(deferredIntent["mode"] as? String, "payment")
        XCTAssertEqual(deferredIntent["amount"] as? Int, 2000)
        XCTAssertEqual(deferredIntent["currency"] as? String, "USD")
        XCTAssertEqual(deferredIntent["setup_future_usage"] as? String, "on_session")
        XCTAssertEqual(deferredIntent["capture_method"] as? String, "automatic_async")
    }

    func testElementsSessionParameters_DeferredSetup() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD",
                                                                           setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            confirmHandler: { _, _, _ in })

        let payload = STPAPIClient(publishableKey: "pk_test").makeElementsSessionsParams(mode: .deferredIntent(intentConfig), configuration: .init())
        XCTAssertEqual(payload["key"] as? String, "pk_test")
        XCTAssertEqual(payload["locale"] as? String, Locale.current.toLanguageTag())
        XCTAssertEqual(payload["external_payment_methods"] as? [String], [])

        let deferredIntent = try XCTUnwrap(payload["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card", "cashapp"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
        XCTAssertEqual(deferredIntent["mode"] as? String, "setup")
        XCTAssertEqual(deferredIntent["currency"] as? String, "USD")
        XCTAssertEqual(deferredIntent["setup_future_usage"] as? String, "off_session")
    }
}

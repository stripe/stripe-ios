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
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPIntentWithPreferencesTest: XCTestCase {
    private let paymentIntentClientSecret =
        "pi_1H5J4RFY0qyl6XeWFTpgue7g_secret_1SS59M0x65qWMaX2wEB03iwVE"
    private let setupIntentClientSecret =
        "seti_1GGCuIFY0qyl6XeWVfbQK6b3_secret_GnoX2tzX2JpvxsrcykRSVna2lrYLKew"

    func testPaymentIntentWithPreferences() async {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        do {
            let paymentIntentWithPreferences = try await client.retrievePaymentIntentWithPreferences(withClientSecret: paymentIntentClientSecret)
            // Check for required PI fields
            XCTAssertEqual(paymentIntentWithPreferences.stripeId, "pi_1H5J4RFY0qyl6XeWFTpgue7g")
            XCTAssertEqual(
                paymentIntentWithPreferences.clientSecret,
                self.paymentIntentClientSecret
            )
            XCTAssertEqual(paymentIntentWithPreferences.amount, 2000)
            XCTAssertEqual(paymentIntentWithPreferences.currency, "usd")
            XCTAssertEqual(
                paymentIntentWithPreferences.status,
                STPPaymentIntentStatus.succeeded
            )
            XCTAssertEqual(paymentIntentWithPreferences.livemode, false)
            XCTAssertEqual(
                paymentIntentWithPreferences.paymentMethodTypes,
                STPPaymentMethod.types(from: ["card"])
            )
            // Check for ordered payment method types
            XCTAssertNotNil(paymentIntentWithPreferences.orderedPaymentMethodTypes)
            XCTAssertEqual(
                paymentIntentWithPreferences.orderedPaymentMethodTypes,
                [STPPaymentMethodType.card]
            )
        } catch {
            XCTFail()
            print(error)
        }
    }

    func testSetupIntentWithPreferences() async {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        do {
            let setupIntentWithPreferences = try await client.retrieveSetupIntentWithPreferences(withClientSecret: setupIntentClientSecret)
            // Check required SI fields
            XCTAssertEqual(setupIntentWithPreferences.stripeID, "seti_1GGCuIFY0qyl6XeWVfbQK6b3")
            XCTAssertEqual(
                setupIntentWithPreferences.clientSecret,
                self.setupIntentClientSecret
            )
            XCTAssertEqual(setupIntentWithPreferences.status, .requiresPaymentMethod)
            XCTAssertEqual(
                setupIntentWithPreferences.paymentMethodTypes,
                STPPaymentMethod.types(from: ["card"])
            )
            // Check for ordered payment method types
            XCTAssertNotNil(setupIntentWithPreferences.orderedPaymentMethodTypes)
            XCTAssertEqual(
                setupIntentWithPreferences.orderedPaymentMethodTypes,
                [STPPaymentMethodType.card]
            )
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testRetrieveElementSession_deferredPayment() async {
        let expectation = XCTestExpectation(description: "Retrieve ElementsSession")
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 2000,
                                                                           currency: "USD",
                                                                           setupFutureUsage: .onSession),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            confirmHandler: { _, _, _ in })

        do {
            let elementsSession = try await client.retrieveElementsSession(withIntentConfig: intentConfig)
            XCTAssertNotNil(elementsSession)
            XCTAssertEqual(elementsSession.countryCode, "US")
            XCTAssertNotNil(elementsSession.linkSettings)
            XCTAssertNotNil(elementsSession.paymentMethodSpecs)
            XCTAssertEqual(
                elementsSession.orderedPaymentMethodTypes,
                [STPPaymentMethodType.card, STPPaymentMethodType.cashApp]
            )
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testRetrieveElementSession_deferredSetup() async {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD",
                                                                           setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            confirmHandler: { _, _, _ in })

        do {
            let elementsSession = try await client.retrieveElementsSession(withIntentConfig: intentConfig)
            XCTAssertNotNil(elementsSession)
            XCTAssertEqual(elementsSession.countryCode, "US")
            XCTAssertNotNil(elementsSession.linkSettings)
            XCTAssertNotNil(elementsSession.paymentMethodSpecs)
            XCTAssertEqual(
                elementsSession.orderedPaymentMethodTypes,
                [STPPaymentMethodType.card, STPPaymentMethodType.cashApp]
            )
        } catch {
            print(error)
            XCTFail()
        }
    }

    // MARK: PaymentSheet.IntentConfiguration+elementsSessionPayload tests

    func testElementsSessionPayload_Payment() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 2000,
                                                                           currency: "USD",
                                                                           setupFutureUsage: .onSession,
                                                                           captureMethod: .automaticAsync),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            confirmHandler: { _, _, _ in })

        let payload = intentConfig.elementsSessionParameters(publishableKey: "pk_test")
        XCTAssertEqual(payload["key"] as? String, "pk_test")
        XCTAssertEqual(payload["locale"] as? String, Locale.current.toLanguageTag())

        let deferredIntent = try XCTUnwrap(payload["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card", "cashapp"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
        XCTAssertEqual(deferredIntent["mode"] as? String, "payment")
        XCTAssertEqual(deferredIntent["amount"] as? Int, 2000)
        XCTAssertEqual(deferredIntent["currency"] as? String, "USD")
        XCTAssertEqual(deferredIntent["setup_future_usage"] as? String, "on_session")
        XCTAssertEqual(deferredIntent["capture_method"] as? String, "automatic_async")
    }

    func testElementsSessionPayload_Setup() throws {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD",
                                                                           setupFutureUsage: .offSession),
                                                            paymentMethodTypes: ["card", "cashapp"],
                                                            onBehalfOf: "acct_connect",
                                                            confirmHandler: { _, _, _ in })

        let payload = intentConfig.elementsSessionParameters(publishableKey: "pk_test")
        XCTAssertEqual(payload["key"] as? String, "pk_test")
        XCTAssertEqual(payload["locale"] as? String, Locale.current.toLanguageTag())

        let deferredIntent = try XCTUnwrap(payload["deferred_intent"] as?  [String: Any])
        XCTAssertEqual(deferredIntent["payment_method_types"] as? [String], ["card", "cashapp"])
        XCTAssertEqual(deferredIntent["on_behalf_of"] as? String, "acct_connect")
        XCTAssertEqual(deferredIntent["mode"] as? String, "setup")
        XCTAssertEqual(deferredIntent["currency"] as? String, "USD")
        XCTAssertEqual(deferredIntent["setup_future_usage"] as? String, "off_session")
    }
}

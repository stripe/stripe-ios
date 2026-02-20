//
//  STPCheckoutSessionTest.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments

class STPCheckoutSessionTest: XCTestCase {

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let fullJson = STPTestUtils.jsonNamed("CheckoutSession")

        XCTAssertNotNil(
            STPCheckoutSession.decodedObject(fromAPIResponse: fullJson),
            "can decode with full json"
        )

        // Required fields per API spec (non-nullable)
        let requiredFields = [
            "session_id",
            "livemode",
            "mode",
            "payment_status",
            "payment_method_types",
        ]

        for field in requiredFields {
            var partialJson = fullJson
            XCTAssertNotNil(partialJson?[field])
            partialJson?.removeValue(forKey: field)
            XCTAssertNil(
                STPCheckoutSession.decodedObject(fromAPIResponse: partialJson),
                "should fail to decode without \(field)"
            )
        }
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.stripeId, "cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(session.clientSecret, "cs_test_a1b2c3d4e5f6g7h8i9j0_secret_xyz123abc456")
        XCTAssertEqual(session.totalSummary?.total, 2000)
        XCTAssertEqual(session.totalSummary?.subtotal, 2000)
        XCTAssertEqual(session.totalSummary?.due, 2000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertEqual(session.mode, .payment)
        XCTAssertEqual(session.status, .open)  // status is nullable but present in JSON
        XCTAssertEqual(session.paymentStatus, .unpaid)
        XCTAssertEqual(session.paymentIntentId, "pi_test123456789")
        XCTAssertNil(session.setupIntentId)
        XCTAssertFalse(session.livemode)
        XCTAssertEqual(session.customerId, "cus_test123456")
        XCTAssertNotNil(session.customer)
        XCTAssertEqual(session.customer?.id, "cus_test123456")
        XCTAssertEqual(session.customer?.email, "customer@example.com")
        XCTAssertEqual(session.customer?.name, "Test Customer")
        XCTAssertEqual(session.customer?.phone, "+15555555555")
        XCTAssertEqual(session.customer?.paymentMethods.count, 2)
        XCTAssertEqual(session.customer?.paymentMethods[0].stripeId, "pm_1Sxae3Lu5o3P18Zpt5YuRRoG")
        XCTAssertEqual(session.customer?.paymentMethods[0].type, .card)
        XCTAssertEqual(session.customer?.paymentMethods[0].card?.last4, "4242")
        XCTAssertEqual(session.customer?.paymentMethods[1].stripeId, "pm_1Sxae4Lu5o3P18ZplFiKexnM")
        XCTAssertEqual(session.customer?.paymentMethods[1].type, .USBankAccount)
        XCTAssertEqual(session.customerEmail, "test@example.com")
        XCTAssertEqual(session.url?.absoluteString, "https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(session.returnUrl, "https://example.com/return")
        XCTAssertEqual(session.cancelUrl, "https://example.com/cancel")

        // Verify saved payment methods offer save
        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .notAccepted)

        XCTAssertEqual(
            session.paymentMethodTypes,
            [STPPaymentMethodType.card, STPPaymentMethodType.USBankAccount]
        )

        XCTAssertNotNil(session.paymentMethodOptions)

        XCTAssertEqual(
            session.allResponseFields as NSDictionary,
            json as NSDictionary
        )
    }

    func testDecodedObjectWithMinimalRequiredFields() {
        // All required fields per API spec, but no optional fields
        let minimalJson: [String: Any] = [
            "session_id": "cs_test_minimal",
            "object": "checkout.session",
            "livemode": true,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            // status is nullable, so we omit it to test that behavior
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: minimalJson)

        XCTAssertNotNil(session, "Should decode with all required fields")
        XCTAssertEqual(session?.stripeId, "cs_test_minimal")
        XCTAssertNil(session?.status)  // status is nullable, should be nil when missing
        XCTAssertEqual(session?.mode, .payment)
        XCTAssertEqual(session?.paymentStatus, .unpaid)
        XCTAssertTrue(session?.livemode ?? false)
        XCTAssertEqual(session?.paymentMethodTypes, [.card])

        // Optional fields should be nil
        XCTAssertNil(session?.totalSummary)
        XCTAssertNil(session?.currency)
        XCTAssertNil(session?.clientSecret)
        XCTAssertNil(session?.paymentIntentId)
        XCTAssertNil(session?.setupIntentId)
        XCTAssertNil(session?.customer)
        XCTAssertNil(session?.customerId)
        XCTAssertNil(session?.customerEmail)
        XCTAssertNil(session?.url)
        XCTAssertNil(session?.returnUrl)
        XCTAssertNil(session?.savedPaymentMethodsOfferSave)
    }

    func testDecodedObjectWithSetupMode() {
        let setupModeJson: [String: Any] = [
            "session_id": "cs_test_setup",
            "object": "checkout.session",
            "livemode": false,
            "status": "open",
            "mode": "setup",
            "payment_status": "no_payment_required",
            "payment_method_types": ["card"],
            "setup_intent": "seti_test123456",
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: setupModeJson)

        XCTAssertNotNil(session)
        XCTAssertEqual(session?.mode, .setup)
        XCTAssertEqual(session?.status, .open)
        XCTAssertEqual(session?.paymentStatus, .noPaymentRequired)
        XCTAssertEqual(session?.setupIntentId, "seti_test123456")
        XCTAssertNil(session?.paymentIntentId)
    }

    // MARK: - Enum Tests

    func testStatusEnumParsing() {
        XCTAssertEqual(STPCheckoutSessionStatus.status(from: "open"), .open)
        XCTAssertEqual(STPCheckoutSessionStatus.status(from: "complete"), .complete)
        XCTAssertEqual(STPCheckoutSessionStatus.status(from: "expired"), .expired)
        XCTAssertEqual(STPCheckoutSessionStatus.status(from: "OPEN"), .open)
        XCTAssertEqual(STPCheckoutSessionStatus.status(from: "unknown_value"), .unknown)
    }

    func testModeEnumParsing() {
        XCTAssertEqual(STPCheckoutSessionMode.mode(from: "payment"), .payment)
        XCTAssertEqual(STPCheckoutSessionMode.mode(from: "setup"), .setup)
        XCTAssertEqual(STPCheckoutSessionMode.mode(from: "subscription"), .subscription)
        XCTAssertEqual(STPCheckoutSessionMode.mode(from: "PAYMENT"), .payment)
        XCTAssertEqual(STPCheckoutSessionMode.mode(from: "unknown_value"), .unknown)
    }

    func testPaymentStatusEnumParsing() {
        XCTAssertEqual(STPCheckoutSessionPaymentStatus.paymentStatus(from: "paid"), .paid)
        XCTAssertEqual(STPCheckoutSessionPaymentStatus.paymentStatus(from: "unpaid"), .unpaid)
        XCTAssertEqual(STPCheckoutSessionPaymentStatus.paymentStatus(from: "no_payment_required"), .noPaymentRequired)
        XCTAssertEqual(STPCheckoutSessionPaymentStatus.paymentStatus(from: "PAID"), .paid)
        XCTAssertEqual(STPCheckoutSessionPaymentStatus.paymentStatus(from: "unknown_value"), .unknown)
    }

}

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

        // Only id and status are truly required fields
        let requiredFields = ["id", "status"]

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
        XCTAssertEqual(session.amountTotal, 2000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertEqual(session.mode, .payment)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.paymentStatus, .unpaid)
        XCTAssertEqual(session.paymentIntentId, "pi_test123456789")
        XCTAssertNil(session.setupIntentId)
        XCTAssertFalse(session.livemode)
        XCTAssertEqual(session.created, Date(timeIntervalSince1970: 1609459200))
        XCTAssertEqual(session.expiresAt, Date(timeIntervalSince1970: 1609545600))
        XCTAssertEqual(session.customerId, "cus_test123456")
        XCTAssertEqual(session.customerEmail, "test@example.com")
        XCTAssertEqual(session.url?.absoluteString, "https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(session.returnUrl, "https://example.com/return")
        XCTAssertEqual(session.cancelUrl, "https://example.com/cancel")

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

    func testDecodedObjectWithMinimalFields() {
        let minimalJson: [String: Any] = [
            "id": "cs_test_minimal",
            "object": "checkout.session",
            "status": "open",
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: minimalJson)

        XCTAssertNotNil(session, "Should decode with minimal fields")
        XCTAssertEqual(session?.stripeId, "cs_test_minimal")
        XCTAssertEqual(session?.status, .open)
        XCTAssertEqual(session?.amountTotal, 0)
        XCTAssertEqual(session?.currency, "")
        XCTAssertNil(session?.clientSecret)
        XCTAssertNil(session?.paymentIntentId)
        XCTAssertNil(session?.setupIntentId)
        XCTAssertNil(session?.customerId)
        XCTAssertNil(session?.customerEmail)
        XCTAssertNil(session?.url)
        XCTAssertNil(session?.returnUrl)
        XCTAssertEqual(session?.paymentMethodTypes, [])
    }

    func testDecodedObjectWithSetupMode() {
        let setupModeJson: [String: Any] = [
            "id": "cs_test_setup",
            "object": "checkout.session",
            "status": "open",
            "mode": "setup",
            "payment_status": "no_payment_required",
            "setup_intent": "seti_test123456",
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: setupModeJson)

        XCTAssertNotNil(session)
        XCTAssertEqual(session?.mode, .setup)
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

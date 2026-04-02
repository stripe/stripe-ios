//
//  STPCheckoutSessionTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

class STPCheckoutSessionTest: XCTestCase {
    private func makeCheckoutSession(_ overrides: [String: Any]) -> STPCheckoutSession {
        var json: [String: Any] = [
            "session_id": "cs_test",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer": ["id": "cus_123"],
        ]
        overrides.forEach { json[$0.key] = $0.value }
        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }

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
        XCTAssertEqual(session.totals?.total, 2686)
        XCTAssertEqual(session.totals?.subtotal, 2000)
        XCTAssertEqual(session.totals?.due, 2686)
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
        XCTAssertNil(session.setupFutureUsage)

        XCTAssertEqual(
            session.paymentMethodTypes,
            [STPPaymentMethodType.card, STPPaymentMethodType.USBankAccount]
        )

        XCTAssertNotNil(session.paymentMethodOptions)

        // Line items
        XCTAssertEqual(session.lineItems.count, 2)
        XCTAssertEqual(session.lineItems[0].id, "li_1abc")
        XCTAssertEqual(session.lineItems[0].name, "Widget")
        XCTAssertEqual(session.lineItems[0].quantity, 2)
        XCTAssertEqual(session.lineItems[0].unitAmount, 750)
        XCTAssertEqual(session.lineItems[0].currency, "usd")
        XCTAssertEqual(session.lineItems[1].id, "li_2def")
        XCTAssertEqual(session.lineItems[1].name, "Gadget")
        XCTAssertEqual(session.lineItems[1].quantity, 1)
        XCTAssertEqual(session.lineItems[1].unitAmount, 500)
        XCTAssertEqual(session.lineItems[1].currency, "usd")

        // Shipping options
        XCTAssertEqual(session.shippingOptions.count, 2)
        XCTAssertEqual(session.shippingOptions[0].id, "shr_standard")
        XCTAssertEqual(session.shippingOptions[0].displayName, "Standard Shipping")
        XCTAssertEqual(session.shippingOptions[0].amount, 500)
        XCTAssertEqual(session.shippingOptions[0].currency, "usd")
        XCTAssertEqual(session.shippingOptions[1].id, "shr_express")
        XCTAssertEqual(session.shippingOptions[1].displayName, "Express Shipping")
        XCTAssertEqual(session.shippingOptions[1].amount, 1500)
        XCTAssertEqual(session.shippingOptions[1].currency, "usd")

        // Totals — discount and tax
        XCTAssertEqual(session.totals?.discount, 0)
        XCTAssertEqual(session.totals?.tax, 186)

        // Tax amounts
        XCTAssertEqual(session.taxAmounts.count, 1)
        XCTAssertEqual(session.taxAmounts[0].amount, 186)
        XCTAssertFalse(session.taxAmounts[0].inclusive)
        XCTAssertEqual(session.taxAmounts[0].taxableAmount, 2500)
        XCTAssertEqual(session.taxAmounts[0].taxRate?.percentage, 7.45)
        XCTAssertEqual(session.taxAmounts[0].taxRate?.displayName, "Sales Tax")

        // Automatic tax
        XCTAssertTrue(session.automaticTaxEnabled)
        XCTAssertEqual(session.automaticTaxAddressSource, "billing")

        // Shipping address collection
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA"])
        XCTAssertTrue(session.requiresShippingAddress)

        // Selected shipping option
        XCTAssertEqual(session.selectedShippingOptionId, "shr_standard")
        XCTAssertEqual(session.totals?.shipping, 500)

        // Adaptive pricing
        XCTAssertTrue(session.adaptivePricingActive)
        XCTAssertEqual(session.localizedPricesMetas.count, 2)
        XCTAssertEqual(session.localizedPricesMetas[0].currency, "eur")
        XCTAssertEqual(session.localizedPricesMetas[0].total, 10839)
        XCTAssertEqual(session.localizedPricesMetas[1].currency, "usd")
        XCTAssertEqual(session.localizedPricesMetas[1].total, 12000)
        XCTAssertNotNil(session.exchangeRateMeta)
        XCTAssertEqual(session.exchangeRateMeta?.buyCurrency, "eur")
        XCTAssertEqual(session.exchangeRateMeta?.sellCurrency, "usd")
        XCTAssertEqual(session.exchangeRateMeta?.exchangeRate, "0.90325")

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
        XCTAssertNil(session?.totals)
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
        XCTAssertNil(session?.setupFutureUsage)
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

    func testDecodedObjectParsesTopLevelSetupFutureUsage() {
        let session = makeCheckoutSession([
            "setup_future_usage": "off_session",
        ])

        XCTAssertEqual(session.setupFutureUsage, "off_session")
    }

    func testTotalsWithTaxFromTaxAmounts() {
        let json: [String: Any] = [
            "session_id": "cs_test_tax",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "total_summary": ["due": 2186, "subtotal": 2000, "total": 2186],
            "line_item_group": [
                "tax_amounts": [
                    ["amount": 186, "inclusive": false, "taxable_amount": 2000,
                     "tax_rate": ["percentage": 7.45, "display_name": "Sales Tax"], ],
                ],
            ],
        ]
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.totals?.tax, 186)
        XCTAssertEqual(session?.totals?.subtotal, 2000)
        XCTAssertEqual(session?.totals?.total, 2186)
        XCTAssertEqual(session?.totals?.due, 2186)
        XCTAssertEqual(session?.totals?.discount, 0)
        XCTAssertEqual(session?.totals?.shipping, 0)
        XCTAssertEqual(session?.taxAmounts.count, 1)
        XCTAssertEqual(session?.taxAmounts[0].amount, 186)
        XCTAssertFalse(session?.taxAmounts[0].inclusive ?? true)
        XCTAssertEqual(session?.taxAmounts[0].taxRate?.displayName, "Sales Tax")
    }

    // MARK: - Enum Tests

    func testStatusEnumParsing() {
        XCTAssertEqual(Checkout.Status.status(from: "open"), .open)
        XCTAssertEqual(Checkout.Status.status(from: "complete"), .complete)
        XCTAssertEqual(Checkout.Status.status(from: "expired"), .expired)
        XCTAssertEqual(Checkout.Status.status(from: "OPEN"), .open)
        XCTAssertEqual(Checkout.Status.status(from: "unknown_value"), .unknown)
    }

    func testModeEnumParsing() {
        XCTAssertEqual(Checkout.Mode.mode(from: "payment"), .payment)
        XCTAssertEqual(Checkout.Mode.mode(from: "setup"), .setup)
        XCTAssertEqual(Checkout.Mode.mode(from: "subscription"), .subscription)
        XCTAssertEqual(Checkout.Mode.mode(from: "PAYMENT"), .payment)
        XCTAssertEqual(Checkout.Mode.mode(from: "unknown_value"), .unknown)
    }

    func testPaymentStatusEnumParsing() {
        XCTAssertEqual(Checkout.PaymentStatus.paymentStatus(from: "paid"), .paid)
        XCTAssertEqual(Checkout.PaymentStatus.paymentStatus(from: "unpaid"), .unpaid)
        XCTAssertEqual(Checkout.PaymentStatus.paymentStatus(from: "no_payment_required"), .noPaymentRequired)
        XCTAssertEqual(Checkout.PaymentStatus.paymentStatus(from: "PAID"), .paid)
        XCTAssertEqual(Checkout.PaymentStatus.paymentStatus(from: "unknown_value"), .unknown)
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithoutSetupFutureUsage() {
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: [
            "session_id": "cs_test_payment",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer": ["id": "cus_123"],
        ])!

        XCTAssertFalse(session.merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithTopLevelSetupFutureUsage() {
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: [
            "session_id": "cs_test_payment_sfu",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer": ["id": "cus_123"],
            "setup_future_usage": "off_session",
        ])!

        XCTAssertTrue(session.merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithoutCustomer() {
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: [
            "session_id": "cs_test_payment_no_customer",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "setup_future_usage": "off_session",
        ])!

        XCTAssertFalse(session.merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_setupModeWithCustomer() {
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: [
            "session_id": "cs_test_setup_customer",
            "object": "checkout.session",
            "livemode": false,
            "mode": "setup",
            "payment_status": "no_payment_required",
            "payment_method_types": ["card"],
            "customer": ["id": "cus_123"],
        ])!

        XCTAssertTrue(session.merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_setupModeWithoutCustomer() {
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: [
            "session_id": "cs_test_setup_no_customer",
            "object": "checkout.session",
            "livemode": false,
            "mode": "setup",
            "payment_status": "no_payment_required",
            "payment_method_types": ["card"],
        ])!

        XCTAssertFalse(session.merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_subscriptionModeWithCustomer() {
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: [
            "session_id": "cs_test_subscription",
            "object": "checkout.session",
            "livemode": false,
            "mode": "subscription",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer": ["id": "cus_123"],
        ])!

        XCTAssertTrue(session.merchantWillSavePaymentMethod(.card))
    }

    func testCheckoutSessionIntent_setupFutureUsageString() {
        let session = makeCheckoutSession([
            "setup_future_usage": "off_session",
        ])

        XCTAssertEqual(Intent.checkoutSession(session).setupFutureUsageString, "off_session")
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_topLevel() {
        let session = makeCheckoutSession([
            "setup_future_usage": "off_session",
            "payment_method_types": ["paypal"],
        ])

        XCTAssertTrue(Intent.checkoutSession(session).isSetupFutureUsageSet(for: .payPal))
    }

}

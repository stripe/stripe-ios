//
//  STPCheckoutSessionAPIResponseTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

@MainActor
class STPCheckoutSessionAPIResponseTest: XCTestCase {

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let fullJson = STPTestUtils.jsonNamed("CheckoutSession")

        XCTAssertNotNil(
            STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: fullJson),
            "can decode with full json"
        )

        // Required fields per API spec (non-nullable)
        let requiredFields = [
            "session_id",
            "livemode",
            "mode",
            "payment_status",
            "payment_method_types",
            "elements_session",
        ]

        for field in requiredFields {
            var partialJson = fullJson
            XCTAssertNotNil(partialJson?[field])
            partialJson?.removeValue(forKey: field)
            XCTAssertNil(
                STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: partialJson),
                "should fail to decode without \(field)"
            )
        }
    }

    func testDecodedObjectFromAPIResponseMalformedElementsSession() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        // Invalid elements_session - missing payment_method_preference
        json["elements_session"] = ["garbage": true]
        XCTAssertNil(STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.id, "cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(session.clientSecret, "cs_test_a1b2c3d4e5f6g7h8i9j0_secret_xyz123abc456")
        XCTAssertEqual(session.total?.total.minorUnitsAmount, 2686)
        XCTAssertEqual(session.total?.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertEqual(session.minorUnitsAmountDivisor, 100)
        XCTAssertEqual(session.mode, .payment)
        XCTAssertEqual(session.status?.type, .open)  // status is nullable but present in JSON
        XCTAssertEqual(session.status?.paymentStatus, .unpaid)
        XCTAssertEqual(session.paymentIntentId, "pi_test123456789")
        XCTAssertNil(session.setupIntentId)
        XCTAssertFalse(session.livemode)
        XCTAssertEqual(session.customerId, "cus_test123456")
        XCTAssertNotNil(session.customer)
        XCTAssertEqual(session.customer?.id, "cus_test123456")
        XCTAssertEqual(session.customer?.email, "customer@example.com")
        XCTAssertEqual(session.customer?.name, "Test Customer")
        XCTAssertEqual(session.customer?.phone, "+15555555555")
        XCTAssertFalse(session.customer?.canDetachPaymentMethod ?? true)
        XCTAssertEqual(session.customer?.paymentMethods.count, 2)
        XCTAssertEqual(session.customer?.paymentMethods[0].stripeId, "pm_1Sxae3Lu5o3P18Zpt5YuRRoG")
        XCTAssertEqual(session.customer?.paymentMethods[0].type, .card)
        XCTAssertEqual(session.customer?.paymentMethods[0].card?.last4, "4242")
        XCTAssertEqual(session.customer?.paymentMethods[1].stripeId, "pm_1Sxae4Lu5o3P18ZplFiKexnM")
        XCTAssertEqual(session.customer?.paymentMethods[1].type, .USBankAccount)
        XCTAssertEqual(session.businessName, "CI Stuff")
        XCTAssertEqual(session.elementsSession.sessionID, "elements_session_test123")
        XCTAssertEqual(session.email, "test@example.com")
        XCTAssertEqual(session.url?.absoluteString, "https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(session.returnUrl, "https://example.com/return")
        XCTAssertEqual(session.cancelUrl, "https://example.com/cancel")

        // Saved payment methods
        XCTAssertEqual(session.savedPaymentMethods.count, 2)
        XCTAssertEqual(session.savedPaymentMethods[0].stripeId, "pm_1Sxae3Lu5o3P18Zpt5YuRRoG")
        XCTAssertEqual(session.savedPaymentMethods[0].type, .card)
        XCTAssertEqual(session.savedPaymentMethods[0].card?.last4, "4242")
        XCTAssertEqual(session.savedPaymentMethods[1].stripeId, "pm_1Sxae4Lu5o3P18ZplFiKexnM")
        XCTAssertEqual(session.savedPaymentMethods[1].type, .USBankAccount)

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
        XCTAssertEqual(session.lineItems[0].unitAmount?.minorUnitsAmount, 750)
        XCTAssertEqual(session.lineItems[1].id, "li_2def")
        XCTAssertEqual(session.lineItems[1].name, "Gadget")
        XCTAssertEqual(session.lineItems[1].quantity, 1)
        XCTAssertEqual(session.lineItems[1].unitAmount?.minorUnitsAmount, 500)

        // Shipping options
        XCTAssertEqual(session.shippingOptions.count, 2)
        XCTAssertEqual(session.shippingOptions[0].id, "shr_standard")
        XCTAssertEqual(session.shippingOptions[0].displayName, "Standard Shipping")
        XCTAssertEqual(session.shippingOptions[0].amount.minorUnitsAmount, 500)
        XCTAssertEqual(session.shippingOptions[0].currency, "usd")
        XCTAssertEqual(session.shippingOptions[1].id, "shr_express")
        XCTAssertEqual(session.shippingOptions[1].displayName, "Express Shipping")
        XCTAssertEqual(session.shippingOptions[1].amount.minorUnitsAmount, 1500)
        XCTAssertEqual(session.shippingOptions[1].currency, "usd")

        // Totals — discount and tax
        XCTAssertEqual(session.total?.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.total?.taxExclusive.minorUnitsAmount, 186)

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

        XCTAssertEqual(session.total?.shippingRate.minorUnitsAmount, 500)

        // Selected shipping
        XCTAssertNotNil(session.shipping)
        XCTAssertEqual(session.shipping?.shippingOption.id, "shr_standard")
        XCTAssertEqual(session.shipping?.shippingOption.amount.minorUnitsAmount, 500)
        XCTAssertEqual(session.shipping?.shippingOption.displayName, "Standard Shipping")

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

        // Currency options (derived from adaptive pricing)
        XCTAssertEqual(session.currencyOptions.count, 2)
        XCTAssertEqual(session.currencyOptions[0].currency, "eur")
        XCTAssertEqual(session.currencyOptions[0].amount.minorUnitsAmount, 10839)
        XCTAssertEqual(session.currencyOptions[0].currencyConversion?.fxRate, "0.90325")
        XCTAssertEqual(session.currencyOptions[0].currencyConversion?.sourceCurrency, "usd")
        XCTAssertEqual(session.currencyOptions[1].currency, "usd")
        XCTAssertEqual(session.currencyOptions[1].amount.minorUnitsAmount, 12000)
        XCTAssertNil(session.currencyOptions[1].currencyConversion)

        XCTAssertEqual(
            session.allResponseFields as NSDictionary,
            json as NSDictionary
        )
    }

    func testDecodedObjectWithMinimalRequiredFields() {
        // All required fields per API spec, but no optional fields
        // status is nullable, so we omit it to test that behavior
        let session = CheckoutTestHelpers.makeSession([
            "session_id": "cs_test_minimal",
            "livemode": true,
        ])

        XCTAssertEqual(session.id, "cs_test_minimal")
        XCTAssertNil(session.status)
        XCTAssertEqual(session.mode, .payment)
        XCTAssertTrue(session.livemode)
        XCTAssertEqual(session.paymentMethodTypes, [.card])

        // Optional fields should be nil
        XCTAssertNil(session.total)
        XCTAssertNil(session.currency)
        XCTAssertNil(session.clientSecret)
        XCTAssertNil(session.paymentIntentId)
        XCTAssertNil(session.setupIntentId)
        XCTAssertNil(session.customer)
        XCTAssertNil(session.customerId)
        XCTAssertNil(session.email)
        XCTAssertNil(session.url)
        XCTAssertNil(session.returnUrl)
        XCTAssertNil(session.savedPaymentMethodsOfferSave)
        XCTAssertNil(session.setupFutureUsage)
    }

    func testDecodedObjectWithSetupMode() {
        let session = CheckoutTestHelpers.makeSession([
            "session_id": "cs_test_setup",
            "status": "open",
            "mode": "setup",
            "payment_status": "no_payment_required",
            "setup_intent": "seti_test123456",
        ])

        XCTAssertEqual(session.mode, .setup)
        XCTAssertEqual(session.status?.type, .open)
        XCTAssertEqual(session.status?.paymentStatus, .noPaymentRequired)
        XCTAssertEqual(session.setupIntentId, "seti_test123456")
        XCTAssertNil(session.paymentIntentId)
    }

    func testDecodedObjectParsesTopLevelSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
        ]).withCustomer()

        XCTAssertEqual(session.setupFutureUsage, "off_session")
    }

    func testDecodedObjectParsesPerPaymentMethodSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "payment_method_types": ["card", "us_bank_account"],
            "setup_future_usage_for_payment_method_type": [
                "card": "off_session",
                "us_bank_account": "none",
            ],
        ]).withCustomer()

        XCTAssertEqual(
            session.setupFutureUsageForPaymentMethodType as NSDictionary,
            [
                "card": "off_session",
                "us_bank_account": "none",
            ] as NSDictionary
        )
    }

    func testDecodedObjectParsesCanDetachPaymentMethodTrue() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
                "can_detach_payment_method": true,
            ],
        ])

        XCTAssertTrue(session.customer?.canDetachPaymentMethod ?? false)
    }

    func testDecodedObjectParsesCanDetachPaymentMethodFalse() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
                "can_detach_payment_method": false,
            ],
        ])

        XCTAssertFalse(session.customer?.canDetachPaymentMethod ?? true)
    }

    func testDecodedObjectDefaultsCanDetachPaymentMethodToFalse() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
            ],
        ])

        XCTAssertFalse(session.customer?.canDetachPaymentMethod ?? true)
    }

    func testTotalsWithTaxFromTaxAmounts() {
        let session = CheckoutTestHelpers.makeSession([
            "total_summary": ["due": 2186, "subtotal": 2000, "total": 2186],
            "line_item_group": [
                "tax_amounts": [
                    ["amount": 186, "inclusive": false, "taxable_amount": 2000,
                     "tax_rate": ["percentage": 7.45, "display_name": "Sales Tax"], ],
                ],
            ],
        ])

        XCTAssertEqual(session.total?.taxExclusive.minorUnitsAmount, 186)
        XCTAssertEqual(session.total?.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(session.total?.total.minorUnitsAmount, 2186)
        XCTAssertEqual(session.total?.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.total?.shippingRate.minorUnitsAmount, 0)
        XCTAssertEqual(session.taxAmounts.count, 1)
        XCTAssertEqual(session.taxAmounts[0].amount, 186)
        XCTAssertFalse(session.taxAmounts[0].inclusive)
        XCTAssertEqual(session.taxAmounts[0].taxRate?.displayName, "Sales Tax")
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithoutSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([:]).withCustomer()

        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithTopLevelSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
        ]).withCustomer()

        XCTAssertTrue(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithTopLevelSetupFutureUsageNone() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "none",
        ]).withCustomer()

        XCTAssertEqual(session.setupFutureUsage, "none")
        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithPerPaymentMethodSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "payment_method_types": ["card", "us_bank_account"],
            "setup_future_usage_for_payment_method_type": [
                "card": "off_session",
                "us_bank_account": "none",
            ],
        ]).withCustomer()

        XCTAssertTrue(session.makePublicSession().merchantWillSavePaymentMethod(.card))
        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.USBankAccount))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithoutCustomer() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
        ])

        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_setupModeWithCustomer() {
        let session = CheckoutTestHelpers.makeSession([
            "mode": "setup",
            "payment_status": "no_payment_required",
        ]).withCustomer()

        XCTAssertTrue(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_setupModeWithoutCustomer() {
        let session = CheckoutTestHelpers.makeSession([
            "mode": "setup",
            "payment_status": "no_payment_required",
        ])

        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testCheckoutSessionIntent_setupFutureUsageString() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(Checkout(apiResponse: session)).setupFutureUsageString, "off_session")
    }

    func testCheckoutSessionIntent_isPaymentMethodOptionsSetupFutureUsageSet() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session",
            ],
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(Checkout(apiResponse: session)).isPaymentMethodOptionsSetupFutureUsageSet, true)
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_topLevel() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertTrue(Intent.checkout(Checkout(apiResponse: session)).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_topLevelNone() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "none",
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(Checkout(apiResponse: session)).setupFutureUsageString, "none")
        XCTAssertFalse(Intent.checkout(Checkout(apiResponse: session)).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_perPaymentMethod() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session",
            ],
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertTrue(Intent.checkout(Checkout(apiResponse: session)).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_perPaymentMethodNoneOverridesTopLevel() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
            "setup_future_usage_for_payment_method_type": [
                "paypal": "none",
            ],
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertFalse(Intent.checkout(Checkout(apiResponse: session)).isSetupFutureUsageSet(for: .payPal))
    }

    // MARK: - TaxStatus Tests

    func testTaxStatus_automaticRequiresLocationInputs_usesTaxContextAddressSource() {
        let taxMeta: [String: Any] = [
            "computation_type": "automatic",
            "status": "requires_location_inputs",
        ]
        let shipping = CheckoutTestHelpers.makeSession([
            "tax_meta": taxMeta,
            "tax_context": ["automatic_tax_address_source": "session.shipping"],
        ]).withCustomer()
        XCTAssertEqual(shipping.tax.status, .requiresShippingAddress)

        let billing = CheckoutTestHelpers.makeSession([
            "tax_meta": taxMeta,
            "tax_context": ["automatic_tax_address_source": "session.billing"],
        ]).withCustomer()
        XCTAssertEqual(billing.tax.status, .requiresBillingAddress)

        let missingSource = CheckoutTestHelpers.makeSession(["tax_meta": taxMeta]).withCustomer()
        XCTAssertEqual(missingSource.tax.status, .requiresBillingAddress)
    }

    func testTaxStatus_automaticFailed_returnsUnknown() {
        let session = CheckoutTestHelpers.makeSession([
            "tax_meta": [
                "computation_type": "automatic",
                "status": "failed",
            ],
        ]).withCustomer()
        XCTAssertEqual(session.tax.status, .unknown)
    }

    func testTaxStatus_nonAutomaticComputationType_isReady() {
        let session = CheckoutTestHelpers.makeSession([
            "tax_meta": [
                "computation_type": "dynamic",
                "status": "requires_location_inputs",
            ],
        ]).withCustomer()
        XCTAssertEqual(session.tax.status, .ready)
    }

    // MARK: - Elements Session Tests

    func testElementsSessionDecoding() {
        let session = CheckoutTestHelpers.makeSession([
            "elements_session": [
                "session_id": "es_123",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
            "tax_context": [
                "automatic_tax_enabled": true,
                "automatic_tax_address_source": "session.billing",
            ],
        ]).withCustomer()
        XCTAssertTrue(session.elementsSession.disableLinkForAutomaticTaxBilling)

        let sessionWithoutTax = CheckoutTestHelpers.makeSession([
            "elements_session": [
                "session_id": "es_123",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
        ]).withCustomer()
        XCTAssertFalse(sessionWithoutTax.elementsSession.disableLinkForAutomaticTaxBilling)

        var jsonWithoutES = CheckoutTestHelpers.baseSessionJSON
        jsonWithoutES.removeValue(forKey: "elements_session")
        XCTAssertNil(STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: jsonWithoutES))
    }

}

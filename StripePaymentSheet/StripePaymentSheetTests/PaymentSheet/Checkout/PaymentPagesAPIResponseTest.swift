//
//  PaymentPagesAPIResponseTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

@MainActor
class PaymentPagesAPIResponseTest: XCTestCase {

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() throws {
        let fullJson = try XCTUnwrap(STPTestUtils.jsonNamed("CheckoutSession"))

        XCTAssertNoThrow(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: fullJson),
            "can decode with full json"
        )

        // Required fields per API spec (non-nullable)
        let requiredFields = [
            "session_id",
            "currency",
            "mode",
            "checkout_items",
            "livemode",
            "status",
            "payment_status",
            "payment_method_types",
            "elements_session",
        ]

        for field in requiredFields {
            var partialJson = fullJson
            XCTAssertNotNil(partialJson[field])
            partialJson.removeValue(forKey: field)
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: partialJson),
                "should fail to decode without \(field)"
            )
        }

        var emptyCurrencyJson = fullJson
        emptyCurrencyJson["currency"] = ""
        XCTAssertThrowsError(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: emptyCurrencyJson),
            "should fail to decode with an empty currency"
        )
    }

    func testDecodedObjectFromAPIResponseMalformedElementsSession() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        // Invalid elements_session - missing payment_method_preference
        json["elements_session"] = ["garbage": true]

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testDecodingErrorIncludesNestedFieldPath() throws {
        let json = modifyingOneTimePriceItem { item in
            item.removeValue(forKey: "quantity")
        }

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json)) { error in
            guard case .keyNotFound(let key, let context) = error as? DecodingError else {
                return XCTFail("Expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "quantity")
            XCTAssertEqual(
                context.codingPath.map(\.stringValue),
                ["checkoutItems", "0", "oneTimePrice", "items", "0"]
            )
        }
    }

    func testLegacyDecodedPaymentMethodErrorIncludesArrayIndex() {
        var json = CheckoutTestHelpers.baseSessionJSON
        json["customer"] = [
            "id": "cus_123",
            "payment_methods": [["id": "pm_missing_created"]],
        ]

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json)) { error in
            guard case .dataCorrupted(let context) = error as? DecodingError else {
                return XCTFail("Expected dataCorrupted, got \(error)")
            }
            XCTAssertEqual(
                context.codingPath.map(\.stringValue),
                ["customer", "paymentMethods", "0"]
            )
            XCTAssertTrue(context.debugDescription.contains("STPPaymentMethod"))
        }
    }

    func testUnexpectedParsingErrorReporterAssertsAndSendsAnalytic() {
        let analyticsClient = MockAnalyticsClient()
        let error = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Invalid customer")
        )
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true

        reportUnexpectedPaymentPagesParsingError(
            error,
            apiClient: STPAPIClient(publishableKey: "pk_test_123"),
            analyticsClient: analyticsClient
        )

        XCTAssertTrue(STPAssertTestUtil.lastAssertMessage.contains("Invalid customer"))
        let analytic = analyticsClient.loggedAnalytics.last as? UnexpectedCheckoutElementsErrorAnalytic
        XCTAssertEqual(analytic?.errorCode, .paymentPagesResponseParsingFailed)
        XCTAssertTrue(analytic?.errorMessage.contains("Invalid customer") == true)
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let apiResponse = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        let session = apiResponse.makePublicSession()

        // The response object retains API-shaped values without public-model conversion.
        XCTAssertEqual(apiResponse.sessionId, "cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(apiResponse.status, "open")
        XCTAssertEqual(apiResponse.paymentStatus, "unpaid")
        XCTAssertEqual(apiResponse.checkoutItems.first?.key, "ci_1abc")
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.activePresentmentCurrency, "eur")
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.integrationAmount, 12000)
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.integrationCurrency, "usd")
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.localCurrencyOptions?.first?.amount, 10839)
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.localCurrencyOptions?.first?.currency, "eur")
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.localCurrencyOptions?.first?.conversionMarkupBps, 400)
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.localCurrencyOptions?.first?.presentmentExchangeRate, "0.90325")

        XCTAssertEqual(session.id, "cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(apiResponse.clientSecret, "cs_test_a1b2c3d4e5f6g7h8i9j0_secret_xyz123abc456")
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2149)
        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertEqual(session.minorUnitsAmountDivisor, 100)
        XCTAssertEqual(session.paymentStatus, .unpaid)
        XCTAssertEqual(session.status?.type, .open)  // status is nullable but present in JSON
        XCTAssertEqual(session.status?.paymentStatus, .unpaid)
        XCTAssertEqual(apiResponse.paymentIntentId, "pi_test123456789")
        XCTAssertNil(apiResponse.setupIntentId)
        XCTAssertFalse(session.livemode)
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
        XCTAssertEqual(apiResponse.url, "https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5f6g7h8i9j0")

        // Verify saved payment methods offer save
        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)
        XCTAssertEqual(session.savedPaymentMethodsOfferSave!.status, .notAccepted)
        XCTAssertNil(session.setupFutureUsage)

        XCTAssertNotNil(session.paymentMethodOptions)

        XCTAssertEqual(session.orderSummaryItems.count, 1)
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        XCTAssertEqual(oneTimePrice.items.count, 2)

        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 149)

        // Tax amounts
        XCTAssertEqual(session.tax.taxAmounts?.count, 1)
        XCTAssertEqual(session.tax.taxAmounts?[0].amount.minorUnitsAmount, 149)
        XCTAssertFalse(session.tax.taxAmounts?[0].inclusive ?? true)
        XCTAssertEqual(session.tax.taxAmounts?[0].displayName, "Sales Tax")

        // Automatic tax
        XCTAssertTrue(session.automaticTaxEnabled)
        XCTAssertEqual(session.automaticTaxAddressSource, "billing")

        // Shipping address collection
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA"])
        XCTAssertTrue(session.requiresShippingAddress)

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
            apiResponse.allResponseFields as NSDictionary,
            json as NSDictionary
        )
    }

    func testDecodedObjectWithMinimalRequiredFields() {
        // All required fields per API spec, but no optional fields
        let apiResponse = CheckoutTestHelpers.makeSession([
            "session_id": "cs_test_minimal",
            "livemode": true,
        ])
        let session = apiResponse.makePublicSession()

        XCTAssertEqual(session.id, "cs_test_minimal")
        XCTAssertEqual(session.status?.type, .open)
        XCTAssertTrue(session.livemode)

        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 1000)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 1000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertNil(apiResponse.clientSecret)
        XCTAssertNil(apiResponse.paymentIntentId)
        XCTAssertNil(apiResponse.setupIntentId)
        XCTAssertNil(session.customer)
        XCTAssertNil(session.email)
        XCTAssertNil(apiResponse.url)
        XCTAssertNil(session.savedPaymentMethodsOfferSave)
        XCTAssertNil(session.setupFutureUsage)
    }

    func testExpandedIntentsDecodeLegacyModels() throws {
        var paymentIntentJSON = CheckoutTestHelpers.baseSessionJSON
        paymentIntentJSON["payment_intent"] = STPTestUtils.jsonNamed("PaymentIntent")!
        let paymentIntentResponse = try PaymentPagesAPIResponse.decode(
            fromAPIResponse: paymentIntentJSON
        )

        var setupIntentJSON = CheckoutTestHelpers.baseSessionJSON
        setupIntentJSON["setup_intent"] = STPTestUtils.jsonNamed("SetupIntent")!
        let setupIntentResponse = try PaymentPagesAPIResponse.decode(
            fromAPIResponse: setupIntentJSON
        )

        XCTAssertEqual(
            paymentIntentResponse.paymentIntent?.stripeId,
            "pi_1Cl15wIl4IdHmuTbCWrpJXN6"
        )
        XCTAssertEqual(
            setupIntentResponse.setupIntent?.stripeID,
            "seti_123456789"
        )
    }

    func testExpandedIntentsRejectMalformedObjects() {
        var paymentIntentJSON = CheckoutTestHelpers.baseSessionJSON
        paymentIntentJSON["payment_intent"] = ["id": "pi_invalid"]
        XCTAssertThrowsError(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: paymentIntentJSON)
        )

        var setupIntentJSON = CheckoutTestHelpers.baseSessionJSON
        setupIntentJSON["setup_intent"] = ["id": "seti_invalid"]
        XCTAssertThrowsError(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: setupIntentJSON)
        )
    }

    func testDecodedObjectRejectsSetupMode() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "session_id": "cs_test_setup",
            "status": "open",
            "mode": "setup",
            "payment_status": "no_payment_required",
            "setup_intent": "seti_test123456",
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testModelessPaymentUsesSessionTotal() {
        let session = CheckoutTestHelpers.makeSession([
            "mode": "modeless",
            "payment_status": "unpaid",
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 2345),
        ]).makePublicSession()

        XCTAssertFalse(session.noPaymentRequired)
        XCTAssertEqual(session.expectedAmount(), 2345)
    }

    func testModelessNoPaymentRequiredSessionHasNoExpectedAmount() {
        let session = CheckoutTestHelpers.makeSession([
            "mode": "modeless",
            "payment_status": "no_payment_required",
        ]).makePublicSession()

        XCTAssertTrue(session.noPaymentRequired)
        XCTAssertNil(session.expectedAmount())
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
            (session.setupFutureUsageForPaymentMethodType ?? [:]) as NSDictionary,
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
        ]).makePublicSession()

        XCTAssertTrue(session.customer?.canDetachPaymentMethod ?? false)
    }

    func testDecodedObjectParsesCanDetachPaymentMethodFalse() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
                "can_detach_payment_method": false,
            ],
        ]).makePublicSession()

        XCTAssertFalse(session.customer?.canDetachPaymentMethod ?? true)
    }

    func testDecodedObjectDefaultsCanDetachPaymentMethodToFalse() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
            ],
        ]).makePublicSession()

        XCTAssertFalse(session.customer?.canDetachPaymentMethod ?? true)
    }

    func testAggregateTaxAmountsRemainSeparateFromTotals() {
        let session = CheckoutTestHelpers.makeSession([
            "mode": "modeless",
            "recurring_details": [
                "total_tax_amounts": [
                    ["amount": 186, "inclusive": false, "taxable_amount": 2000,
                     "tax_rate": ["percentage": 7.45, "display_name": "Sales Tax"], ],
                ],
            ],
        ]).makePublicSession()

        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 1000)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 1000)
        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.tax.taxAmounts?.count, 1)
        XCTAssertEqual(session.tax.taxAmounts?[0].amount.minorUnitsAmount, 186)
        XCTAssertFalse(session.tax.taxAmounts?[0].inclusive ?? true)
        XCTAssertEqual(session.tax.taxAmounts?[0].displayName, "Sales Tax")
    }

    func testUnifiedModeSessionParsesCheckoutItemsTaxAndDiscounts() {
        let session = CheckoutTestHelpers.makeSession([
            "mode": "modeless",
            "recurring_details": [
                "total_tax_amounts": [
                    [
                        "amount": 148,
                        "inclusive": false,
                        "taxable_amount": 2000,
                        "tax_rate": ["percentage": 7.4, "display_name": "Sales Tax"],
                    ],
                ],
                "total_discount_amounts": [
                    ["amount": 332, "coupon": ["id": "co_test", "name": "Welcome"]],
                ],
            ],
            "checkout_items": [
                [
                    "key": "checkout_item_abc123",
                    "type": "one_time_price",
                    "one_time_price": [
                        "subtotal": 2000,
                        "total": 2148,
                        "items": [
                            [
                                "inner_item_key": "checkout_item_inner_abc123",
                                "quantity": 2,
                                "subtotal": 2000,
                                "total": 2148,
                                "unit_amount": 1000,
                                "unit_amount_decimal": "1000",
                                "tax_amounts": [],
                                "tax_inclusive": 0,
                                "tax_exclusive": 148,
                                "price": [
                                    "id": "price_test123",
                                    "currency": "usd",
                                    "unit_amount": 1000,
                                    "product": [
                                        "name": "Classic T-Shirt",
                                        "description": "A comfy shirt",
                                        "images": ["https://example.com/shirt.png"],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]).makePublicSession()

        XCTAssertEqual(session.orderSummaryItems.count, 1)
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems[0] else {
            return XCTFail("Expected one-time price order summary item")
        }
        XCTAssertEqual(oneTimePrice.key, "checkout_item_abc123")
        XCTAssertNil(oneTimePrice.description)
        XCTAssertEqual(oneTimePrice.items.count, 1)
        XCTAssertEqual(oneTimePrice.items[0].key, "price_test123")
        XCTAssertEqual(oneTimePrice.items[0].displayName, "Classic T-Shirt")
        XCTAssertEqual(oneTimePrice.items[0].images, ["https://example.com/shirt.png"])
        XCTAssertEqual(oneTimePrice.items[0].quantity, 2)
        XCTAssertEqual(oneTimePrice.items[0].unitAmount.minorUnitsAmount, 1000)
        XCTAssertEqual(oneTimePrice.amountDetails.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(oneTimePrice.amountDetails.total.minorUnitsAmount, 2148)
        XCTAssertEqual(oneTimePrice.amountDetails.taxExclusive.minorUnitsAmount, 148)

        XCTAssertEqual(session.tax.taxAmounts?.count, 1)
        XCTAssertEqual(session.tax.taxAmounts?[0].amount.minorUnitsAmount, 148)
        XCTAssertEqual(session.tax.taxAmounts?[0].displayName, "Sales Tax")

        XCTAssertEqual(session.discountAmounts.count, 1)
        XCTAssertEqual(session.discountAmounts[0].amount.minorUnitsAmount, 332)
        XCTAssertEqual(session.discountAmounts[0].displayName, "Welcome")

        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 148)
        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2148)
    }

    func testTotalsSumOneTimePrices() {
        let session = CheckoutTestHelpers.makeSession([
            "checkout_items": [
                makeOneTimePriceCheckoutItem(
                    key: "one_time_price_1",
                    subtotal: 1000,
                    taxExclusive: 100,
                    taxInclusive: 0,
                    total: 1100
                ),
                makeOneTimePriceCheckoutItem(
                    key: "one_time_price_2",
                    subtotal: 500,
                    taxExclusive: 0,
                    taxInclusive: 40,
                    total: 500
                ),
            ],
        ]).makePublicSession()

        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 1500)
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 100)
        XCTAssertEqual(session.totals.taxInclusive.minorUnitsAmount, 40)
        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 1600)
        XCTAssertEqual(
            session.totals.total.amount,
            String.localizedAmountDisplayString(for: 1600, currency: "usd")
        )
    }

    func testUnifiedModeSessionRejectsUnsupportedCheckoutItemTypes() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "checkout_items": [
                ["key": "checkout_item_abc123", "type": "rate_card_subscription_item"],
            ],
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testUnifiedModeSessionRejectsMalformedOneTimePriceItems() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "checkout_items": [
                [
                    "key": "checkout_item_abc123",
                    "type": "one_time_price",
                    "one_time_price": [
                        "subtotal": 1000,
                        "total": 1000,
                        "items": [
                            [
                                "quantity": 1,
                                "price": ["id": "price_test123", "currency": "usd", "unit_amount": 1000],
                            ],
                        ],
                    ],
                ],
            ],
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testUnifiedModeSessionRejectsEmptyCheckoutItems() {
        let json = CheckoutTestHelpers.makeSessionJSON(["checkout_items": []])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testUnifiedModeSessionRejectsNonModelessMode() {
        let json = CheckoutTestHelpers.makeSessionJSON(["mode": "payment"])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testUnifiedModeSessionRejectsMissingRequiredOneTimePriceFields() {
        for field in ["key", "type", "one_time_price"] {
            let json = modifyingCheckoutItem { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing checkout item field \(field) to fail decoding"
            )
        }

        for field in ["items", "subtotal", "total"] {
            let json = modifyingOneTimePrice { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing one_time_price field \(field) to fail decoding"
            )
        }
    }

    func testUnifiedModeSessionRejectsMissingRequiredNestedItemFields() {
        let requiredFields = [
            "inner_item_key",
            "price",
            "quantity",
            "subtotal",
            "total",
            "tax_amounts",
            "tax_inclusive",
            "tax_exclusive",
        ]

        for field in requiredFields {
            let json = modifyingOneTimePriceItem { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing nested item field \(field) to fail decoding"
            )
        }
    }

    func testUnifiedModeSessionRejectsMissingRequiredPriceAndProductFields() {
        for field in ["id", "currency", "product"] {
            let json = modifyingPrice { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing Price field \(field) to fail decoding"
            )
        }

        for field in ["name", "images"] {
            let json = modifyingProduct { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing Product field \(field) to fail decoding"
            )
        }

        let mismatchedCurrencyJSON = modifyingPrice { $0["currency"] = "eur" }
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: mismatchedCurrencyJSON))
    }

    func testUnifiedModeSessionRejectsMalformedTaxAmounts() {
        let validTaxRate: [String: Any] = [
            "display_name": "Sales Tax",
            "percentage": 7.25,
        ]
        let validTaxAmount: [String: Any] = [
            "amount": 73,
            "inclusive": false,
            "tax_rate": validTaxRate,
        ]

        for field in ["amount", "inclusive", "tax_rate"] {
            let json = modifyingOneTimePriceItem { item in
                var taxAmount = validTaxAmount
                taxAmount.removeValue(forKey: field)
                item["tax_amounts"] = [taxAmount]
            }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing tax amount field \(field) to fail decoding"
            )
        }

        for field in ["display_name", "percentage"] {
            let json = modifyingOneTimePriceItem { item in
                var taxRate = validTaxRate
                taxRate.removeValue(forKey: field)
                var taxAmount = validTaxAmount
                taxAmount["tax_rate"] = taxRate
                item["tax_amounts"] = [taxAmount]
            }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing tax rate field \(field) to fail decoding"
            )
        }
    }

    func testUnifiedModeSessionRejectsInvalidOrMissingAmountRepresentation() {
        let invalidDecimalJSON = modifyingOneTimePriceItem {
            $0["unit_amount_decimal"] = "not-a-decimal"
        }
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: invalidDecimalJSON))

        let missingAmountJSON = modifyingOneTimePriceItem { item in
            item.removeValue(forKey: "unit_amount")
            item.removeValue(forKey: "unit_amount_decimal")
            var price = item["price"] as! [String: Any]
            price.removeValue(forKey: "unit_amount")
            item["price"] = price
        }
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: missingAmountJSON))
    }

    func testUnifiedModeSessionMapsDecimalOnlyAmountLikeEwCS() throws {
        let json = modifyingOneTimePriceItem { item in
            item.removeValue(forKey: "unit_amount")
            item["unit_amount_decimal"] = "12.345"
            var price = item["price"] as! [String: Any]
            price.removeValue(forKey: "unit_amount")
            item["price"] = price
        }

        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        let session = response.makePublicSession()
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        let item = try XCTUnwrap(oneTimePrice.items.first)
        XCTAssertEqual(item.unitAmount.minorUnitsAmount, 0)
        let unitAmountDecimal = try XCTUnwrap(item.unitAmountDecimal)
        XCTAssertEqual(unitAmountDecimal.minorUnitsAmount, 12.345)
        XCTAssertEqual(unitAmountDecimal.amount, "$0.12345")
    }

    func testUnifiedModeSessionMapsAdjustableQuantity() throws {
        let enabledJSON = modifyingOneTimePriceItem {
            $0["adjustable_quantity"] = ["enabled": true]
        }
        let enabledResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: enabledJSON)
        guard case .oneTimePrice(let enabledOneTimePrice) = enabledResponse.makePublicSession().orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        let enabledQuantity = try XCTUnwrap(enabledOneTimePrice.items.first?.adjustableQuantity)
        XCTAssertTrue(enabledQuantity.enabled)
        XCTAssertEqual(enabledQuantity.minimum, 0)
        XCTAssertEqual(enabledQuantity.maximum, 99)

        let disabledJSON = modifyingOneTimePriceItem {
            $0["adjustable_quantity"] = ["enabled": false]
        }
        let disabledResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: disabledJSON)
        guard case .oneTimePrice(let disabledOneTimePrice) = disabledResponse.makePublicSession().orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        XCTAssertNil(disabledOneTimePrice.items.first?.adjustableQuantity)
    }

    func testUnifiedModeSessionAllowsEmptyNestedItems() throws {
        let json = modifyingOneTimePrice { $0["items"] = [] }
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        guard case .oneTimePrice(let oneTimePrice) = response.makePublicSession().orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }

        XCTAssertTrue(oneTimePrice.items.isEmpty)
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

    func testCheckoutSessionIntent_setupFutureUsageString() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(session.makePublicSession()).setupFutureUsageString, "off_session")
    }

    func testCheckoutSessionIntent_isPaymentMethodOptionsSetupFutureUsageSet() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session",
            ],
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(session.makePublicSession()).isPaymentMethodOptionsSetupFutureUsageSet, true)
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_topLevel() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertTrue(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_topLevelNone() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "none",
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(session.makePublicSession()).setupFutureUsageString, "none")
        XCTAssertFalse(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_perPaymentMethod() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session",
            ],
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertTrue(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_perPaymentMethodNoneOverridesTopLevel() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage": "off_session",
            "setup_future_usage_for_payment_method_type": [
                "paypal": "none",
            ],
            "payment_method_types": ["paypal"],
        ]).withCustomer()

        XCTAssertFalse(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
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
        ]).withCustomer().makePublicSession()
        XCTAssertEqual(shipping.tax.status, .requiresShippingAddress)

        let billing = CheckoutTestHelpers.makeSession([
            "tax_meta": taxMeta,
            "tax_context": ["automatic_tax_address_source": "session.billing"],
        ]).withCustomer().makePublicSession()
        XCTAssertEqual(billing.tax.status, .requiresBillingAddress)

        let missingSource = CheckoutTestHelpers.makeSession(["tax_meta": taxMeta]).withCustomer().makePublicSession()
        XCTAssertEqual(missingSource.tax.status, .requiresBillingAddress)
    }

    func testTaxStatus_automaticFailed_returnsUnknown() {
        let session = CheckoutTestHelpers.makeSession([
            "tax_meta": [
                "computation_type": "automatic",
                "status": "failed",
            ],
        ]).withCustomer().makePublicSession()
        XCTAssertEqual(session.tax.status, .unknown)
    }

    func testTaxStatus_nonAutomaticComputationType_isReady() {
        let session = CheckoutTestHelpers.makeSession([
            "tax_meta": [
                "computation_type": "dynamic",
                "status": "requires_location_inputs",
            ],
        ]).withCustomer().makePublicSession()
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
        ]).withCustomer().makePublicSession()
        XCTAssertTrue(session.elementsSession.disableLinkForAutomaticTaxBilling)

        let sessionWithoutTax = CheckoutTestHelpers.makeSession([
            "elements_session": [
                "session_id": "es_123",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
        ]).withCustomer().makePublicSession()
        XCTAssertFalse(sessionWithoutTax.elementsSession.disableLinkForAutomaticTaxBilling)

        var jsonWithoutES = CheckoutTestHelpers.baseSessionJSON
        jsonWithoutES.removeValue(forKey: "elements_session")
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: jsonWithoutES))
    }

    private func modifyingCheckoutItem(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        var json = CheckoutTestHelpers.makeSessionJSON()
        var checkoutItems = json["checkout_items"] as! [[String: Any]]
        mutation(&checkoutItems[0])
        json["checkout_items"] = checkoutItems
        return json
    }

    private func modifyingOneTimePrice(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        modifyingCheckoutItem { checkoutItem in
            var oneTimePrice = checkoutItem["one_time_price"] as! [String: Any]
            mutation(&oneTimePrice)
            checkoutItem["one_time_price"] = oneTimePrice
        }
    }

    private func modifyingOneTimePriceItem(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        modifyingOneTimePrice { oneTimePrice in
            var items = oneTimePrice["items"] as! [[String: Any]]
            mutation(&items[0])
            oneTimePrice["items"] = items
        }
    }

    private func modifyingPrice(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        modifyingOneTimePriceItem { item in
            var price = item["price"] as! [String: Any]
            mutation(&price)
            item["price"] = price
        }
    }

    private func modifyingProduct(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        modifyingPrice { price in
            var product = price["product"] as! [String: Any]
            mutation(&product)
            price["product"] = product
        }
    }

    private func makeOneTimePriceCheckoutItem(
        key: String,
        subtotal: Int,
        taxExclusive: Int,
        taxInclusive: Int,
        total: Int
    ) -> [String: Any] {
        var checkoutItem = CheckoutTestHelpers.makeOneTimePriceCheckoutItems()[0]
        checkoutItem["key"] = key
        var oneTimePrice = checkoutItem["one_time_price"] as! [String: Any]
        var item = (oneTimePrice["items"] as! [[String: Any]])[0]
        var price = item["price"] as! [String: Any]
        item["inner_item_key"] = "\(key)_inner"
        item["subtotal"] = subtotal
        item["total"] = total
        item["unit_amount"] = subtotal
        item["unit_amount_decimal"] = String(subtotal)
        item["tax_exclusive"] = taxExclusive
        item["tax_inclusive"] = taxInclusive
        price["id"] = "\(key)_price"
        price["unit_amount"] = subtotal
        item["price"] = price
        oneTimePrice["items"] = [item]
        oneTimePrice["subtotal"] = subtotal
        oneTimePrice["total"] = total
        checkoutItem["one_time_price"] = oneTimePrice
        return checkoutItem
    }

}

//
//  PaymentPagesAPIResponseTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

@MainActor
class PaymentPagesAPIResponseTest: XCTestCase {

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectRejectsMissingSDKRequiredFields() throws {
        let fullJson = try XCTUnwrap(STPTestUtils.jsonNamed("CheckoutSession"))

        XCTAssertNoThrow(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: fullJson),
            "can decode with full json"
        )

        // Fields required by the SDK for the supported mobile response profile.
        let requiredFields = [
            "id",
            "presentment_currency",
            "integration_currency",
            "ui_mode",
            "items",
            "livemode",
            "status",
            "payment_status",
            "elements_session_id",
            "merchant_info",
            "ordered_payment_method_types_and_wallets",
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
        emptyCurrencyJson["presentment_currency"] = ""
        XCTAssertThrowsError(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: emptyCurrencyJson),
            "should fail to decode with an empty currency"
        )
    }

    func testDecodedObjectFromAPIResponseMapsSessionStatus() throws {
        let testCases: [(status: String, paymentStatus: String, expected: CheckoutController.Session.Status)] = [
            ("open", "unpaid", .open),
            ("expired", "unpaid", .expired),
            ("complete", "paid", .complete(.paid)),
            ("complete", "unpaid", .complete(.unpaid)),
            ("complete", "no_payment_required", .complete(.noPaymentRequired)),
        ]

        for testCase in testCases {
            var json = STPTestUtils.jsonNamed("CheckoutSession")!
            json["status"] = testCase.status
            json["payment_status"] = testCase.paymentStatus

            let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)

            XCTAssertEqual(response.makePublicSession().status, testCase.expected)
        }
    }

    func testDecodesCheckoutClientPaymentStatuses() throws {
        for status in [
            "requires_payment_method", "requires_action", "processing", "requires_capture", "succeeded", "canceled",
        ] {
            var json = CheckoutTestHelpers.makeSessionJSON()
            json["payment_response"] = ["status": status]

            let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)

            XCTAssertEqual(response.paymentResponse?.status, status)
        }
    }

    func testRejectsCheckoutClientPaymentResponseWithoutStatus() {
        var json = CheckoutTestHelpers.makeSessionJSON()
        json["payment_response"] = [:]

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testDecodedObjectFromAPIResponseRejectsUnknownSessionStatus() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        json["status"] = "future_status"

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testDecodedObjectFromAPIResponseRejectsUnknownPaymentStatus() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        json["payment_status"] = "future_status"

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testDecodedObjectFromAPIResponseMalformedElementsSession() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        // Invalid ordered payment method types
        json["ordered_payment_method_types_and_wallets"] = ["garbage": true]

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json)) { error in
            guard case .dataCorrupted(let context) = error as? DecodingError else {
                return XCTFail("Expected dataCorrupted, got \(error)")
            }
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["orderedPaymentMethodTypesAndWallets"])
        }
    }

    func testDecodedObjectFromAPIResponseRequiresMerchantCountry() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        var merchant = json["merchant_info"] as! [String: Any]
        merchant.removeValue(forKey: "country")
        json["merchant_info"] = merchant

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json)) { error in
            guard case .keyNotFound(let key, let context) = error as? DecodingError else {
                return XCTFail("Expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "country")
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["merchantInfo"])
        }
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
                ["items", "0", "oneTimePrice", "items", "0"]
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

    func testDecodedObjectFromAPIResponseMapping() throws {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let apiResponse = try! PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        let session = apiResponse.makePublicSession()

        // The response object retains API-shaped values without public-model conversion.
        XCTAssertEqual(apiResponse.sessionId, "cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(apiResponse.status, .open)
        XCTAssertEqual(apiResponse.paymentStatus, .unpaid)
        XCTAssertEqual(apiResponse.checkoutItems.first?.key, "ci_1abc")
        XCTAssertEqual(apiResponse.checkoutItems.first?.oneTimePrice.items.first?.innerItemKey, "cii_1abc")
        XCTAssertEqual(apiResponse.currency, "eur")
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.integrationAmount, 12000)
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.integrationCurrency, "usd")
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.localCurrencyOptions.first?.amount, 10839)
        XCTAssertEqual(apiResponse.adaptivePricingInfo?.localCurrencyOptions.first?.currency, "eur")

        XCTAssertEqual(session.id, "cs_test_a1b2c3d4e5f6g7h8i9j0")
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2149)
        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertEqual(session.minorUnitsAmountDivisor, 100)
        XCTAssertEqual(session.paymentStatus, .unpaid)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(apiResponse.paymentResponse?.paymentIntent?.id, "pi_test123456789")
        XCTAssertNil(apiResponse.paymentResponse?.setupIntent?.id)
        XCTAssertFalse(session.livemode)
        XCTAssertNotNil(session.customer)
        XCTAssertEqual(session.customer?.id, "cus_test123456")
        XCTAssertFalse(session.canDetachPaymentMethod)
        XCTAssertEqual(session.customer?.paymentMethods.count, 2)
        XCTAssertEqual(session.customer?.paymentMethods[0].stripeId, "pm_1Sxae3Lu5o3P18Zpt5YuRRoG")
        XCTAssertEqual(session.customer?.paymentMethods[0].type, .card)
        XCTAssertEqual(session.customer?.paymentMethods[0].card?.last4, "4242")
        XCTAssertEqual(session.customer?.paymentMethods[1].stripeId, "pm_1Sxae4Lu5o3P18ZplFiKexnM")
        XCTAssertEqual(session.customer?.paymentMethods[1].type, .USBankAccount)
        XCTAssertEqual(session.businessName, "CI Stuff")
        XCTAssertEqual(session.elementsSession.sessionID, "elements_session_test123")
        XCTAssertEqual(session.email, "test@example.com")
        XCTAssertEqual(session.serverEmail, "test@example.com")

        // Verify saved payment methods offer save
        XCTAssertNotNil(session.savedPaymentMethodsOfferSave)
        XCTAssertTrue(session.savedPaymentMethodsOfferSave!.enabled)

        XCTAssertNotNil(session.paymentMethodOptions)

        XCTAssertEqual(session.orderSummaryItems.count, 1)
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        XCTAssertEqual(oneTimePrice.items.count, 2)

        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 149)

        // Tax amounts
        XCTAssertEqual(session.taxAmounts?.count, 1)
        XCTAssertFalse(session.taxAmounts?[0].amount.isEmpty ?? true)
        XCTAssertEqual(session.taxAmounts?[0].minorUnitsAmount, 149)
        XCTAssertFalse(session.taxAmounts?[0].inclusive ?? true)
        XCTAssertEqual(session.taxAmounts?[0].displayName, "Sales Tax")
        XCTAssertEqual(session.taxAmounts?[0].percentage, 7.45)

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
        XCTAssertEqual(session.exchangeRateMeta?.localizedCurrency, "eur")
        XCTAssertEqual(session.exchangeRateMeta?.integrationCurrency, "usd")

        // Presentment details (derived from adaptive pricing)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertEqual(session.presentmentDetails?.presentmentCurrency, "eur")

        XCTAssertEqual(
            apiResponse.allResponseFields as NSDictionary,
            json as NSDictionary
        )

        var checkoutClientJSON = json as! [String: Any]
        checkoutClientJSON["flags"] = ["elements_enable_passive_captcha": true]
        checkoutClientJSON["passive_captcha"] = [
            "site_key": "site_key", "rqdata": "rqdata", "token_refresh_after_seconds": 21570,
        ]
        let data = try JSONSerialization.data(withJSONObject: checkoutClientJSON)
        let checkoutClient = try StripeJSONDecoder().decode(PaymentPagesAPIResponse.self, from: data)
        XCTAssertEqual(
            checkoutClient.makePublicSession().elementsSession.passiveCaptchaData,
            PassiveCaptchaData(siteKey: "site_key", rqdata: "rqdata", tokenTimeoutSeconds: 21570)
        )
    }

    func testDecodedObjectWithOnlySDKRequiredFields() throws {
        let json: [String: Any] = [
            "livemode": true,
            "status": "open",
            "payment_status": "unpaid",
            "id": "cs_test_minimal",
            "items": [
                [
                    "key": "checkout_item_test",
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "inner_item_key": "checkout_item_inner_test",
                                "price": [
                                    "id": "price_test",
                                    "currency": "usd",
                                    "product": [
                                        "name": "Test product",
                                        "images": [],
                                    ],
                                ],
                                "quantity": 1,
                                "unit_amount": 1000,
                                "amount_details": [
                                    "subtotal": 1000,
                                    "total": 1000,
                                    "tax_amounts": [],
                                    "tax_inclusive": 0,
                                    "tax_exclusive": 0,
                                ],
                            ],
                        ],
                        "subtotal": 1000,
                        "total": 1000,
                    ],
                ],
            ],
            "ui_mode": "mobile_elements",
            "integration_currency": "usd",
            "presentment_currency": "usd",
            "ordered_payment_method_types_and_wallets": ["card"],
            "elements_session_id": "es_test",
            "merchant_info": [
                "country": "US"
            ],
        ]

        let apiResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        let session = apiResponse.makePublicSession()

        XCTAssertEqual(session.id, "cs_test_minimal")
        XCTAssertEqual(session.status, .open)
        XCTAssertTrue(session.livemode)

        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 1000)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 1000)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertNil(session.presentmentDetails)
        XCTAssertNil(apiResponse.paymentResponse?.paymentIntent?.id)
        XCTAssertNil(apiResponse.paymentResponse?.setupIntent?.id)
        XCTAssertNil(session.customer)
        XCTAssertNil(session.email)
        XCTAssertNil(session.savedPaymentMethodsOfferSave)
    }

    func testAdaptivePricingInfoRejectsMissingRequiredFields() {
        let adaptivePricingInfo: [String: Any] = [
            "integration_currency_option": ["amount": 1200, "currency": "usd"],
            "local_currency_options": [
                [
                    "amount": 1080,
                    "conversion_markup_bps": 400,
                    "currency": "eur",
                    "presentment_exchange_rate": "0.9",
                ],
            ],
        ]

        for field in [
            "integration_currency_option",
            "local_currency_options",
        ] {
            var invalidAdaptivePricingInfo = adaptivePricingInfo
            invalidAdaptivePricingInfo.removeValue(forKey: field)
            var json = CheckoutTestHelpers.baseSessionJSON
            json["adaptive_pricing_info"] = invalidAdaptivePricingInfo

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing \(field) to fail decoding"
            )
        }
    }

    func testAdaptivePricingLocalCurrencyOptionRejectsMissingRequiredFields() {
        let localCurrencyOption: [String: Any] = [
            "amount": 1080,
            "conversion_markup_bps": 400,
            "currency": "eur",
            "presentment_exchange_rate": "0.9",
        ]

        for field in ["amount", "currency"] {
            var invalidLocalCurrencyOption = localCurrencyOption
            invalidLocalCurrencyOption.removeValue(forKey: field)
            var json = CheckoutTestHelpers.baseSessionJSON
            json["adaptive_pricing_info"] = [
                "integration_currency_option": ["amount": 1200, "currency": "usd"],
                "local_currency_options": [invalidLocalCurrencyOption],
            ]

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing \(field) to fail decoding"
            )
        }
    }

    func testAdaptivePricingLocalCurrencyOptionAllowsMissingOrNullDisclosure() throws {
        let disclosures: [Any?] = [nil, NSNull()]

        for disclosure in disclosures {
            var localCurrencyOption: [String: Any] = [
                "amount": 1080,
                "currency": "eur",
                "presentment_exchange_rate": "0.9",
            ]
            localCurrencyOption["disclosure"] = disclosure

            var json = CheckoutTestHelpers.baseSessionJSON
            json["adaptive_pricing_info"] = [
                "integration_currency_option": ["amount": 1200, "currency": "usd"],
                "local_currency_options": [localCurrencyOption],
            ]

            let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
            let session = response.makePublicSession()
            let exchangeRateMeta = try XCTUnwrap(session.exchangeRateMeta)

            XCTAssertTrue(session.adaptivePricingActive)
            XCTAssertNotNil(CurrencySelectorUtilities.adaptivePricingData(from: session))
            XCTAssertNil(CurrencySelectorUtilities.detailText(exchangeRateMeta: exchangeRateMeta))
        }
    }

    func testIntentReferencesDecode() throws {
        var json = CheckoutTestHelpers.baseSessionJSON
        json["payment_response"] = [
            "status": "succeeded",
            "payment_intent": ["id": "pi_123", "client_secret": "pi_123_secret_abc"],
            "setup_intent": ["id": "seti_123", "client_secret": "seti_123_secret_abc"],
        ]
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
        XCTAssertEqual(response.paymentResponse?.paymentIntent?.id, "pi_123")
        XCTAssertEqual(response.paymentResponse?.setupIntent?.id, "seti_123")
    }

    func testIntentReferencesRequireClientSecrets() {
        for key in ["payment_intent", "setup_intent"] {
            var json = CheckoutTestHelpers.baseSessionJSON
            json["payment_response"] = ["status": "requires_action", key: ["id": "intent_123"]]
            XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
        }
    }

    func testDecodedObjectRejectsSetupMode() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "status": "open",
            "payment_status": "no_payment_required",
            "setup_intent": "seti_test123456",
            "id": "cs_test_setup",
            "ui_mode": "setup",
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testModelessPaymentUsesSessionTotal() {
        let session = CheckoutTestHelpers.makeSession([
            "payment_status": "unpaid",
            "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 2345),
            "ui_mode": "mobile_elements",
            "integration_currency": "usd",
        ]).makePublicSession()

        XCTAssertFalse(session.noPaymentRequired)
        XCTAssertEqual(session.amount, 2345)
    }

    func testDecodedObjectParsesResolvedSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "card": "off_session",
                "link": "off_session",
            ],
        ]).withCustomer()

        XCTAssertEqual(session.makePublicSession().setupFutureUsage(for: .card), "off_session")
    }

    func testDecodedObjectParsesPerPaymentMethodSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "ordered_payment_method_types_and_wallets": ["card", "us_bank_account"],
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
            ],
            "saved_payment_method_options": [
                "payment_method_remove": "enabled",
                "payment_method_save": "disabled",
            ],
        ]).makePublicSession()

        XCTAssertTrue(session.canDetachPaymentMethod)
    }

    func testDecodedObjectParsesCanDetachPaymentMethodFalse() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
            ],
            "saved_payment_method_options": [
                "payment_method_remove": "disabled",
                "payment_method_save": "disabled",
            ],
        ]).makePublicSession()

        XCTAssertFalse(session.canDetachPaymentMethod)
    }

    func testDecodedObjectDefaultsCanDetachPaymentMethodToFalse() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_test_123",
                "payment_methods": [],
            ],
        ]).makePublicSession()

        XCTAssertFalse(session.canDetachPaymentMethod)
    }

    func testRemovalPermissionUsesSessionConfigurationWithoutCustomer() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": NSNull(),
            "saved_payment_method_options": ["payment_method_remove": "enabled"],
        ]).makePublicSession()

        XCTAssertTrue(session.canDetachPaymentMethod)
        XCTAssertNil(session.customer)
        XCTAssertTrue(Intent.checkout(session).allowsPaymentMethodRemoval(elementsSession: session.elementsSession))
    }

    func testAggregateTaxAmountsRemainSeparateFromTotals() {
        let session = CheckoutTestHelpers.makeSession([
            "total_summary": [
                "total_tax_amounts": [
                    [
                        "amount": 186, "inclusive": false, "taxable_amount": 2000,
                        "percentage": 7.45, "display_name": "Sales Tax",
                    ],
                ],
            ],
            "ui_mode": "mobile_elements",
            "integration_currency": "usd",
        ]).makePublicSession()

        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.subtotal.minorUnitsAmount, 1000)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 1000)
        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.taxAmounts?.count, 1)
        XCTAssertEqual(session.taxAmounts?[0].minorUnitsAmount, 186)
        XCTAssertFalse(session.taxAmounts?[0].inclusive ?? true)
        XCTAssertEqual(session.taxAmounts?[0].displayName, "Sales Tax")
    }

    func testUnifiedModeSessionParsesCheckoutItemsAndTax() {
        let session = CheckoutTestHelpers.makeSession([

            "total_summary": [
                "total_tax_amounts": [
                    [
                        "amount": 148,
                        "inclusive": false,
                        "taxable_amount": 2000,
                        "percentage": 7.4, "display_name": "Sales Tax",
                    ],
                ],
            ],
            "items": [
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
                                "unit_amount": 1000,
                                "unit_amount_decimal": "1000",
                                "amount_details": [
                                    "subtotal": 2000,
                                    "total": 2148,
                                    "tax_amounts": [],
                                    "tax_inclusive": 0,
                                    "tax_exclusive": 148,
                                ],
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
            "ui_mode": "mobile_elements",
            "integration_currency": "usd",
        ]).makePublicSession()

        XCTAssertEqual(session.orderSummaryItems.count, 1)
        let orderSummaryItem = session.orderSummaryItems[0]
        XCTAssertEqual(orderSummaryItem.id, "checkout_item_abc123")
        guard case .oneTimePrice(let oneTimePrice) = orderSummaryItem else {
            return XCTFail("Expected one-time price order summary item")
        }
        XCTAssertEqual(oneTimePrice.key, "checkout_item_abc123")
        XCTAssertEqual(oneTimePrice.id, "checkout_item_abc123")
        XCTAssertNil(oneTimePrice.description)
        XCTAssertEqual(oneTimePrice.items.count, 1)
        XCTAssertEqual(oneTimePrice.items[0].key, "checkout_item_inner_abc123")
        XCTAssertEqual(oneTimePrice.items[0].id, "checkout_item_inner_abc123")
        XCTAssertNotEqual(oneTimePrice.items[0].id, "price_test123")
        XCTAssertEqual(oneTimePrice.items[0].displayName, "Classic T-Shirt")
        XCTAssertEqual(oneTimePrice.items[0].images, ["https://example.com/shirt.png"])
        XCTAssertEqual(oneTimePrice.items[0].quantity, 2)
        XCTAssertEqual(oneTimePrice.items[0].unitAmount.minorUnitsAmount, 1000)
        XCTAssertEqual(oneTimePrice.items[0].amountDetails.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(oneTimePrice.items[0].amountDetails.total.minorUnitsAmount, 2148)
        XCTAssertEqual(oneTimePrice.items[0].amountDetails.taxExclusive.minorUnitsAmount, 148)
        XCTAssertNil(oneTimePrice.items[0].amountDetails.taxAmounts)

        XCTAssertEqual(session.taxAmounts?.count, 1)
        XCTAssertEqual(session.taxAmounts?[0].minorUnitsAmount, 148)
        XCTAssertEqual(session.taxAmounts?[0].displayName, "Sales Tax")

        XCTAssertTrue(session.discountAmounts.isEmpty)

        XCTAssertEqual(session.totals.taxExclusive.minorUnitsAmount, 148)
        XCTAssertEqual(session.totals.discount.minorUnitsAmount, 0)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2148)
    }

    func testOneTimePriceMapsAmountDetailsPerItem() throws {
        let json = modifyingOneTimePrice { oneTimePrice in
            var firstItem = (oneTimePrice["items"] as! [[String: Any]])[0]
            firstItem["inner_item_key"] = "first_item"
            firstItem["amount_details"] = [
                "subtotal": 1000,
                "total": 1100,
                "tax_inclusive": 0,
                "tax_exclusive": 100,
                "tax_amounts": [[
                    "amount": 100,
                    "inclusive": false,
                    "tax_rate": ["display_name": "Sales Tax", "percentage": 10.0],
                ], ],
            ]

            var secondItem = firstItem
            secondItem["inner_item_key"] = "second_item"
            secondItem["amount_details"] = [
                "subtotal": 2000,
                "total": 2000,
                "tax_inclusive": 50,
                "tax_exclusive": 0,
                "tax_amounts": [[
                    "amount": 50,
                    "inclusive": true,
                    "tax_rate": ["display_name": "VAT", "percentage": 2.5],
                ], ],
            ]
            oneTimePrice["items"] = [firstItem, secondItem]
            oneTimePrice["subtotal"] = 3000
            oneTimePrice["total"] = 3100
        }

        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time price order summary item")
        }

        let firstAmountDetails = oneTimePrice.items[0].amountDetails
        XCTAssertEqual(firstAmountDetails.subtotal.minorUnitsAmount, 1000)
        XCTAssertEqual(firstAmountDetails.total.minorUnitsAmount, 1100)
        XCTAssertEqual(firstAmountDetails.taxExclusive.minorUnitsAmount, 100)
        XCTAssertEqual(firstAmountDetails.taxInclusive.minorUnitsAmount, 0)
        XCTAssertEqual(firstAmountDetails.taxAmounts?.first?.displayName, "Sales Tax")

        let secondAmountDetails = oneTimePrice.items[1].amountDetails
        XCTAssertEqual(secondAmountDetails.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(secondAmountDetails.total.minorUnitsAmount, 2000)
        XCTAssertEqual(secondAmountDetails.taxExclusive.minorUnitsAmount, 0)
        XCTAssertEqual(secondAmountDetails.taxInclusive.minorUnitsAmount, 50)
        XCTAssertEqual(secondAmountDetails.taxAmounts?.first?.displayName, "VAT")
    }

    func testTotalsSumOneTimePriceItems() {
        let session = CheckoutTestHelpers.makeSession([
            "items": [
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
            "items": [
                ["key": "checkout_item_abc123", "type": "rate_card_subscription_item"]
            ],
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testUnifiedModeSessionRejectsMalformedOneTimePriceItems() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "items": [
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
        let json = CheckoutTestHelpers.makeSessionJSON([
            "items": []
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testUnifiedModeSessionRejectsNonMobileElementsMode() {
        for uiMode in ["hosted", "embedded", "custom", "elements", "form", "payment"] {
            let json = CheckoutTestHelpers.makeSessionJSON([
                "ui_mode": uiMode
            ])

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected ui_mode \(uiMode) to fail decoding"
            )
        }
    }

    func testUnifiedModeSessionRejectsMissingRequiredOneTimePriceFields() {
        for field in ["key", "type", "one_time_price"] {
            let json = modifyingCheckoutItem { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing checkout item field \(field) to fail decoding"
            )
        }

        let json = modifyingOneTimePrice { $0.removeValue(forKey: "items") }
        XCTAssertThrowsError(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
            "Expected missing one_time_price items to fail decoding"
        )
    }

    func testUnifiedModeSessionRejectsMissingRequiredNestedItemFields() {
        let requiredFields = [
            "inner_item_key",
            "price",
            "quantity",
            "amount_details",
        ]

        for field in requiredFields {
            let json = modifyingOneTimePriceItem { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing nested item field \(field) to fail decoding"
            )
        }

        for field in ["subtotal", "total", "tax_inclusive", "tax_exclusive"] {
            let json = modifyingAmountDetails { $0.removeValue(forKey: field) }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing amount_details field \(field) to fail decoding"
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
            let json = modifyingAmountDetails { amountDetails in
                var taxAmount = validTaxAmount
                taxAmount.removeValue(forKey: field)
                amountDetails["tax_amounts"] = [taxAmount]
            }
            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing tax amount field \(field) to fail decoding"
            )
        }

        for field in ["display_name", "percentage"] {
            let json = modifyingAmountDetails { amountDetails in
                var taxRate = validTaxRate
                taxRate.removeValue(forKey: field)
                var taxAmount = validTaxAmount
                taxAmount["tax_rate"] = taxRate
                amountDetails["tax_amounts"] = [taxAmount]
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
            $0["adjustable_quantity"] = [
                "enabled": true,
                "minimum": 2,
                "maximum": 10,
            ]
        }
        let enabledResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: enabledJSON)
        guard case .oneTimePrice(let enabledOneTimePrice) = enabledResponse.makePublicSession().orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        let enabledQuantity = try XCTUnwrap(enabledOneTimePrice.items.first?.adjustableQuantity)
        XCTAssertTrue(enabledQuantity.enabled)
        XCTAssertEqual(enabledQuantity.minimum, 2)
        XCTAssertEqual(enabledQuantity.maximum, 10)

        let disabledJSON = modifyingOneTimePriceItem {
            $0["adjustable_quantity"] = ["enabled": false]
        }
        let disabledResponse = try PaymentPagesAPIResponse.decode(fromAPIResponse: disabledJSON)
        guard case .oneTimePrice(let disabledOneTimePrice) = disabledResponse.makePublicSession().orderSummaryItems.first else {
            return XCTFail("Expected one-time Price order summary item")
        }
        XCTAssertNil(disabledOneTimePrice.items.first?.adjustableQuantity)
    }

    func testUnifiedModeSessionRejectsEnabledAdjustableQuantityWithoutBounds() {
        for field in ["minimum", "maximum"] {
            var adjustableQuantity: [String: Any] = [
                "enabled": true,
                "minimum": 0,
                "maximum": 99,
            ]
            adjustableQuantity.removeValue(forKey: field)
            let json = modifyingOneTimePriceItem {
                $0["adjustable_quantity"] = adjustableQuantity
            }

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing \(field) to fail decoding"
            )
        }
    }

    func testUnifiedModeSessionRejectsEnabledAdjustableQuantityWithNullBounds() {
        for field in ["minimum", "maximum"] {
            var adjustableQuantity: [String: Any] = [
                "enabled": true,
                "minimum": 0,
                "maximum": 99,
            ]
            adjustableQuantity[field] = NSNull()
            let json = modifyingOneTimePriceItem {
                $0["adjustable_quantity"] = adjustableQuantity
            }

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected null \(field) to fail decoding"
            )
        }
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
            "setup_future_usage_for_payment_method_type": [
                "card": "off_session",
                "link": "off_session",
            ],
        ]).withCustomer()

        XCTAssertTrue(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithTopLevelSetupFutureUsageNone() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "card": "none",
                "link": "none",
            ],
        ]).withCustomer()

        XCTAssertEqual(session.makePublicSession().setupFutureUsage(for: .card), "none")
        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testMerchantWillSavePaymentMethod_paymentModeWithPerPaymentMethodSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "ordered_payment_method_types_and_wallets": ["card", "us_bank_account"],
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
            "setup_future_usage_for_payment_method_type": [
                "card": "off_session",
                "link": "off_session",
            ],
        ])

        XCTAssertFalse(session.makePublicSession().merchantWillSavePaymentMethod(.card))
    }

    func testCheckoutSessionIntent_hasNoGlobalSetupFutureUsage() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "card": "off_session",
                "link": "off_session",
            ],
        ]).withCustomer()

        XCTAssertNil(Intent.checkout(session.makePublicSession()).setupFutureUsageString)
        XCTAssertEqual(session.makePublicSession().setupFutureUsage(for: .link), "off_session")
    }

    func testCheckoutSessionIntent_isPaymentMethodOptionsSetupFutureUsageSet() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session"
            ],
            "ordered_payment_method_types_and_wallets": ["paypal"],
        ]).withCustomer()

        XCTAssertEqual(Intent.checkout(session.makePublicSession()).isPaymentMethodOptionsSetupFutureUsageSet, true)
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_resolved() {
        let session = CheckoutTestHelpers.makeSession([
            "ordered_payment_method_types_and_wallets": ["paypal"],
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session",
                "link": "off_session",
            ],
        ]).withCustomer()

        XCTAssertTrue(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_resolvedNone() {
        let session = CheckoutTestHelpers.makeSession([
            "ordered_payment_method_types_and_wallets": ["paypal"],
            "setup_future_usage_for_payment_method_type": [
                "paypal": "none",
                "link": "none",
            ],
        ]).withCustomer()

        XCTAssertEqual(session.makePublicSession().setupFutureUsage(for: .link), "none")
        XCTAssertFalse(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_perPaymentMethod() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "off_session"
            ],
            "ordered_payment_method_types_and_wallets": ["paypal"],
        ]).withCustomer()

        XCTAssertTrue(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    func testCheckoutSessionIntent_isSetupFutureUsageSet_perPaymentMethodNoneOverridesTopLevel() {
        let session = CheckoutTestHelpers.makeSession([
            "setup_future_usage_for_payment_method_type": [
                "paypal": "none"
            ],
            "ordered_payment_method_types_and_wallets": ["paypal"],
        ]).withCustomer()

        XCTAssertFalse(Intent.checkout(session.makePublicSession()).isSetupFutureUsageSet(for: .payPal))
    }

    // MARK: - Tax Tests

    func testTax_automaticComplete_isReady() {
        // Given automatic tax completed
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": [
                "enabled": true,
                "status": "ready",
            ],
        ]).withCustomer()

        // When creating the public Session
        let session = response.makePublicSession()

        // Then the public tax status is ready
        XCTAssertEqual(session.tax?.status, .ready)
    }

    func testTaxStatus_requiresAddress_usesAddressSource() {
        for (source, expected) in [
            ("shipping", CheckoutController.Session.Tax.Status.requiresShippingAddress),
            ("billing", .requiresBillingAddress),
        ] {
            let session = CheckoutTestHelpers.makeSession([
                "automatic_tax": ["enabled": true, "status": "requires_address", "address_source": source]
            ]).makePublicSession()
            XCTAssertEqual(session.tax?.status, expected)
        }
        let session = CheckoutTestHelpers.makeSession([
            "automatic_tax": ["enabled": true, "status": "requires_address"]
        ]).makePublicSession()
        XCTAssertNil(session.tax)
    }

    func testTax_automaticFailed_isNil() {
        // Given automatic tax failed
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": [
                "enabled": true,
                "status": "failed",
            ],
        ]).withCustomer()

        // When creating the public Session
        let session = response.makePublicSession()

        // Then the public Session has no tax state
        XCTAssertNil(session.tax)
    }

    func testTax_automaticUnsupportedStatus_isNil() {
        // Given automatic tax returns an unsupported status
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": [
                "enabled": true,
                "status": "future_status",
            ],
        ]).withCustomer()

        // When creating the public Session
        let session = response.makePublicSession()

        // Then the unknown status doesn't prevent the Session from decoding
        XCTAssertNil(session.tax)
    }

    func testTax_missingMetadata_isNil() {
        // Given a response without tax metadata
        let response = CheckoutTestHelpers.makeSession().withCustomer()

        // When creating the public Session
        let session = response.makePublicSession()

        // Then the public Session has no tax state
        XCTAssertNil(session.tax)
    }

    func testTax_missingEnabled_isRejected() {
        let json = CheckoutTestHelpers.makeSessionJSON(["automatic_tax": ["status": "ready"]])
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testDisabledAutomaticTax_isReady() {
        // Given automatic tax is disabled
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": [
                "enabled": false,
                "status": "ready",
            ],
        ]).withCustomer()

        // When creating the public Session
        let session = response.makePublicSession()

        // Then the public tax status is ready
        XCTAssertEqual(session.tax?.status, .ready)
    }

    func testUnknownAutomaticTaxStatus_isNil() {
        // Given a tax status added after this SDK version shipped
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": [
                "enabled": true,
                "status": "future_status",
            ],
        ]).withCustomer()

        // When creating the public Session
        let session = response.makePublicSession()

        // Then the SDK does not assume the tax calculation is ready
        XCTAssertNil(session.tax)
    }

    func testAutomaticTaxRejectsMalformedEnabled() {
        let json = CheckoutTestHelpers.makeSessionJSON(["automatic_tax": ["enabled": "invalid", "status": "ready"]])
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testShippingAddressCollectionRejectsMissingAllowedCountries() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "shipping_address_collection": [:] as [String: Any]
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    // MARK: - Elements Session Tests

    func testElementsSessionDecodesResolvedMobileLinkSettings() throws {
        for enabled in [true, false] {
            let popupOption: LinkSettings.PopupWebviewOption = enabled ? .ephemeral : .shared
            let json = CheckoutTestHelpers.makeSessionJSON([
                "link_settings": [
                    "link_funding_sources": ["CARD"],
                    "link_mode": "LINK_PAYMENT_METHOD",
                    "link_mobile_use_attestation_endpoints": enabled,
                    "link_mobile_attestation_state_sync_enabled": enabled,
                    "link_mobile_disable_signup": enabled,
                    "link_mobile_disable_rux_in_flow_controller": enabled,
                    "link_popup_webview_option": popupOption.rawValue,
                    "link_enable_displayable_default_values_in_ece": enabled,
                ],
            ])

            let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: json)
            let settings = try XCTUnwrap(response.makePublicSession().elementsSession.linkSettings)

            XCTAssertEqual(settings.useAttestationEndpoints, enabled)
            XCTAssertEqual(settings.attestationStateSyncEnabled, enabled)
            XCTAssertEqual(settings.disableSignup, enabled)
            XCTAssertEqual(settings.disableFlowControllerRUX, enabled)
            XCTAssertEqual(settings.popupWebviewOption, popupOption)
            XCTAssertEqual(settings.linkEnableDisplayableDefaultValuesInECE, enabled)
            XCTAssertEqual(settings.linkMode, .linkPaymentMethod)
        }
    }

    func testElementsSessionDecoding() {
        let session = CheckoutTestHelpers.makeSession([
            "checkout_session_config_id": "csc_123",
            "ordered_payment_method_types_and_wallets": ["card"],
            "elements_session_id": "es_123",
            "merchant_info": [
                "country": "US"
            ],
            "automatic_tax": [
                "enabled": true,
                "status": "ready",
                "address_source": "billing",
            ],
        ]).withCustomer().makePublicSession()
        XCTAssertEqual(session.checkoutConfigID, "csc_123")
        XCTAssertTrue(session.elementsSession.disableLinkForAutomaticTaxBilling)

        let sessionWithoutTax = CheckoutTestHelpers.makeSession([
            "ordered_payment_method_types_and_wallets": ["card"],
            "elements_session_id": "es_123",
            "merchant_info": [
                "country": "US"
            ],
        ]).withCustomer().makePublicSession()
        XCTAssertNil(sessionWithoutTax.checkoutConfigID)
        XCTAssertFalse(sessionWithoutTax.elementsSession.disableLinkForAutomaticTaxBilling)

        var jsonWithoutES = CheckoutTestHelpers.baseSessionJSON
        jsonWithoutES.removeValue(forKey: "elements_session_id")
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: jsonWithoutES))
    }

    private func modifyingCheckoutItem(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        var json = CheckoutTestHelpers.makeSessionJSON()
        var checkoutItems = json["items"] as! [[String: Any]]
        mutation(&checkoutItems[0])
        json["items"] = checkoutItems
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

    private func modifyingAmountDetails(
        _ mutation: (inout [String: Any]) -> Void
    ) -> [String: Any] {
        modifyingOneTimePriceItem { item in
            var amountDetails = item["amount_details"] as! [String: Any]
            mutation(&amountDetails)
            item["amount_details"] = amountDetails
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
        var amountDetails = item["amount_details"] as! [String: Any]
        amountDetails["subtotal"] = subtotal
        amountDetails["total"] = total
        item["unit_amount"] = subtotal
        item["unit_amount_decimal"] = String(subtotal)
        amountDetails["tax_exclusive"] = taxExclusive
        amountDetails["tax_inclusive"] = taxInclusive
        item["amount_details"] = amountDetails
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

//
//  STPPaymentIntentTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentIntentTest: XCTestCase {
    func testIdentifierFromSecret() {
        XCTAssertEqual(
            STPPaymentIntent.id(fromClientSecret: "pi_123_secret_XYZ"),
            "pi_123"
        )
        XCTAssertEqual(
            STPPaymentIntent.id(
                fromClientSecret: "pi_123_secret_RandomlyContains_secret_WhichIsFine"
            ),
            "pi_123"
        )
        XCTAssertEqual(
            STPPaymentIntent.id(fromClientSecret: "pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
            "pi_1CkiBMLENEVhOs7YMtUehLau"
        )

        // Test scoped client secrets
        XCTAssertEqual(
            STPPaymentIntent.id(fromClientSecret: "pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6"),
            "pi_3RddVUHh8VvNDQ8j1CFgLC0y"
        )
        XCTAssertEqual(
            STPPaymentIntent.id(fromClientSecret: "pi_1CkiBMLENEVhOs7YMtUehLau_scoped_secret_s4O8SDh7s6spSmHDw1VaYPGZA"),
            "pi_1CkiBMLENEVhOs7YMtUehLau"
        )

        XCTAssertNil(STPPaymentIntent.id(fromClientSecret: ""))
        XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "po_123_secret_HasBadPrefix"))
        XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "MissingSentinalForSplitting"))
        XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "pi_123_scoped_secret_"))
    }

    // MARK: - Description Tests
    func testDescription() {
        let paymentIntent = STPFixtures.paymentIntent()

        XCTAssertNotNil(paymentIntent)
        let desc = paymentIntent.description
        XCTAssertTrue(desc.contains(NSStringFromClass(type(of: paymentIntent).self)))
        XCTAssertGreaterThan((desc.count), 500, "Custom description should be long")
    }

    // MARK: - STPAPIResponseDecodable Tests
    func testDecodedObjectFromAPIResponseRequiredFields() {
        let fullJson = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)

        XCTAssertNotNil(
            STPPaymentIntent.decodedObject(fromAPIResponse: fullJson),
            "can decode with full json"
        )

        // Only id and status are truly required fields - all others can be missing in redacted responses
        let requiredFields = ["id", "status"]

        for field in requiredFields {
            var partialJson = fullJson

            XCTAssertNotNil(partialJson?[field])
            partialJson?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentIntent.decodedObject(fromAPIResponse: partialJson))
        }

        // Test that other previously "required" fields now work with placeholders when missing
        let fieldsWithPlaceholders = ["client_secret", "amount", "currency", "livemode"]

        for field in fieldsWithPlaceholders {
            var partialJson = fullJson

            XCTAssertNotNil(partialJson?[field])
            partialJson?.removeValue(forKey: field)

            let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: partialJson)
            XCTAssertNotNil(paymentIntent, "Should decode even without \(field)")

            // Verify it's marked as redacted when these fields are missing
            if field == "amount" || field == "currency" || field == "client_secret" {
                XCTAssertTrue(paymentIntent?.isRedacted ?? false, "Should be marked as redacted when \(field) is missing")
            }
        }
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let paymentIntentJson = STPTestUtils.jsonNamed("PaymentIntent")!
        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJson)!

        XCTAssertEqual(paymentIntent.stripeId, "pi_1Cl15wIl4IdHmuTbCWrpJXN6")
        XCTAssertEqual(
            paymentIntent.clientSecret,
            "pi_1Cl15wIl4IdHmuTbCWrpJXN6_secret_EkKtQ7Sg75hLDFKqFG8DtWcaK"
        )
        XCTAssertEqual(paymentIntent.amount, 2345)
        XCTAssertEqual(paymentIntent.canceledAt, Date(timeIntervalSince1970: 1_530_911_045))
        XCTAssertEqual(paymentIntent.captureMethod, .manual)
        XCTAssertEqual(paymentIntent.confirmationMethod, .automatic)
        XCTAssertEqual(paymentIntent.created, Date(timeIntervalSince1970: 1_530_911_040))
        XCTAssertEqual(paymentIntent.currency, "usd")
        XCTAssertEqual(paymentIntent.stripeDescription, "My Sample PaymentIntent")
        XCTAssertFalse(paymentIntent.livemode)
        XCTAssertEqual(paymentIntent.receiptEmail, "danj@example.com")

        // Deprecated: `nextSourceAction` & `authorizeWithURL` should just be aliases for `nextAction` & `redirectToURL`
        // #pragma clang diagnostic push
        // #pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertEqual(
            paymentIntent.nextAction,
            paymentIntent.nextAction,
            "Should be the same object."
        )
        XCTAssertEqual(
            paymentIntent.nextAction!.redirectToURL!,
            paymentIntent.nextAction!.redirectToURL,
            "Should be the same object."
        )
        // #pragma clang diagnostic pop

        // nextAction
        XCTAssertNotNil(paymentIntent.nextAction)
        XCTAssertEqual(paymentIntent.nextAction!.type, .redirectToURL)
        XCTAssertNotNil(paymentIntent.nextAction!.redirectToURL)
        XCTAssertNotNil(paymentIntent.nextAction!.redirectToURL!.url)
        let returnURL = paymentIntent.nextAction!.redirectToURL!.returnURL
        XCTAssertNotNil(returnURL)
        XCTAssertEqual(returnURL, URL(string: "payments-example://stripe-redirect"))
        let url = paymentIntent.nextAction!.redirectToURL!.url
        XCTAssertNotNil(url)

        XCTAssertEqual(
            url,
            URL(
                string:
                    "https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk"
            )
        )
        XCTAssertEqual(paymentIntent.sourceId, "src_1Cl1AdIl4IdHmuTbseiDWq6m")
        XCTAssertEqual(paymentIntent.status, .requiresAction)
        XCTAssertEqual(paymentIntent.setupFutureUsage, .none)

        XCTAssertEqual(
            paymentIntent.paymentMethodTypes,
            [NSNumber(value: STPPaymentMethodType.card.rawValue)]
        )

        // lastPaymentError

        XCTAssertNotNil(paymentIntent.lastPaymentError)
        XCTAssertEqual(
            paymentIntent.lastPaymentError!.code,
            "payment_intent_authentication_failure"
        )
        XCTAssertEqual(
            paymentIntent.lastPaymentError!.docURL,
            "https://stripe.com/docs/error-codes#payment-intent-authentication-failure"
        )
        XCTAssertEqual(
            paymentIntent.lastPaymentError!.message,
            "The provided PaymentMethod has failed authentication. You can provide payment_method_data or a new PaymentMethod to attempt to fulfill this PaymentIntent again."
        )
        XCTAssertNotNil(paymentIntent.lastPaymentError!.paymentMethod)
        XCTAssertEqual(paymentIntent.lastPaymentError!.type, .invalidRequest)

        // Shipping
        XCTAssertNotNil(paymentIntent.shipping)
        XCTAssertEqual(paymentIntent.shipping!.carrier, "USPS")
        XCTAssertEqual(paymentIntent.shipping!.name, "Dan")
        XCTAssertEqual(paymentIntent.shipping!.phone, "1-415-555-1234")
        XCTAssertEqual(paymentIntent.shipping!.trackingNumber, "xyz123abc")
        XCTAssertNotNil(paymentIntent.shipping!.address)
        XCTAssertEqual(paymentIntent.shipping!.address!.city, "San Francisco")
        XCTAssertEqual(paymentIntent.shipping!.address!.country, "USA")
        XCTAssertEqual(paymentIntent.shipping!.address!.line1, "123 Main St")
        XCTAssertEqual(paymentIntent.shipping!.address!.line2, "Apt 456")
        XCTAssertEqual(paymentIntent.shipping!.address!.postalCode, "94107")
        XCTAssertEqual(paymentIntent.shipping!.address!.state, "CA")

        XCTAssertEqual(
            paymentIntent.allResponseFields as NSDictionary,
            paymentIntentJson as NSDictionary
        )

        // Test that this is NOT a redacted PaymentIntent
        XCTAssertFalse(paymentIntent.isRedacted)
    }

    // MARK: - Redacted PaymentIntent Tests
    func testDecodedObjectFromRedactedAPIResponse() {
        // Create a redacted PaymentIntent response (as returned when using scoped client secret)
        let redactedResponse: [String: Any] = [
            "id": "pi_3RddVUHh8VvNDQ8j1CFgLC0y",
            "object": "payment_intent",
            "status": "requires_payment_method",
            "livemode": false,
            "created": 1735000000,
            // These fields are nil/missing in redacted responses:
            // "amount": nil,
            // "currency": nil,
            // "client_secret": nil,
            // "payment_method_types": nil
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: redactedResponse)

        XCTAssertNotNil(paymentIntent, "Should successfully decode redacted PaymentIntent")
        XCTAssertEqual(paymentIntent?.stripeId, "pi_3RddVUHh8VvNDQ8j1CFgLC0y")
        XCTAssertEqual(paymentIntent?.status, .requiresPaymentMethod)
        XCTAssertFalse(paymentIntent?.livemode ?? true)

        // Check placeholder values
        XCTAssertEqual(paymentIntent?.amount, -1, "Should use -1 as placeholder for amount")
        XCTAssertEqual(paymentIntent?.currency, "unknown", "Should use 'unknown' as placeholder for currency")
        XCTAssertEqual(paymentIntent?.clientSecret, "redacted_client_secret", "Should use 'redacted_client_secret' as placeholder for client_secret")
        XCTAssertEqual(paymentIntent?.paymentMethodTypes, [], "Should use empty array for payment_method_types")

        // Verify isRedacted returns true
        XCTAssertTrue(paymentIntent?.isRedacted ?? false, "Should identify as redacted PaymentIntent")
    }

    func testDecodedObjectFromPartiallyRedactedAPIResponse() {
        // Test case where some fields are present but others are redacted
        let partialResponse: [String: Any] = [
            "id": "pi_test123",
            "object": "payment_intent",
            "status": "succeeded",
            "livemode": true,
            "created": 1735000000,
            "amount": 1000,
            // Missing: currency, client_secret, payment_method_types
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: partialResponse)

        XCTAssertNotNil(paymentIntent, "Should successfully decode partially redacted PaymentIntent")
        XCTAssertEqual(paymentIntent?.amount, 1000, "Should use actual amount value")
        XCTAssertEqual(paymentIntent?.currency, "unknown", "Should use placeholder for missing currency")
        XCTAssertTrue(paymentIntent?.isRedacted ?? false, "Should identify as redacted due to missing fields")
    }

    func testDecodedObjectFailsWithMissingRequiredFields() {
        // Test that we still fail if truly required fields are missing
        let invalidResponse: [String: Any] = [
            // Missing id and status - these are always required
            "amount": 1000,
            "currency": "usd",
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: invalidResponse)
        XCTAssertNil(paymentIntent, "Should fail to decode without id and status")
    }

    // MARK: - Additional Redacted PaymentIntent Tests

    func testIsRedactedProperty() {
        // Test non-redacted PaymentIntent
        let normalPI = STPFixtures.paymentIntent()
        XCTAssertFalse(normalPI.isRedacted, "Normal PaymentIntent should not be redacted")

        // Test redacted PaymentIntent with -1 amount
        let redactedResponse1: [String: Any] = [
            "id": "pi_test1",
            "object": "payment_intent",
            "status": "requires_payment_method",
            "livemode": false,
        ]
        let redactedPI1 = STPPaymentIntent.decodedObject(fromAPIResponse: redactedResponse1)!
        XCTAssertTrue(redactedPI1.isRedacted, "Should be redacted when amount is -1")

        // Test redacted PaymentIntent with "unknown" currency
        let redactedResponse2: [String: Any] = [
            "id": "pi_test2",
            "object": "payment_intent",
            "status": "requires_payment_method",
            "amount": 1000,
            "livemode": false,
        ]
        let redactedPI2 = STPPaymentIntent.decodedObject(fromAPIResponse: redactedResponse2)!
        XCTAssertTrue(redactedPI2.isRedacted, "Should be redacted when currency is 'unknown'")

        // Test redacted PaymentIntent with "redacted" client_secret
        let redactedResponse3: [String: Any] = [
            "id": "pi_test3",
            "object": "payment_intent",
            "status": "requires_payment_method",
            "amount": 1000,
            "currency": "usd",
            "payment_method_types": ["card"],
            "livemode": false,
        ]
        let redactedPI3 = STPPaymentIntent.decodedObject(fromAPIResponse: redactedResponse3)!
        XCTAssertTrue(redactedPI3.isRedacted, "Should be redacted when client_secret is 'redacted'")
    }

    func testRedactedPaymentIntentWithOptionalFields() {
        // Test that optional fields work correctly with redacted PaymentIntents
        let redactedResponse: [String: Any] = [
            "id": "pi_redacted_optional",
            "object": "payment_intent",
            "status": "succeeded",
            "livemode": true,
            "created": 1735000000,
            // Missing required fields that trigger redaction
            // But including some optional fields
            "description": "Test payment",
            "receipt_email": "test@example.com",
            "metadata": ["key": "value"],
            "setup_future_usage": "off_session",
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: redactedResponse)

        XCTAssertNotNil(paymentIntent)
        XCTAssertTrue(paymentIntent!.isRedacted)

        // Verify optional fields are preserved
        XCTAssertEqual(paymentIntent?.stripeDescription, "Test payment")
        XCTAssertEqual(paymentIntent?.receiptEmail, "test@example.com")
        XCTAssertEqual(paymentIntent?.setupFutureUsage, .offSession)

        // Verify placeholder values
        XCTAssertEqual(paymentIntent?.amount, -1)
        XCTAssertEqual(paymentIntent?.currency, "unknown")
        XCTAssertEqual(paymentIntent?.clientSecret, "redacted_client_secret")
    }

    func testRedactedPaymentIntentAllFieldsMissing() {
        // Test extreme case where all optional fields are missing
        let minimalResponse: [String: Any] = [
            "id": "pi_minimal",
            "object": "payment_intent",
            "status": "requires_payment_method",
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: minimalResponse)

        XCTAssertNotNil(paymentIntent, "Should decode with minimal fields")
        XCTAssertTrue(paymentIntent!.isRedacted)

        // Check all placeholder values
        XCTAssertEqual(paymentIntent?.amount, -1)
        XCTAssertEqual(paymentIntent?.currency, "unknown")
        XCTAssertEqual(paymentIntent?.clientSecret, "redacted_client_secret")
        XCTAssertEqual(paymentIntent?.paymentMethodTypes, [])
        XCTAssertFalse(paymentIntent?.livemode ?? true)

        // Check optional fields are nil
        XCTAssertNil(paymentIntent?.stripeDescription)
        XCTAssertNil(paymentIntent?.receiptEmail)
        XCTAssertNil(paymentIntent?.shipping)
        XCTAssertNil(paymentIntent?.paymentMethod)
        XCTAssertNil(paymentIntent?.lastPaymentError)
    }

    func testRedactedPaymentIntentWithNextAction() {
        // Test that redacted PaymentIntents can still have next actions
        let redactedWithAction: [String: Any] = [
            "id": "pi_action",
            "object": "payment_intent",
            "status": "requires_action",
            "next_action": [
                "type": "redirect_to_url",
                "redirect_to_url": [
                    "url": "https://example.com/redirect",
                    "return_url": "app://return",
                ],
            ],
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: redactedWithAction)

        XCTAssertNotNil(paymentIntent)
        XCTAssertTrue(paymentIntent!.isRedacted)
        XCTAssertEqual(paymentIntent?.status, .requiresAction)

        // Verify next action is preserved
        XCTAssertNotNil(paymentIntent?.nextAction)
        XCTAssertEqual(paymentIntent?.nextAction?.type, .redirectToURL)
        XCTAssertNotNil(paymentIntent?.nextAction?.redirectToURL)
        XCTAssertEqual(paymentIntent?.nextAction?.redirectToURL?.url.absoluteString, "https://example.com/redirect")
    }

    func testRedactedPaymentIntentWithPaymentMethod() {
        // Test redacted PI with expanded payment method
        let redactedWithPM: [String: Any] = [
            "id": "pi_with_pm",
            "object": "payment_intent",
            "status": "succeeded",
            "payment_method": [
                "id": "pm_test123",
                "created": "1753466748",
                "object": "payment_method",
                "type": "card",
                "card": [
                    "brand": "visa",
                    "last4": "4242",
                    "exp_month": 12,
                    "exp_year": 2025,
                ],
            ],
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: redactedWithPM)

        XCTAssertNotNil(paymentIntent)
        XCTAssertTrue(paymentIntent!.isRedacted)

        // Verify payment method is preserved
        XCTAssertNotNil(paymentIntent?.paymentMethod)
        XCTAssertEqual(paymentIntent?.paymentMethod?.stripeId, "pm_test123")
        XCTAssertEqual(paymentIntent?.paymentMethod?.type, .card)
        XCTAssertEqual(paymentIntent?.paymentMethod?.card?.brand, .visa)
        XCTAssertEqual(paymentIntent?.paymentMethod?.card?.last4, "4242")
    }

    func testMixedRedactedFields() {
        // Test various combinations of missing fields
        let testCases: [(name: String, response: [String: Any], expectedRedacted: Bool)] = [
            (
                name: "Only amount missing",
                response: [
                    "id": "pi_1",
                    "status": "requires_payment_method",
                    "currency": "usd",
                    "client_secret": "pi_1_secret_xyz",
                    "payment_method_types": ["card"],
                ],
                expectedRedacted: true
            ),
            (
                name: "Only currency missing",
                response: [
                    "id": "pi_2",
                    "status": "requires_payment_method",
                    "amount": 1000,
                    "client_secret": "pi_2_secret_xyz",
                    "payment_method_types": ["card"],
                ],
                expectedRedacted: true
            ),
            (
                name: "Only payment_method_types missing",
                response: [
                    "id": "pi_3",
                    "status": "requires_payment_method",
                    "amount": 1000,
                    "currency": "usd",
                    "client_secret": "pi_3_secret_xyz",
                ],
                expectedRedacted: true
            ),
            (
                name: "All fields present",
                response: [
                    "id": "pi_4",
                    "status": "requires_payment_method",
                    "amount": 1000,
                    "currency": "usd",
                    "client_secret": "pi_4_secret_xyz",
                    "payment_method_types": ["card"],
                ],
                expectedRedacted: false
            ),
        ]

        for testCase in testCases {
            let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: testCase.response)
            XCTAssertNotNil(paymentIntent, "Failed to decode: \(testCase.name)")
            XCTAssertEqual(
                paymentIntent!.isRedacted,
                testCase.expectedRedacted,
                "Incorrect redaction status for: \(testCase.name)"
            )
        }
    }

    func testScopedSecretWithRedactedPaymentIntent() {
        // Test realistic scenario: scoped client secret with redacted response
        let scopedSecretResponse: [String: Any] = [
            "id": "pi_3RddVUHh8VvNDQ8j1CFgLC0y",
            "object": "payment_intent",
            "status": "requires_payment_method",
            "livemode": false,
            "created": 1735000000,
            // Note: When using scoped secrets, these fields are typically nil/missing
            // "amount": nil,
            // "currency": nil,
            // "client_secret": nil,
            // "payment_method_types": nil,
            // But might include some other fields
            "metadata": ["order_id": "12345"],
            "description": "Order #12345",
        ]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: scopedSecretResponse)

        XCTAssertNotNil(paymentIntent, "Should decode redacted PI from scoped secret response")
        XCTAssertTrue(paymentIntent!.isRedacted, "Should be marked as redacted")

        // Verify we can still extract ID from a scoped secret
        let scopedSecret = "pi_3RddVUHh8VvNDQ8j1CFgLC0y_scoped_secret_JouqJt9ahCKgh6B9r6"
        let extractedId = STPPaymentIntent.id(fromClientSecret: scopedSecret)
        XCTAssertEqual(extractedId, "pi_3RddVUHh8VvNDQ8j1CFgLC0y")
        XCTAssertEqual(extractedId, paymentIntent?.stripeId)

        // Verify metadata and description are preserved
        XCTAssertEqual(paymentIntent?.stripeDescription, "Order #12345")
        XCTAssertEqual((paymentIntent?.allResponseFields["metadata"] as? [String: String])?["order_id"], "12345")
    }

    func testRedactedPaymentIntentConsistency() {
        // Test that all ways of creating a redacted PI result in isRedacted = true
        let testCases: [[String: Any]] = [
            // Missing all redactable fields
            [
                "id": "pi_all_missing",
                "status": "requires_payment_method",
            ],
            // Missing just amount
            [
                "id": "pi_no_amount",
                "status": "requires_payment_method",
                "currency": "usd",
                "client_secret": "pi_no_amount_secret_xyz",
                "payment_method_types": ["card"],
            ],
            // Missing just currency
            [
                "id": "pi_no_currency",
                "status": "requires_payment_method",
                "amount": 1000,
                "client_secret": "pi_no_currency_secret_xyz",
                "payment_method_types": ["card"],
            ],
            // Missing just client_secret
            [
                "id": "pi_no_secret",
                "status": "requires_payment_method",
                "amount": 1000,
                "currency": "usd",
                "payment_method_types": ["card"],
            ],
            // Missing just payment_method_types
            [
                "id": "pi_no_pmts",
                "status": "requires_payment_method",
                "amount": 1000,
                "currency": "usd",
                "client_secret": "pi_no_pmts_secret_xyz",
            ],
        ]

        for testCase in testCases {
            let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: testCase)
            XCTAssertNotNil(paymentIntent, "Failed to decode PI with id: \(testCase["id"] ?? "unknown")")
            XCTAssertTrue(paymentIntent!.isRedacted, "PI should be redacted: \(testCase["id"] ?? "unknown")")

            // Verify placeholder values are used appropriately
            if testCase["amount"] == nil {
                XCTAssertEqual(paymentIntent?.amount, -1)
            }
            if testCase["currency"] == nil {
                XCTAssertEqual(paymentIntent?.currency, "unknown")
            }
            if testCase["client_secret"] == nil {
                XCTAssertEqual(paymentIntent?.clientSecret, "redacted_client_secret")
            }
            if testCase["payment_method_types"] == nil {
                XCTAssertEqual(paymentIntent?.paymentMethodTypes, [])
            }
        }
    }
}

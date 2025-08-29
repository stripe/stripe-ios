//
//  STPConfirmationTokenTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments

class STPConfirmationTokenTest: XCTestCase {

    // MARK: - Description
    func testDescription() {
        let confirmationToken = STPConfirmationToken(
            stripeId: "ct_1234567890",
            object: "confirmation_token",
            created: Date(),
            expiresAt: nil,
            liveMode: false,
            mandateData: nil,
            paymentIntentId: nil,
            setupIntentId: nil,
            paymentMethodOptions: nil,
            paymentMethodPreview: nil,
            returnURL: nil,
            setupFutureUsage: .none,
            shipping: nil,
            useStripeSDK: true,
            allResponseFields: [:]
        )

        XCTAssertNotNil(confirmationToken.description)
        XCTAssertTrue(confirmationToken.description.contains("ct_1234567890"))
        XCTAssertTrue(confirmationToken.description.contains("confirmation_token"))
    }

    // MARK: - STPAPIResponseDecodable Tests
    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "id": "ct_1234567890",
            "object": "confirmation_token",
            "created": 1234567890,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: requiredFields)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken!.stripeId, "ct_1234567890")
        XCTAssertEqual(confirmationToken!.object, "confirmation_token")
        XCTAssertEqual(confirmationToken!.created.timeIntervalSince1970, 1234567890)
    }

    func testDecodedObjectFromAPIResponseAllFields() {
        let allFields: [String: Any] = [
            "id": "ct_1234567890",
            "object": "confirmation_token",
            "created": 1234567890,
            "expires_at": 1234567890 + 3600,
            "livemode": true,
            "payment_intent": "pi_1234567890",
            "setup_intent": "seti_1234567890",
            "return_url": "https://example.com/return",
            "setup_future_usage": "off_session",
            "use_stripe_sdk": false,
            "payment_method": "pm_1234567890",
            "mandate_data": [
                "customer_acceptance": [
                    "type": "online",
                    "online": [
                        "ip_address": "127.0.0.1",
                        "user_agent": "Test User Agent",
                    ],
                ],
            ],
            "payment_method_options": [
                "card": [
                    "cvc_token": "cvctok_1234567890"
                ],
            ],
            "payment_method_preview": [
                "type": "card",
                "card": [
                    "brand": "visa",
                    "last4": "4242",
                ],
            ],
        ]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: allFields)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken!.stripeId, "ct_1234567890")
        XCTAssertEqual(confirmationToken!.object, "confirmation_token")
        XCTAssertEqual(confirmationToken!.created.timeIntervalSince1970, 1234567890)
        XCTAssertEqual(confirmationToken!.expiresAt?.timeIntervalSince1970, 1234567890 + 3600)
        XCTAssertTrue(confirmationToken!.liveMode)
        XCTAssertEqual(confirmationToken!.paymentIntentId, "pi_1234567890")
        XCTAssertEqual(confirmationToken!.setupIntentId, "seti_1234567890")
        XCTAssertEqual(confirmationToken!.returnURL, "https://example.com/return")
        XCTAssertEqual(confirmationToken!.setupFutureUsage, .offSession)
        XCTAssertFalse(confirmationToken!.useStripeSDK)
        XCTAssertNotNil(confirmationToken!.mandateData)
        XCTAssertNotNil(confirmationToken!.paymentMethodOptions)
        XCTAssertNotNil(confirmationToken!.paymentMethodPreview)
    }

    func testDecodedObjectFromAPIResponseMissingId() {
        let incompleteFields = [
            "object": "confirmation_token",
            "created": 1234567890,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: incompleteFields)
        XCTAssertNil(confirmationToken)
    }

    func testDecodedObjectFromAPIResponseMissingObject() {
        let incompleteFields = [
            "id": "ct_1234567890",
            "created": 1234567890,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: incompleteFields)
        XCTAssertNil(confirmationToken)
    }

    func testDecodedObjectFromAPIResponseMissingCreated() {
        let incompleteFields = [
            "id": "ct_1234567890",
            "object": "confirmation_token",
        ]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: incompleteFields)
        XCTAssertNil(confirmationToken)
    }

    func testDecodedObjectFromAPIResponseInvalidCreated() {
        let incompleteFields = [
            "id": "ct_1234567890",
            "object": "confirmation_token",
            "created": "invalid_timestamp",
        ]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: incompleteFields)
        XCTAssertNil(confirmationToken)
    }

    // MARK: - Nested Types Tests
    func testMandateDataDecoding() {
        let mandateDataDict: [String: Any] = [
            "customer_acceptance": [
                "type": "online",
                "online": [
                    "ip_address": "127.0.0.1",
                    "user_agent": "Test User Agent",
                ],
            ],
        ]

        let mandateData = STPConfirmationToken.MandateData.decodedObject(fromAPIResponse: mandateDataDict)

        XCTAssertNotNil(mandateData)
        XCTAssertEqual(mandateData!.customerAcceptance.type, "online")
        XCTAssertNotNil(mandateData!.customerAcceptance.online)
        XCTAssertEqual(mandateData!.customerAcceptance.online!.ipAddress, "127.0.0.1")
        XCTAssertEqual(mandateData!.customerAcceptance.online!.userAgent, "Test User Agent")
    }

    func testPaymentMethodOptionsDecoding() {
        let paymentMethodOptionsDict: [String: Any] = [
            "card": [
                "cvc_token": "cvctok_1234567890",
                "installments": [
                    "plan": [
                        "count": 3,
                        "interval": "month",
                        "type": "fixed_count",
                    ],
                ],
            ],
        ]

        let paymentMethodOptions = STPConfirmationToken.PaymentMethodOptions.decodedObject(fromAPIResponse: paymentMethodOptionsDict)

        XCTAssertNotNil(paymentMethodOptions)
        XCTAssertNotNil(paymentMethodOptions!.card)
        XCTAssertEqual(paymentMethodOptions!.card!.cvcToken, "cvctok_1234567890")
        XCTAssertNotNil(paymentMethodOptions!.card!.installments)
        XCTAssertNotNil(paymentMethodOptions!.card!.installments!.plan)
        XCTAssertEqual(paymentMethodOptions!.card!.installments!.plan!.count, 3)
        XCTAssertEqual(paymentMethodOptions!.card!.installments!.plan!.interval, .month)
        XCTAssertEqual(paymentMethodOptions!.card!.installments!.plan!.type, .fixedCount)
    }

    func testPaymentMethodPreviewDecoding() {
        let paymentMethodPreviewDict: [String: Any] = [
            "type": "card",
            "card": [
                "brand": "visa",
                "last4": "4242",
            ],
            "billing_details": [
                "address": [
                    "country": "US"
                ],
            ],
        ]

        let paymentMethodPreview = STPConfirmationToken.PaymentMethodPreview.decodedObject(fromAPIResponse: paymentMethodPreviewDict)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview!.type, .card)
        XCTAssertNotNil(paymentMethodPreview!.billingDetails)
        XCTAssertNotNil(paymentMethodPreview!.card)

        let cardDetails = paymentMethodPreview!.card
        XCTAssertNotNil(cardDetails)
        XCTAssertEqual(cardDetails?.brand, .visa)
        XCTAssertEqual(cardDetails?.last4, "4242")
    }

    // MARK: - Edge Cases
    func testEmptyResponse() {
        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: [:])
        XCTAssertNil(confirmationToken)
    }

    func testNilResponse() {
        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: nil)
        XCTAssertNil(confirmationToken)
    }

    // MARK: - API Client Tests
    func testCreateConfirmationTokenMethodSignature() {
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let paymentMethodParams = STPPaymentMethodParams(card: STPPaymentMethodCardParams(), billingDetails: nil, metadata: nil)
        let confirmationTokenParams = STPConfirmationTokenParams(paymentMethodData: paymentMethodParams)

        // Test that the method exists and can be called (we won't actually make the network request)
        let expectation = self.expectation(description: "Create ConfirmationToken method exists")
        expectation.isInverted = true // We expect this NOT to be fulfilled since we won't make the actual call

        apiClient.createConfirmationToken(with: confirmationTokenParams) { _, _ in
            // This should not be called in unit tests
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }
}

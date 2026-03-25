//
//  STPConfirmationTokenTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/4/25.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

class STPConfirmationTokenTest: XCTestCase {

    func testConfirmationTokenParsing() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "expires_at": 1694068225,
            "livemode": true,
            "payment_intent": "pi_1234567890",
            "setup_intent": "seti_1234567890",
            "return_url": "https://example.com/return",
            "setup_future_usage": "off_session",
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken?.stripeId, "ctoken_1NnQUf2eZvKYlo2CIObdtbnb")
        XCTAssertTrue(confirmationToken?.liveMode ?? false)
        XCTAssertEqual(confirmationToken?.created, Date(timeIntervalSince1970: 1694025025))
        XCTAssertEqual(confirmationToken?.expiresAt, Date(timeIntervalSince1970: 1694068225))
        XCTAssertEqual(confirmationToken?.paymentIntentId, "pi_1234567890")
        XCTAssertEqual(confirmationToken?.setupIntentId, "seti_1234567890")
        XCTAssertEqual(confirmationToken?.returnURL, "https://example.com/return")
        XCTAssertEqual(confirmationToken?.setupFutureUsage, .offSession)
    }

    func testConfirmationTokenWithNullableFields() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "expires_at": NSNull(),
            "payment_intent": NSNull(),
            "setup_intent": NSNull(),
            "return_url": NSNull(),
            "setup_future_usage": NSNull(),
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken?.stripeId, "ctoken_1NnQUf2eZvKYlo2CIObdtbnb")
        XCTAssertFalse(confirmationToken?.liveMode ?? true)
        XCTAssertEqual(confirmationToken?.created, Date(timeIntervalSince1970: 1694025025))
        XCTAssertNil(confirmationToken?.expiresAt)
        XCTAssertNil(confirmationToken?.paymentIntentId)
        XCTAssertNil(confirmationToken?.setupIntentId)
        XCTAssertNil(confirmationToken?.returnURL)
        XCTAssertNil(confirmationToken?.setupFutureUsage)
    }

    func testConfirmationTokenWithPaymentMethodPreview() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_preview": [
                "type": "card",
                "billing_details": [
                    "name": "John Doe",
                    "email": "john@example.com",
                ],
                "allow_redisplay": "always",
                "customer": "cus_1234567890",
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken?.stripeId, "ctoken_1NnQUf2eZvKYlo2CIObdtbnb")

        let paymentMethodPreview = confirmationToken?.paymentMethodPreview
        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .card)
        XCTAssertEqual(paymentMethodPreview?.billingDetails?.name, "John Doe")
        XCTAssertEqual(paymentMethodPreview?.billingDetails?.email, "john@example.com")
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .always)
        XCTAssertEqual(paymentMethodPreview?.customerId, "cus_1234567890")
    }

    func testConfirmationTokenWithPaymentMethodPreviewCard() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_preview": [
                "type": "card",
                "billing_details": [
                    "name": "John Doe",
                    "email": "john@example.com",
                ],
                "card": [
                    "brand": "visa",
                    "country": "US",
                    "exp_month": 12,
                    "exp_year": 2030,
                    "funding": "credit",
                    "last4": "4242",
                    "display_brand": "visa",
                ],
                "allow_redisplay": "always",
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken?.stripeId, "ctoken_1NnQUf2eZvKYlo2CIObdtbnb")

        let paymentMethodPreview = confirmationToken?.paymentMethodPreview
        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .card)

        // Test card fields
        let card = paymentMethodPreview?.card
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.brand, .visa)
        XCTAssertEqual(card?.country, "US")
        XCTAssertEqual(card?.expMonth, 12)
        XCTAssertEqual(card?.expYear, 2030)
        XCTAssertEqual(card?.funding, "credit")
        XCTAssertEqual(card?.last4, "4242")
        XCTAssertEqual(card?.displayBrand, "visa")
    }

    func testConfirmationTokenWithShippingDetails() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "shipping": [
                "name": "John Doe",
                "address": [
                    "line1": "123 Main St",
                    "city": "San Francisco",
                    "state": "CA",
                    "postal_code": "94111",
                    "country": "US",
                ],
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken?.stripeId, "ctoken_1NnQUf2eZvKYlo2CIObdtbnb")

        let shipping = confirmationToken?.shipping
        XCTAssertNotNil(shipping)
        XCTAssertEqual(shipping?.name, "John Doe")
        XCTAssertEqual(shipping?.address?.line1, "123 Main St")
        XCTAssertEqual(shipping?.address?.city, "San Francisco")
        XCTAssertEqual(shipping?.address?.state, "CA")
        XCTAssertEqual(shipping?.address?.postalCode, "94111")
        XCTAssertEqual(shipping?.address?.country, "US")
    }

    // MARK: - Required Field Validation Tests

    func testConfirmationTokenRequiresId() {
        let jsonWithoutId = [
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: jsonWithoutId)
        XCTAssertNil(confirmationToken, "decodedObject should return nil when 'id' field is missing")
    }

    func testConfirmationTokenRequiresIdNotNull() {
        let jsonWithNullId = [
            "id": NSNull(),
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: jsonWithNullId)
        XCTAssertNil(confirmationToken, "decodedObject should return nil when 'id' field is null")
    }

    func testConfirmationTokenRequiresIdNotEmpty() {
        let jsonWithEmptyId = [
            "id": "",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: jsonWithEmptyId)
        XCTAssertNil(confirmationToken, "decodedObject should return nil when 'id' field is empty string")
    }

    func testConfirmationTokenRequiresCreated() {
        let jsonWithoutCreated = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "livemode": false,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: jsonWithoutCreated)
        XCTAssertNil(confirmationToken, "decodedObject should return nil when 'created' field is missing")
    }

    func testConfirmationTokenRequiresCreatedNotNull() {
        let jsonWithNullCreated = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": NSNull(),
            "livemode": false,
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: jsonWithNullCreated)
        XCTAssertNil(confirmationToken, "decodedObject should return nil when 'created' field is null")
    }

    // MARK: - New Initializer Tests

    func testConfirmationTokenInitializer() {
        let stripeId = "ctoken_1NnQUf2eZvKYlo2CIObdtbnb"
        let createdDate = Date(timeIntervalSince1970: 1694025025)

        let confirmationToken = STPConfirmationToken(stripeId: stripeId, created: createdDate)

        XCTAssertEqual(confirmationToken.stripeId, stripeId)
        XCTAssertEqual(confirmationToken.created, createdDate)
        XCTAssertFalse(confirmationToken.liveMode)
        XCTAssertNil(confirmationToken.expiresAt)
        XCTAssertNil(confirmationToken.paymentIntentId)
        XCTAssertNil(confirmationToken.setupIntentId)
        XCTAssertNil(confirmationToken.returnURL)
        XCTAssertNil(confirmationToken.setupFutureUsage)
    }

    // MARK: - Comprehensive Field Tests

    func testConfirmationTokenWithAllFields() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "expires_at": 1694068225,
            "livemode": true,
            "payment_intent": "pi_1234567890",
            "setup_intent": "seti_1234567890",
            "return_url": "https://example.com/return",
            "setup_future_usage": "off_session",
            "payment_method_preview": [
                "type": "card",
                "billing_details": [
                    "name": "John Doe",
                    "email": "john@example.com",
                ],
                "allow_redisplay": "always",
                "customer": "cus_1234567890",
            ],
            "shipping": [
                "name": "John Doe",
                "phone": "+1234567890",
                "address": [
                    "line1": "123 Main St",
                    "line2": "Apt 4B",
                    "city": "San Francisco",
                    "state": "CA",
                    "postal_code": "94111",
                    "country": "US",
                ],
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertEqual(confirmationToken?.stripeId, "ctoken_1NnQUf2eZvKYlo2CIObdtbnb")
        XCTAssertTrue(confirmationToken?.liveMode ?? false)
        XCTAssertEqual(confirmationToken?.created, Date(timeIntervalSince1970: 1694025025))
        XCTAssertEqual(confirmationToken?.expiresAt, Date(timeIntervalSince1970: 1694068225))
        XCTAssertEqual(confirmationToken?.paymentIntentId, "pi_1234567890")
        XCTAssertEqual(confirmationToken?.setupIntentId, "seti_1234567890")
        XCTAssertEqual(confirmationToken?.returnURL, "https://example.com/return")
        XCTAssertEqual(confirmationToken?.setupFutureUsage, .offSession)

        // Test payment method preview
        let paymentMethodPreview = confirmationToken?.paymentMethodPreview
        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .card)
        XCTAssertEqual(paymentMethodPreview?.billingDetails?.name, "John Doe")
        XCTAssertEqual(paymentMethodPreview?.billingDetails?.email, "john@example.com")
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .always)
        XCTAssertEqual(paymentMethodPreview?.customerId, "cus_1234567890")

        // Test shipping details
        let shipping = confirmationToken?.shipping
        XCTAssertNotNil(shipping)
        XCTAssertEqual(shipping?.name, "John Doe")
        XCTAssertEqual(shipping?.phone, "+1234567890")
        XCTAssertEqual(shipping?.address?.line1, "123 Main St")
        XCTAssertEqual(shipping?.address?.line2, "Apt 4B")
        XCTAssertEqual(shipping?.address?.city, "San Francisco")
        XCTAssertEqual(shipping?.address?.state, "CA")
        XCTAssertEqual(shipping?.address?.postalCode, "94111")
        XCTAssertEqual(shipping?.address?.country, "US")
    }

    func testConfirmationTokenAllResponseFieldsPreserved() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "custom_field": "custom_value",
            "nested_custom": [
                "inner": "value"
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertNotNil(confirmationToken?.allResponseFields)
        XCTAssertEqual(confirmationToken?.allResponseFields["custom_field"] as? String, "custom_value")
        XCTAssertNotNil(confirmationToken?.allResponseFields["nested_custom"])
    }

    func testConfirmationTokenEmptyResponse() {
        let emptyJson = [:] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: emptyJson)
        XCTAssertNil(confirmationToken, "decodedObject should return nil for empty response")
    }

    func testConfirmationTokenNilResponse() {
        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: nil)
        XCTAssertNil(confirmationToken, "decodedObject should return nil for nil response")
    }
}

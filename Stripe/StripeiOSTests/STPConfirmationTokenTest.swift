//
//  STPConfirmationTokenTest.swift
//  StripeiOSTests
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP)@_spi(ConfirmationTokensPublicPreview) import StripePayments
import XCTest

class STPConfirmationTokenTest: XCTestCase {

    // MARK: - Basic Parsing Tests

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
        XCTAssertNil(confirmationToken?.expiresAt)
        XCTAssertNil(confirmationToken?.paymentIntentId)
        XCTAssertNil(confirmationToken?.setupIntentId)
        XCTAssertNil(confirmationToken?.returnURL)
        XCTAssertNil(confirmationToken?.setupFutureUsage)
    }

    // MARK: - MandateData Tests

    func testConfirmationTokenWithMandateData() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "mandate_data": [
                "customer_acceptance": [
                    "type": "online",
                    "online": [
                        "ip_address": "192.168.1.1",
                        "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X)",
                    ],
                ],
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertNotNil(confirmationToken?.mandateData)
        XCTAssertNotNil(confirmationToken?.mandateData?.customerAcceptance)
        XCTAssertEqual(confirmationToken?.mandateData?.customerAcceptance.typeString, "online")
        XCTAssertNotNil(confirmationToken?.mandateData?.customerAcceptance.onlineParams)
        XCTAssertEqual(confirmationToken?.mandateData?.customerAcceptance.onlineParams?.ipAddress, "192.168.1.1")
        XCTAssertEqual(confirmationToken?.mandateData?.customerAcceptance.onlineParams?.userAgent, "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X)")
    }

    // MARK: - PaymentMethodOptions Tests

    func testConfirmationTokenWithPaymentMethodOptions() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_options": [
                "card": [
                    "cvc_token": "cvctok_1234567890",
                    "require_cvc_recollection": true,
                ],
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertNotNil(confirmationToken?.paymentMethodOptions)
        XCTAssertNotNil(confirmationToken?.paymentMethodOptions?.card)
        XCTAssertEqual(confirmationToken?.paymentMethodOptions?.card?.cvcToken, "cvctok_1234567890")
        XCTAssertTrue(confirmationToken?.paymentMethodOptions?.card?.requireCvcRecollection ?? false)
    }

    // MARK: - PaymentMethodPreview Tests

    func testConfirmationTokenWithPaymentMethodPreview() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_preview": [
                "type": "card",
                "allow_redisplay": "always",
                "customer": "cus_1234567890",
                "billing_details": [
                    "address": [
                        "city": "Hyde Park",
                        "country": "US",
                        "line1": "50 Sprague St",
                        "line2": "",
                        "postal_code": "02136",
                        "state": "MA",
                    ],
                    "email": "jennyrosen@stripe.com",
                    "name": "Jenny Rosen",
                    "phone": NSNull(),
                ],
                "card": [
                    "brand": "visa",
                    "country": "US",
                    "exp_month": 8,
                    "exp_year": 2026,
                    "funding": "credit",
                    "last4": "4242",
                    "display_brand": "visa",
                ],
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertNotNil(confirmationToken?.paymentMethodPreview)
        XCTAssertEqual(confirmationToken?.paymentMethodPreview?.type, .card)
        XCTAssertEqual(confirmationToken?.paymentMethodPreview?.allowRedisplay, .always)
        XCTAssertEqual(confirmationToken?.paymentMethodPreview?.customerId, "cus_1234567890")

        // Test billing details
        let billingDetails = confirmationToken?.paymentMethodPreview?.billingDetails
        XCTAssertNotNil(billingDetails)
        XCTAssertEqual(billingDetails?.name, "Jenny Rosen")
        XCTAssertEqual(billingDetails?.email, "jennyrosen@stripe.com")
        XCTAssertEqual(billingDetails?.address?.city, "Hyde Park")
        XCTAssertEqual(billingDetails?.address?.country, "US")
        XCTAssertEqual(billingDetails?.address?.line1, "50 Sprague St")
        XCTAssertEqual(billingDetails?.address?.postalCode, "02136")
        XCTAssertEqual(billingDetails?.address?.state, "MA")

        // Test card details
        let card = confirmationToken?.paymentMethodPreview?.card
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.brand, .visa)
        XCTAssertEqual(card?.country, "US")
        XCTAssertEqual(card?.expMonth, 8)
        XCTAssertEqual(card?.expYear, 2026)
        XCTAssertEqual(card?.funding, "credit")
        XCTAssertEqual(card?.last4, "4242")
    }

    func testConfirmationTokenWithPaymentMethodPreviewAllowRedisplayVariations() {
        // Test "limited"
        let limitedJson = [
            "id": "ctoken_1",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_preview": [
                "type": "card",
                "allow_redisplay": "limited",
            ],
        ] as [String: Any]

        let limitedToken = STPConfirmationToken.decodedObject(fromAPIResponse: limitedJson)
        XCTAssertEqual(limitedToken?.paymentMethodPreview?.allowRedisplay, .limited)

        // Test "unspecified"
        let unspecifiedJson = [
            "id": "ctoken_2",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_preview": [
                "type": "card",
                "allow_redisplay": "unspecified",
            ],
        ] as [String: Any]

        let unspecifiedToken = STPConfirmationToken.decodedObject(fromAPIResponse: unspecifiedJson)
        XCTAssertEqual(unspecifiedToken?.paymentMethodPreview?.allowRedisplay, .unspecified)

        // Test missing (should default to unspecified)
        let missingJson = [
            "id": "ctoken_3",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "payment_method_preview": [
                "type": "card"
            ],
        ] as [String: Any]

        let missingToken = STPConfirmationToken.decodedObject(fromAPIResponse: missingJson)
        XCTAssertEqual(missingToken?.paymentMethodPreview?.allowRedisplay, .unspecified)
    }

    // MARK: - Shipping Tests

    func testConfirmationTokenWithShipping() {
        let json = [
            "id": "ctoken_1NnQUf2eZvKYlo2CIObdtbnb",
            "object": "confirmation_token",
            "created": 1694025025,
            "livemode": false,
            "shipping": [
                "address": [
                    "city": "Hyde Park",
                    "country": "US",
                    "line1": "50 Sprague St",
                    "line2": "Apt 2",
                    "postal_code": "02136",
                    "state": "MA",
                ],
                "name": "Jenny Rosen",
                "phone": "+15551234567",
            ],
        ] as [String: Any]

        let confirmationToken = STPConfirmationToken.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(confirmationToken)
        XCTAssertNotNil(confirmationToken?.shipping)
        XCTAssertEqual(confirmationToken?.shipping?.name, "Jenny Rosen")
        XCTAssertEqual(confirmationToken?.shipping?.phone, "+15551234567")
        XCTAssertEqual(confirmationToken?.shipping?.address?.city, "Hyde Park")
        XCTAssertEqual(confirmationToken?.shipping?.address?.country, "US")
        XCTAssertEqual(confirmationToken?.shipping?.address?.line1, "50 Sprague St")
        XCTAssertEqual(confirmationToken?.shipping?.address?.line2, "Apt 2")
        XCTAssertEqual(confirmationToken?.shipping?.address?.postalCode, "02136")
        XCTAssertEqual(confirmationToken?.shipping?.address?.state, "MA")
    }

    // MARK: - Description Tests

    func testConfirmationTokenDescription() {
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

        let description = confirmationToken?.description ?? ""

        XCTAssertTrue(description.contains("ctoken_1NnQUf2eZvKYlo2CIObdtbnb"))
        XCTAssertTrue(description.contains("livemode = YES"))
        XCTAssertTrue(description.contains("paymentIntentId = pi_1234567890"))
        XCTAssertTrue(description.contains("setupIntentId = seti_1234567890"))
        XCTAssertTrue(description.contains("returnURL = https://example.com/return"))
        XCTAssertTrue(description.contains("setupFutureUsage = off_session"))
    }
}

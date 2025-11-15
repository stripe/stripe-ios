//
//  STPPaymentMethodPreviewTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/15/25.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

class STPPaymentMethodPreviewTest: XCTestCase {

    // MARK: - Required Field Validation Tests

    func testPaymentMethodPreviewRequiresType() {
        let jsonWithoutType = [
            "billing_details": [
                "name": "John Doe",
                "email": "john@example.com",
            ],
            "allow_redisplay": "always",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: jsonWithoutType)
        XCTAssertNil(paymentMethodPreview, "decodedObject should return nil when 'type' field is missing")
    }

    func testPaymentMethodPreviewRequiresTypeNotNull() {
        let jsonWithNullType = [
            "type": NSNull(),
            "billing_details": [
                "name": "John Doe",
                "email": "john@example.com",
            ],
            "allow_redisplay": "always",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: jsonWithNullType)
        XCTAssertNil(paymentMethodPreview, "decodedObject should return nil when 'type' field is null")
    }

    // MARK: - Basic Type Parsing Tests

    func testPaymentMethodPreviewCardType() {
        let json = [
            "type": "card",
            "billing_details": [
                "name": "John Doe",
                "email": "john@example.com",
            ],
            "allow_redisplay": "always",
            "customer": "cus_1234567890",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .card)
        XCTAssertEqual(paymentMethodPreview?.billingDetails?.name, "John Doe")
        XCTAssertEqual(paymentMethodPreview?.billingDetails?.email, "john@example.com")
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .always)
        XCTAssertEqual(paymentMethodPreview?.customerId, "cus_1234567890")
    }

    func testPaymentMethodPreviewSEPADebitType() {
        let json = [
            "type": "sepa_debit",
            "billing_details": [
                "name": "John Doe",
                "email": "john@example.com",
            ],
            "allow_redisplay": "limited",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .SEPADebit)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .limited)
    }

    func testPaymentMethodPreviewUnknownType() {
        let json = [
            "type": "future_payment_method",
            "billing_details": [
                "name": "John Doe"
            ],
            "allow_redisplay": "unspecified",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .unknown)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .unspecified)
    }

    // MARK: - Allow Redisplay Tests

    func testAllowRedisplayAlways() {
        let json = [
            "type": "card",
            "allow_redisplay": "always",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .always)
    }

    func testAllowRedisplayLimited() {
        let json = [
            "type": "card",
            "allow_redisplay": "limited",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .limited)
    }

    func testAllowRedisplayUnspecified() {
        let json = [
            "type": "card",
            "allow_redisplay": "unspecified",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .unspecified)
    }

    func testAllowRedisplayInvalidValue() {
        let json = [
            "type": "card",
            "allow_redisplay": "invalid_value",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .unspecified)
    }

    func testAllowRedisplayMissing() {
        let json = [
            "type": "card"
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .unspecified)
    }

    // MARK: - Billing Details Tests

    func testBillingDetailsComplete() {
        let json = [
            "type": "card",
            "billing_details": [
                "name": "John Doe",
                "email": "john@example.com",
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

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        let billingDetails = paymentMethodPreview?.billingDetails
        XCTAssertNotNil(billingDetails)
        XCTAssertEqual(billingDetails?.name, "John Doe")
        XCTAssertEqual(billingDetails?.email, "john@example.com")
        XCTAssertEqual(billingDetails?.phone, "+1234567890")

        let address = billingDetails?.address
        XCTAssertNotNil(address)
        XCTAssertEqual(address?.line1, "123 Main St")
        XCTAssertEqual(address?.line2, "Apt 4B")
        XCTAssertEqual(address?.city, "San Francisco")
        XCTAssertEqual(address?.state, "CA")
        XCTAssertEqual(address?.postalCode, "94111")
        XCTAssertEqual(address?.country, "US")
    }

    func testBillingDetailsNil() {
        let json = [
            "type": "card"
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertNil(paymentMethodPreview?.billingDetails)
    }

    // MARK: - Edge Cases and Error Handling

    func testPaymentMethodPreviewWithNullFields() {
        let json = [
            "type": "card",
            "billing_details": NSNull(),
            "allow_redisplay": NSNull(),
            "customer": NSNull(),
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .card)
        XCTAssertNil(paymentMethodPreview?.billingDetails)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .unspecified)
        XCTAssertNil(paymentMethodPreview?.customerId)
    }

    func testPaymentMethodPreviewMinimalValid() {
        let json = [
            "type": "card"
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .card)
        XCTAssertNil(paymentMethodPreview?.billingDetails)
        XCTAssertEqual(paymentMethodPreview?.allowRedisplay, .unspecified)
        XCTAssertNil(paymentMethodPreview?.customerId)
    }

    func testPaymentMethodPreviewEmptyResponse() {
        let emptyJson = [:] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: emptyJson)
        XCTAssertNil(paymentMethodPreview, "decodedObject should return nil for empty response")
    }

    func testPaymentMethodPreviewNilResponse() {
        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: nil)
        XCTAssertNil(paymentMethodPreview, "decodedObject should return nil for nil response")
    }

    // MARK: - Card Field Tests

    func testPaymentMethodPreviewCardFields() {
        let json = [
            "type": "card",
            "billing_details": [
                "name": "John Doe"
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
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertNotNil(paymentMethodPreview?.card)
        XCTAssertEqual(paymentMethodPreview?.card?.brand, .visa)
        XCTAssertEqual(paymentMethodPreview?.card?.country, "US")
        XCTAssertEqual(paymentMethodPreview?.card?.expMonth, 12)
        XCTAssertEqual(paymentMethodPreview?.card?.expYear, 2030)
        XCTAssertEqual(paymentMethodPreview?.card?.funding, "credit")
        XCTAssertEqual(paymentMethodPreview?.card?.last4, "4242")
        XCTAssertEqual(paymentMethodPreview?.card?.displayBrand, "visa")
    }

    func testPaymentMethodPreviewCardFieldsWithAdditionalData() {
        let json = [
            "type": "card",
            "card": [
                "brand": "mastercard",
                "country": "GB",
                "exp_month": 6,
                "exp_year": 2025,
                "funding": "debit",
                "last4": "5678",
                "display_brand": "mastercard",
                "fingerprint": "fingerprint123",
                "networks": [
                    "available": ["mastercard"],
                    "preferred": "mastercard",
                ],
                "checks": [
                    "cvc_check": "pass"
                ],
                "three_d_secure_usage": [
                    "supported": true
                ],
            ],
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertNotNil(paymentMethodPreview?.card)
        XCTAssertEqual(paymentMethodPreview?.card?.brand, .mastercard)
        XCTAssertEqual(paymentMethodPreview?.card?.country, "GB")
        XCTAssertEqual(paymentMethodPreview?.card?.expMonth, 6)
        XCTAssertEqual(paymentMethodPreview?.card?.expYear, 2025)
        XCTAssertEqual(paymentMethodPreview?.card?.funding, "debit")
        XCTAssertEqual(paymentMethodPreview?.card?.last4, "5678")
        XCTAssertEqual(paymentMethodPreview?.card?.displayBrand, "mastercard")
        XCTAssertEqual(paymentMethodPreview?.card?.fingerprint, "fingerprint123")
        XCTAssertNotNil(paymentMethodPreview?.card?.networks)
        XCTAssertNotNil(paymentMethodPreview?.card?.checks)
        XCTAssertNotNil(paymentMethodPreview?.card?.threeDSecureUsage)
    }

    func testPaymentMethodPreviewCardFieldsNil() {
        let json = [
            "type": "card"
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertNil(paymentMethodPreview?.card)
    }

    func testPaymentMethodPreviewNonCardTypeWithoutCardFields() {
        let json = [
            "type": "sepa_debit",
            "billing_details": [
                "name": "John Doe"
            ],
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertEqual(paymentMethodPreview?.type, .SEPADebit)
        XCTAssertNil(paymentMethodPreview?.card)
    }

    // MARK: - AllResponseFields Test

    func testAllResponseFieldsPreserved() {
        let json = [
            "type": "card",
            "billing_details": [
                "name": "John Doe"
            ],
            "allow_redisplay": "always",
            "customer": "cus_1234567890",
            "custom_field": "custom_value",
        ] as [String: Any]

        let paymentMethodPreview = STPPaymentMethodPreview.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(paymentMethodPreview)
        XCTAssertNotNil(paymentMethodPreview?.allResponseFields)
        XCTAssertEqual(paymentMethodPreview?.allResponseFields["type"] as? String, "card")
        XCTAssertEqual(paymentMethodPreview?.allResponseFields["customer"] as? String, "cus_1234567890")
        XCTAssertEqual(paymentMethodPreview?.allResponseFields["custom_field"] as? String, "custom_value")
    }
}

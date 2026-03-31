//
//  ConsumerPaymentDetailsEncodingTests.swift
//  StripePaymentSheetTests
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
import XCTest

class ConsumerPaymentDetailsEncodingTests: XCTestCase {

    // Verifies that encoding a ParsedEnum<DetailsType> for any known case
    // produces the same string as the enum's rawValue.
    //
    // This matters because ParsedEnum always encodes via its rawValue — if the
    // inner enum's rawValue ever diverges from what the API expects, this test
    // will catch it.
    func test_parsedEnumEncodingMatchesUnderlyingRawValue() throws {
        for detailsType in ConsumerPaymentDetails.DetailsType.allCases {
            let parsed = ParsedEnum(detailsType)
            let encodedData = try JSONEncoder().encode(parsed)
            let encodedString = try JSONDecoder().decode(String.self, from: encodedData)
            XCTAssertEqual(
                encodedString,
                detailsType.rawValue,
                "ParsedEnum<DetailsType> encoding should match rawValue for .\(detailsType)"
            )
        }
    }

    // MARK: - Display metadata decoding

    func test_decodingUnknownTypeWithDisplayMetadata() throws {
        let json: [String: Any] = [
            "id": "csmrpd_test_123",
            "type": "CRYPTO",
            "is_default": false,
            "display": [
                "icon": [
                    "default": "https://cdn.stripe.com/crypto.png"
                ],
                "label": "Stablecoin",
                "sublabel": "Wallet •••2",
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let details = try decoder.decode(ConsumerPaymentDetails.self, from: data)

        if case .unparsable(let rawValue) = details.details {
            XCTAssertEqual(rawValue, "CRYPTO")
        } else {
            XCTFail("Expected .unparsable case")
        }

        XCTAssertNotNil(details.display)
        XCTAssertEqual(details.display?.label, "Stablecoin")
        XCTAssertEqual(details.display?.sublabel, "Wallet •••2")
        XCTAssertEqual(details.display?.icon?.main, URL(string: "https://cdn.stripe.com/crypto.png"))
    }

    func test_decodingUnknownTypeWithoutDisplayMetadata() throws {
        let json: [String: Any] = [
            "id": "csmrpd_test_456",
            "type": "UNKNOWN_TYPE",
            "is_default": false,
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let details = try decoder.decode(ConsumerPaymentDetails.self, from: data)

        if case .unparsable(let rawValue) = details.details {
            XCTAssertEqual(rawValue, "UNKNOWN_TYPE")
        } else {
            XCTFail("Expected .unparsable case")
        }

        XCTAssertNil(details.display)
    }

    func test_decodingKnownTypeWithDisplayMetadata() throws {
        let json: [String: Any] = [
            "id": "csmrpd_test_789",
            "type": "CARD",
            "is_default": true,
            "cardDetails": [
                "expYear": 30,
                "expMonth": 12,
                "brand": "visa",
                "networks": ["visa"],
                "last4": "4242",
                "funding": "CREDIT",
            ],
            "display": [
                "label": "Visa Credit",
                "sublabel": "•••• 4242",
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let details = try decoder.decode(ConsumerPaymentDetails.self, from: data)

        if case .card(let card) = details.details {
            XCTAssertEqual(card.last4, "4242")
        } else {
            XCTFail("Expected .card case")
        }

        // Display metadata is available even for known types
        XCTAssertNotNil(details.display)
        XCTAssertEqual(details.display?.label, "Visa Credit")
    }

    func test_decodingDisplayMetadataWithOptionalFields() throws {
        let json: [String: Any] = [
            "id": "csmrpd_test_abc",
            "type": "SEPA",
            "is_default": false,
            "display": [
                "label": "SEPA Direct Debit",
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let details = try decoder.decode(ConsumerPaymentDetails.self, from: data)

        XCTAssertNotNil(details.display)
        XCTAssertEqual(details.display?.label, "SEPA Direct Debit")
        XCTAssertNil(details.display?.sublabel)
        XCTAssertNil(details.display?.icon)
    }
}

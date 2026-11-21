//
//  ConsumerPaymentDetailsEncodingTests.swift
//  StripePaymentSheetTests
//

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePayments
import XCTest

class ConsumerPaymentDetailsEncodingTests: XCTestCase {

    func testCardIssuerCountryDecodesIndependentlyOfBilling() throws {
        let json: [String: Any] = [
            "id": "pd_india",
            "type": "CARD",
            "is_default": false,
            "card_details": [
                "exp_year": 2055, "exp_month": 12, "brand": "visa", "networks": ["visa"],
                "last4": "4242", "funding": "CREDIT", "country": "COUNTRY_IN",
            ],
        ]
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let details = try decoder.decode(ConsumerPaymentDetails.self, from: JSONSerialization.data(withJSONObject: json))
        guard case .card(let card) = details.details else {
            return XCTFail("Expected card details")
        }
        XCTAssertEqual(card.country, "COUNTRY_IN")
        XCTAssertTrue(details.isIndiaCardOverride(.indiaCardElementsSession()))
    }

    func testIndiaRoutingPredicate() {
        let cases: [(String?, Bool?, String?, Bool)] = [
            ("IN", true, "LINK_PAYMENT_METHOD", true),
            ("COUNTRY_IN", true, "LINK_PAYMENT_METHOD", true),
            ("in", true, "LINK_PAYMENT_METHOD", true),
            ("country_in", true, "LINK_PAYMENT_METHOD", true),
            (nil, true, "LINK_PAYMENT_METHOD", false),
            ("", true, "LINK_PAYMENT_METHOD", false),
            (" ", true, "LINK_PAYMENT_METHOD", false),
            ("IND", true, "LINK_PAYMENT_METHOD", false),
            ("COUNTRY_UNKNOWN", true, "LINK_PAYMENT_METHOD", false),
            ("US", true, "LINK_PAYMENT_METHOD", false),
            ("IN", false, "LINK_PAYMENT_METHOD", false),
            ("IN", nil, "LINK_PAYMENT_METHOD", false),
            ("IN", true, nil, true),
            ("IN", true, "PASSTHROUGH", false),
            ("IN", true, "LINK_CARD_BRAND", false),
        ]
        for (country, flag, mode, expected) in cases {
            let details = indiaCardDetails(country: country)
            let session = STPElementsSession.indiaCardElementsSession(flag: flag, mode: mode)
            XCTAssertEqual(details.shouldSharePaymentDetails(session), expected, "country=\(country ?? "nil"), mode=\(mode ?? "nil")")
            XCTAssertFalse(session.linkPassthroughModeEnabled)
        }
        XCTAssertFalse(LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
            .isIndiaCardOverride(.indiaCardElementsSession()))
    }

    func testIndiaCardConsentUsesCardSetupOptions() {
        let session = STPElementsSession.linkElementsSessionWithCustomerSessionAndIndiaOverride
        let indiaCard = indiaCardDetails(country: "IN")
        XCTAssertEqual(indiaCard.computeAllowRedisplay(elementsSession: session, isSettingUp: { $0 == .card }), .limited)
        XCTAssertEqual(indiaCardDetails(country: "US").computeAllowRedisplay(elementsSession: session, isSettingUp: { $0 == .card }), .unspecified)
    }

    private func indiaCardDetails(country: String?) -> ConsumerPaymentDetails {
        ConsumerPaymentDetails(
            stripeID: "pd_india",
            details: .card(card: .init(
                expiryYear: 2055, expiryMonth: 12, brand: "visa", networks: ["visa"], last4: "4242",
                funding: .credit, checks: nil, country: country
            )),
            billingAddress: nil, billingEmailAddress: nil, nickname: nil, isDefault: false
        )
    }

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

    func test_decodingGenericTypeWithDisplayMetadata() throws {
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

        if case .generic(let rawValue) = details.details {
            XCTAssertEqual(rawValue, "CRYPTO")
        } else {
            XCTFail("Expected .generic case")
        }

        XCTAssertFalse(details.isIndiaCardOverride(.indiaCardElementsSession()))
        XCTAssertNotNil(details.display)
        XCTAssertEqual(details.display?.label, "Stablecoin")
        XCTAssertEqual(details.display?.sublabel, "Wallet •••2")
        XCTAssertEqual(details.display?.icon?.main, URL(string: "https://cdn.stripe.com/crypto.png"))
    }

    func test_decodingGenericTypeWithoutDisplayMetadata() throws {
        let json: [String: Any] = [
            "id": "csmrpd_test_456",
            "type": "UNKNOWN_TYPE",
            "is_default": false,
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let details = try decoder.decode(ConsumerPaymentDetails.self, from: data)

        if case .generic(let rawValue) = details.details {
            XCTAssertEqual(rawValue, "UNKNOWN_TYPE")
        } else {
            XCTFail("Expected .generic case")
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
            XCTAssertNil(card.country)
        } else {
            XCTFail("Expected .card case")
        }

        // Display metadata is available even for known types
        XCTAssertNotNil(details.display)
        XCTAssertEqual(details.display?.label, "Visa Credit")
    }

    func test_decodingDisplayIconType() throws {
        // Given payment details with each icon type, plus one the SDK doesn't know about
        let iconTypes = ["card_art", "card_brand", "institution", "generic", "some_new_type"]
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // When the payment details are decoded
        let decodedIconTypes = try iconTypes.map { iconType in
            let json: [String: Any] = [
                "id": "csmrpd_test_123",
                "type": "SEPA",
                "is_default": false,
                "display": [
                    "label": "Label",
                    "icon": [
                        "default": "https://b.stripecdn.com/icon.png",
                        "type": iconType,
                    ],
                ],
            ]
            let data = try JSONSerialization.data(withJSONObject: json)
            return try decoder.decode(ConsumerPaymentDetails.self, from: data).display?.icon
        }

        // Then known types are decoded, and an unknown type doesn't prevent the icon from being decoded
        XCTAssertEqual(decodedIconTypes.map { $0?.type }, [.cardArt, .cardBrand, .institution, .generic, nil])
        XCTAssertEqual(decodedIconTypes.map { $0?.main }, Array(repeating: URL(string: "https://b.stripecdn.com/icon.png"), count: iconTypes.count))
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

    func test_genericTypeWithBillingCountryInAllowedCountriesIsSupported() throws {
        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(linkFundingSources: ["CRYPTO"])
        let linkAccount = LinkStubs.account()
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.allowedCountries = ["US"]

        let details = ConsumerPaymentDetails(
            stripeID: "csmrpd_test_country_match",
            details: .generic(rawValue: "CRYPTO"),
            billingAddress: BillingAddress(countryCode: "US"),
            billingEmailAddress: nil,
            nickname: nil,
            display: .init(label: "Stablecoin", sublabel: "Wallet •••2", icon: nil),
            isDefault: false
        )

        XCTAssertTrue(
            details.isSupported(
                linkAccount: linkAccount,
                elementsSession: elementsSession,
                configuration: configuration,
                cardBrandFilter: .default,
                cardFundingFilter: .default
            )
        )
    }

    func test_genericTypeWithoutBillingCountryIsNotSupportedWhenAllowedCountriesAreFiltered() throws {
        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(linkFundingSources: ["CRYPTO"])
        let linkAccount = LinkStubs.account()
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.allowedCountries = ["US"]

        let details = ConsumerPaymentDetails(
            stripeID: "csmrpd_test_missing_country",
            details: .generic(rawValue: "CRYPTO"),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nil,
            display: .init(label: "Stablecoin", sublabel: "Wallet •••2", icon: nil),
            isDefault: false
        )

        XCTAssertFalse(
            details.isSupported(
                linkAccount: linkAccount,
                elementsSession: elementsSession,
                configuration: configuration,
                cardBrandFilter: .default,
                cardFundingFilter: .default
            )
        )
    }

}

//
//  ConsumerPaymentDetailsEncodingTests.swift
//  StripePaymentSheetTests
//

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
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

    // MARK: - Bank account decoding

    func test_decodingBankAccountUsesBankAccountName() throws {
        // Given a bank account with both an account name and a bank name
        let json = makeBankAccountJSON(bankAccountName: "Total Checking", bankName: "Chase")

        // When decoding
        let details = try decodePaymentDetails(from: json)

        // Then both names are decoded and the account name is displayed
        guard case .bankAccount(let bankAccount) = details.details else {
            return XCTFail("Expected .bankAccount case")
        }
        XCTAssertEqual(bankAccount.bankName, "Chase")
        XCTAssertEqual(bankAccount.accountName, "Total Checking")
        XCTAssertEqual(bankAccount.name, "Total Checking")
        XCTAssertEqual(bankAccount.iconCode, "morganchase")
        XCTAssertEqual(bankAccount.last4, "0644")
        XCTAssertEqual(bankAccount.country, "COUNTRY_US")
    }

    func test_decodingBankAccountWithNullBankAccountNameFallsBackToBankName() throws {
        // Given a bank account whose account name is null
        let json = makeBankAccountJSON(bankAccountName: NSNull(), bankName: "CHASE Bank")

        // When decoding
        let details = try decodePaymentDetails(from: json)

        // Then the bank name is displayed instead
        guard case .bankAccount(let bankAccount) = details.details else {
            return XCTFail("Expected .bankAccount case")
        }
        XCTAssertNil(bankAccount.accountName)
        XCTAssertEqual(bankAccount.bankName, "CHASE Bank")
        XCTAssertEqual(bankAccount.name, "CHASE Bank")
    }

    func test_decodingBankAccountWithMissingBankAccountNameFallsBackToBankName() throws {
        // Given a bank account with no account name key at all
        let json = makeBankAccountJSON(bankAccountName: nil, bankName: "CHASE Bank")

        // When decoding
        let details = try decodePaymentDetails(from: json)

        // Then the bank name is displayed instead
        guard case .bankAccount(let bankAccount) = details.details else {
            return XCTFail("Expected .bankAccount case")
        }
        XCTAssertNil(bankAccount.accountName)
        XCTAssertEqual(bankAccount.bankName, "CHASE Bank")
        XCTAssertEqual(bankAccount.name, "CHASE Bank")
    }

    func test_decodingBankAccountWithoutBankNameFails() throws {
        // Given a bank account with neither an account name nor a bank name
        let json = makeBankAccountJSON(bankAccountName: NSNull(), bankName: NSNull())

        // When decoding, then it throws
        XCTAssertThrowsError(try decodePaymentDetails(from: json))
    }

    func test_decodingPaymentDetailsListWithNullBankAccountName() throws {
        // Given a list response where one bank account has a null account name
        let json: [String: Any] = [
            "redacted_payment_details": [
                makeBankAccountJSON(id: "csmrpd_1", bankAccountName: "Spending Account", bankName: "Ally Bank"),
                makeBankAccountJSON(id: "csmrpd_2", bankAccountName: NSNull(), bankName: "CHASE Bank"),
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        // When decoding with the API client's decoder
        let response = try StripeJSONDecoder().decode(DetailsListResponse.self, from: data)

        // Then every payment method is decoded
        XCTAssertEqual(response.redactedPaymentDetails.map(\.stripeID), ["csmrpd_1", "csmrpd_2"])
        XCTAssertEqual(response.redactedPaymentDetails.map(\.paymentSheetLabel), ["Spending Account", "CHASE Bank"])
    }

    func test_bankAccountEncodingRoundTrips() throws {
        // Given a bank account
        let bankAccount = ConsumerPaymentDetails.Details.BankAccount(
            iconCode: "ally",
            bankName: "Ally Bank",
            accountName: "Savings Account",
            last4: "4183",
            country: "COUNTRY_US"
        )

        // When encoding and decoding it
        let data = try JSONEncoder().encode(bankAccount)
        let decoded = try JSONDecoder().decode(ConsumerPaymentDetails.Details.BankAccount.self, from: data)

        // Then the values are preserved
        XCTAssertEqual(decoded.iconCode, "ally")
        XCTAssertEqual(decoded.bankName, "Ally Bank")
        XCTAssertEqual(decoded.accountName, "Savings Account")
        XCTAssertEqual(decoded.last4, "4183")
        XCTAssertEqual(decoded.country, "COUNTRY_US")
    }

    // MARK: - Bank account icon code

    func test_resolvedIconCodePrefersServerIconCode() {
        // Given a bank account with a server-provided icon code and an account name that doesn't match any bank
        let bankAccount = ConsumerPaymentDetails.Details.BankAccount(
            iconCode: "ally",
            bankName: "Ally Bank",
            accountName: "Savings Account",
            last4: "4183",
            country: "COUNTRY_US"
        )

        // Then the server-provided icon code is used
        XCTAssertEqual(bankAccount.resolvedIconCode, "ally")
    }

    func test_resolvedIconCodeFallsBackToMatchingBankName() {
        // Given a bank account without an icon code whose account name doesn't match any bank
        let bankAccount = ConsumerPaymentDetails.Details.BankAccount(
            iconCode: nil,
            bankName: "JPMorgan Chase",
            accountName: "Total Checking",
            last4: "0644",
            country: "COUNTRY_US"
        )

        // Then the icon code is matched from the bank name, not the account name
        XCTAssertEqual(bankAccount.resolvedIconCode, "morganchase")
    }

    func test_resolvedIconCodeIsDefaultForUnknownBank() {
        // Given a bank account without an icon code for an unrecognized bank
        let bankAccount = ConsumerPaymentDetails.Details.BankAccount(
            iconCode: nil,
            bankName: "Unknown Credit Union",
            accountName: nil,
            last4: "1234",
            country: "COUNTRY_US"
        )

        // Then the default icon code is used
        XCTAssertEqual(bankAccount.resolvedIconCode, "default")
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

    // MARK: - Helpers

    private struct DetailsListResponse: Decodable {
        let redactedPaymentDetails: [ConsumerPaymentDetails]
    }

    private func makeBankAccountJSON(
        id: String = "csmrpd_test_bank",
        bankAccountName: Any?,
        bankName: Any
    ) -> [String: Any] {
        var bankAccountDetails: [String: Any] = [
            "bank_icon_code": "morganchase",
            "bank_name": bankName,
            "country": "COUNTRY_US",
            "last4": "0644",
        ]
        if let bankAccountName {
            bankAccountDetails["bank_account_name"] = bankAccountName
        }
        return [
            "id": id,
            "type": "BANK_ACCOUNT",
            "is_default": false,
            "bank_account_details": bankAccountDetails,
        ]
    }

    private func decodePaymentDetails(from json: [String: Any]) throws -> ConsumerPaymentDetails {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try StripeJSONDecoder().decode(ConsumerPaymentDetails.self, from: data)
    }
}

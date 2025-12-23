//
//  CardFundingFilterTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/25/25.
//

import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) @_spi(CardFundingFilteringPrivatePreview) @testable import StripePaymentSheet
import XCTest

class CardFundingFilterTests: XCTestCase {

    // MARK: - Filtering Enabled Tests

    func testIsAccepted_allFundingTypesAccepted() {
        // Use the default filter which accepts all funding types
        let filter = CardFundingFilter.default

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when all funding types are accepted.")
        }
    }

    func testIsAccepted_allowedFundingTypes_debitOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: true)

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only debit is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_creditOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .credit, filteringEnabled: true)

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only credit is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .credit), "Credit should be accepted when only credit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only credit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only credit is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_prepaidOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .prepaid, filteringEnabled: true)

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only prepaid is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only prepaid is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should be accepted when only prepaid is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only prepaid is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_unknownOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .unknown, filteringEnabled: true)

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only unknown is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only unknown is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only unknown is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .other), "Other should be accepted when only unknown is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_debitAndCredit() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit], filteringEnabled: true)

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted when debit and credit are allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .credit), "Credit should be accepted when debit and credit are allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when debit and credit are allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when debit and credit are allowed.")
    }

    func testIsAccepted_allFundingTypesAllowed() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit, .prepaid, .unknown], filteringEnabled: true)

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when all funding types are explicitly allowed.")
        }
    }

    func testFundingTypeMapping() {
        XCTAssertEqual(STPCardFundingType.debit.asFundingType, .debit)
        XCTAssertEqual(STPCardFundingType.credit.asFundingType, .credit)
        XCTAssertEqual(STPCardFundingType.prepaid.asFundingType, .prepaid)
        XCTAssertEqual(STPCardFundingType.other.asFundingType, .unknown)
    }

    func testDefaultFilter() {
        let filter = CardFundingFilter.default

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Default filter should accept all funding types.")
        }
    }

    // MARK: - Filtering feature flag tests

    func testIsAccepted_filteringDisabled_acceptsAll() {
        // Even with restrictive allowed types, filtering disabled should accept all
        let filter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: false)

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when filtering is disabled.")
        }
    }

    func testApplePayMerchantCapabilities_filteringDisabled() {
        // Even with restrictive allowed types, filtering disabled should return nil
        let filter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: false)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNil(capabilities, "When filtering is disabled, nil should be returned regardless of allowed funding types.")
    }

    func testAllowedFundingTypesDisplayString_filteringDisabled() {
        // Even with restrictive allowed types, filtering disabled should return nil
        let filter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: false)

        XCTAssertNil(filter.allowedFundingTypesDisplayString(), "When filtering is disabled, display string should be nil.")
    }

    // MARK: - Factory Method Tests

    func testFromElementsSession_filteringEnabled() {
        let elementsSession = STPElementsSession._testCardValue(flags: ["elements_mobile_card_funding_filtering": true])

        let filter = CardFundingFilter.from(allowedFundingTypes: .debit, elementsSession: elementsSession)

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when filtering is enabled and only debit is allowed.")
    }

    func testFromElementsSession_filteringDisabled() {
        let elementsSession = STPElementsSession._testCardValue(flags: ["elements_mobile_card_funding_filtering": false])

        let filter = CardFundingFilter.from(allowedFundingTypes: .debit, elementsSession: elementsSession)

        // Even though allowedFundingTypes is .debit, filtering is disabled so all should be accepted
        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when elements session has filtering disabled.")
        }
    }

    func testFromElementsSession_flagMissing() {
        // When the flag is not present, filtering should be disabled (default false)
        let elementsSession = STPElementsSession._testCardValue()

        let filter = CardFundingFilter.from(allowedFundingTypes: .debit, elementsSession: elementsSession)

        // Flag missing means false, so filtering is disabled
        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when elements session flag is missing.")
        }
    }

    // MARK: - Apple Pay Merchant Capabilities Tests

    func testApplePayMerchantCapabilities_all() {
        // Use the default filter which accepts all funding types
        let filter = CardFundingFilter.default
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNil(capabilities, "When all funding types are accepted, nil should be returned to use the default capabilities on the payment request.")
    }

    func testApplePayMerchantCapabilities_debitOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: true)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertTrue(capabilities!.contains(.capabilityDebit), "Debit capability should be included when debit is allowed.")
        XCTAssertFalse(capabilities!.contains(.capabilityCredit), "Credit capability should not be included when only debit is allowed.")
    }

    func testApplePayMerchantCapabilities_creditOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .credit, filteringEnabled: true)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertFalse(capabilities!.contains(.capabilityDebit), "Debit capability should not be included when only credit is allowed.")
        XCTAssertTrue(capabilities!.contains(.capabilityCredit), "Credit capability should be included when credit is allowed.")
    }

    func testApplePayMerchantCapabilities_debitAndCredit() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit], filteringEnabled: true)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertTrue(capabilities!.contains(.capabilityDebit), "Debit capability should be included when debit is allowed.")
        XCTAssertTrue(capabilities!.contains(.capabilityCredit), "Credit capability should be included when credit is allowed.")
    }

    func testApplePayMerchantCapabilities_prepaidOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .prepaid, filteringEnabled: true)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertEqual(capabilities, .capability3DS, "Prepaid is not filterable via merchantCapabilities, so only 3DS should be set.")
    }

    func testApplePayMerchantCapabilities_unknownOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .unknown, filteringEnabled: true)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertEqual(capabilities, .capability3DS, "Unknown is not filterable via merchantCapabilities, so only 3DS should be set.")
    }

    // MARK: - Allowed Funding Types Display String Tests

    func testAllowedFundingTypesDisplayString_all() {
        // Use the default filter which accepts all funding types
        let filter = CardFundingFilter.default
        XCTAssertNil(filter.allowedFundingTypesDisplayString())
    }

    func testAllowedFundingTypesDisplayString_debitOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: true)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "Only debit cards are accepted")
    }

    func testAllowedFundingTypesDisplayString_creditOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .credit, filteringEnabled: true)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "Only credit cards are accepted")
    }

    func testAllowedFundingTypesDisplayString_prepaidOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .prepaid, filteringEnabled: true)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "Only prepaid cards are accepted")
    }

    func testAllowedFundingTypesDisplayString_debitAndCredit() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit], filteringEnabled: true)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "Only debit and credit cards are accepted")
    }

    func testAllowedFundingTypesDisplayString_debitAndPrepaid() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .prepaid], filteringEnabled: true)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "Only debit and prepaid cards are accepted")
    }

    func testAllowedFundingTypesDisplayString_creditAndPrepaid() {
        let filter = CardFundingFilter(allowedFundingTypes: [.credit, .prepaid], filteringEnabled: true)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "Only credit and prepaid cards are accepted")
    }

    func testAllowedFundingTypesDisplayString_allThreeTypes() {
        // When all three types are allowed, no warning is needed
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit, .prepaid], filteringEnabled: true)
        XCTAssertNil(filter.allowedFundingTypesDisplayString())
    }

    func testAllowedFundingTypesDisplayString_unknownOnly() {
        // Unknown has no display name, so should return nil
        let filter = CardFundingFilter(allowedFundingTypes: .unknown, filteringEnabled: true)
        XCTAssertNil(filter.allowedFundingTypesDisplayString())
    }
}

extension STPCardFundingType: @retroactive CaseIterable {
    public static var allCases: [STPCardFundingType] {
        return [.debit, .credit, .prepaid, .other]
    }
}

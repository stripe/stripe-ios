//
//  CardFundingFilterTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/25/25.
//

import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(CardFundingFilteringPrivatePreview) @testable import StripePaymentSheet
import XCTest

class CardFundingFilterTests: XCTestCase {

    func testIsAccepted_allFundingTypesAccepted() {
        let filter = CardFundingFilter(allowedFundingTypes: .all)

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when all funding types are accepted.")
        }
    }

    func testIsAccepted_allowedFundingTypes_debitOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .debit)

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only debit is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_creditOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .credit)

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only credit is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .credit), "Credit should be accepted when only credit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only credit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only credit is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_prepaidOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .prepaid)

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only prepaid is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only prepaid is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should be accepted when only prepaid is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only prepaid is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_unknownOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .unknown)

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only unknown is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only unknown is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only unknown is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .other), "Other should be accepted when only unknown is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_debitAndCredit() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit])

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted when debit and credit are allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .credit), "Credit should be accepted when debit and credit are allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when debit and credit are allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when debit and credit are allowed.")
    }

    func testIsAccepted_allFundingTypesAllowed() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit, .prepaid, .unknown])

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

    // MARK: - Apple Pay Merchant Capabilities Tests

    func testApplePayMerchantCapabilities_all() {
        let filter = CardFundingFilter(allowedFundingTypes: .all)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNil(capabilities, "When all funding types are accepted, nil should be returned to use the default capabilities on the payment request.")
    }

    func testApplePayMerchantCapabilities_debitOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .debit)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertTrue(capabilities!.contains(.capabilityDebit), "Debit capability should be included when debit is allowed.")
        XCTAssertFalse(capabilities!.contains(.capabilityCredit), "Credit capability should not be included when only debit is allowed.")
    }

    func testApplePayMerchantCapabilities_creditOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .credit)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertFalse(capabilities!.contains(.capabilityDebit), "Debit capability should not be included when only credit is allowed.")
        XCTAssertTrue(capabilities!.contains(.capabilityCredit), "Credit capability should be included when credit is allowed.")
    }

    func testApplePayMerchantCapabilities_debitAndCredit() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit])
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertTrue(capabilities!.contains(.capabilityDebit), "Debit capability should be included when debit is allowed.")
        XCTAssertTrue(capabilities!.contains(.capabilityCredit), "Credit capability should be included when credit is allowed.")
    }

    func testApplePayMerchantCapabilities_prepaidOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .prepaid)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertEqual(capabilities, .capability3DS, "Prepaid is not filterable via merchantCapabilities, so only 3DS should be set.")
    }

    func testApplePayMerchantCapabilities_unknownOnly() {
        let filter = CardFundingFilter(allowedFundingTypes: .unknown)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertEqual(capabilities, .capability3DS, "Unknown is not filterable via merchantCapabilities, so only 3DS should be set.")
    }

    // MARK: - Allowed Funding Types Display String Tests

    func testAllowedFundingTypesDisplayString_all() {
        let filter = CardFundingFilter(allowedFundingTypes: .all)
        XCTAssertNil(filter.allowedFundingTypesDisplayString())
    }

    func testAllowedFundingTypesDisplayString_singleType() {
        let filter = CardFundingFilter(allowedFundingTypes: .debit)
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "debit")
    }

    func testAllowedFundingTypesDisplayString_twoTypes() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit])
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "debit and credit")
    }

    func testAllowedFundingTypesDisplayString_threeTypes() {
        let filter = CardFundingFilter(allowedFundingTypes: [.debit, .credit, .prepaid])
        XCTAssertEqual(filter.allowedFundingTypesDisplayString(), "debit, credit and prepaid")
    }

    func testAllowedFundingTypesDisplayString_unknownOnly() {
        // Unknown has no display name, so should return nil
        let filter = CardFundingFilter(allowedFundingTypes: .unknown)
        XCTAssertNil(filter.allowedFundingTypesDisplayString())
    }
}

extension STPCardFundingType: @retroactive CaseIterable {
    public static var allCases: [STPCardFundingType] {
        return [.debit, .credit, .prepaid, .other]
    }
}

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
        let filter = CardFundingFilter(cardFundingAcceptance: .all)

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when all funding types are accepted.")
        }
    }

    func testIsAccepted_allowedFundingTypes_debitOnly() {
        let allowedFundingTypes: [PaymentSheet.CardFundingType] = [.debit]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only debit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only debit is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_creditOnly() {
        let allowedFundingTypes: [PaymentSheet.CardFundingType] = [.credit]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only credit is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .credit), "Credit should be accepted when only credit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only credit is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only credit is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_prepaidOnly() {
        let allowedFundingTypes: [PaymentSheet.CardFundingType] = [.prepaid]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only prepaid is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only prepaid is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should be accepted when only prepaid is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when only prepaid is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_unknownOnly() {
        let allowedFundingTypes: [PaymentSheet.CardFundingType] = [.unknown]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        XCTAssertFalse(filter.isAccepted(cardFundingType: .debit), "Debit should not be accepted when only unknown is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .credit), "Credit should not be accepted when only unknown is allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when only unknown is allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .other), "Other should be accepted when only unknown is allowed.")
    }

    func testIsAccepted_allowedFundingTypes_debitAndCredit() {
        let allowedFundingTypes: [PaymentSheet.CardFundingType] = [.debit, .credit]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        XCTAssertTrue(filter.isAccepted(cardFundingType: .debit), "Debit should be accepted when debit and credit are allowed.")
        XCTAssertTrue(filter.isAccepted(cardFundingType: .credit), "Credit should be accepted when debit and credit are allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .prepaid), "Prepaid should not be accepted when debit and credit are allowed.")
        XCTAssertFalse(filter.isAccepted(cardFundingType: .other), "Other should not be accepted when debit and credit are allowed.")
    }

    func testIsAccepted_allFundingTypesAllowed() {
        let allowedFundingTypes: [PaymentSheet.CardFundingType] = [.debit, .credit, .prepaid, .unknown]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Funding type \(fundingType) should be accepted when all funding types are explicitly allowed.")
        }
    }

    func testFundingCategoryMapping() {
        XCTAssertEqual(STPCardFundingType.debit.asFundingCategory, .debit)
        XCTAssertEqual(STPCardFundingType.credit.asFundingCategory, .credit)
        XCTAssertEqual(STPCardFundingType.prepaid.asFundingCategory, .prepaid)
        XCTAssertEqual(STPCardFundingType.other.asFundingCategory, .unknown)
    }

    func testDefaultFilter() {
        let filter = CardFundingFilter.default

        for fundingType in STPCardFundingType.allCases {
            XCTAssertTrue(filter.isAccepted(cardFundingType: fundingType), "Default filter should accept all funding types.")
        }
    }

    // MARK: - Apple Pay Merchant Capabilities Tests

    func testApplePayMerchantCapabilities_all() {
        let filter = CardFundingFilter(cardFundingAcceptance: .all)
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNil(capabilities, "When all funding types are accepted, nil should be returned to use the default capabilities on the payment request.")
    }

    func testApplePayMerchantCapabilities_debitOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.debit]))
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertTrue(capabilities!.contains(.capabilityDebit), "Debit capability should be included when debit is allowed.")
        XCTAssertFalse(capabilities!.contains(.capabilityCredit), "Credit capability should not be included when only debit is allowed.")
    }

    func testApplePayMerchantCapabilities_creditOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.credit]))
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertFalse(capabilities!.contains(.capabilityDebit), "Debit capability should not be included when only credit is allowed.")
        XCTAssertTrue(capabilities!.contains(.capabilityCredit), "Credit capability should be included when credit is allowed.")
    }

    func testApplePayMerchantCapabilities_debitAndCredit() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.debit, .credit]))
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities!.contains(.capability3DS), "3DS capability should always be included.")
        XCTAssertTrue(capabilities!.contains(.capabilityDebit), "Debit capability should be included when debit is allowed.")
        XCTAssertTrue(capabilities!.contains(.capabilityCredit), "Credit capability should be included when credit is allowed.")
    }

    func testApplePayMerchantCapabilities_prepaidOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.prepaid]))
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertEqual(capabilities, .capability3DS, "Prepaid is not filterable via merchantCapabilities, so only 3DS should be set.")
    }

    func testApplePayMerchantCapabilities_unknownOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.unknown]))
        let capabilities = filter.applePayMerchantCapabilities()

        XCTAssertEqual(capabilities, .capability3DS, "Unknown is not filterable via merchantCapabilities, so only 3DS should be set.")
    }
}

extension STPCardFundingType: @retroactive CaseIterable {
    public static var allCases: [STPCardFundingType] {
        return [.debit, .credit, .prepaid, .other]
    }
}

//
//  CardFundingFilterTests.swift
//  StripePaymentSheetTests
//
//  Created by Stripe on 11/24/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(CardFundingFilteringPrivatePreview) @testable import StripePaymentSheet
import XCTest

class CardFundingFilterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        STPAnalyticsClient.sharedClient._testLogHistory = []
    }

    func testIsAccepted_allFundingTypesAccepted() {
        let filter = CardFundingFilter(cardFundingAcceptance: .all)

        let allFundingTypes: [STPCardFundingType] = [.credit, .debit, .prepaid, .unknown, .other]
        for fundingType in allFundingTypes {
            XCTAssertTrue(filter.isAccepted(fundingType: fundingType), "Funding type \(fundingType) should be accepted when all funding types are accepted.")
        }
    }

    func testIsAccepted_allowedFundingTypes() {
        let allowedFundingTypes: [PaymentSheet.CardFundingAcceptance.CardFundingCategory] = [.credit, .debit]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        // Credit should be accepted
        XCTAssertTrue(filter.isAccepted(fundingType: .credit), "Credit should be accepted when in allowed list")

        // Debit should be accepted
        XCTAssertTrue(filter.isAccepted(fundingType: .debit), "Debit should be accepted when in allowed list")

        // Prepaid should not be accepted
        XCTAssertFalse(filter.isAccepted(fundingType: .prepaid), "Prepaid should not be accepted when not in allowed list")

        // Unknown should not be accepted (no category mapping)
        XCTAssertFalse(filter.isAccepted(fundingType: .unknown), "Unknown should not be accepted with allow list")

        // Other should not be accepted (no category mapping)
        XCTAssertFalse(filter.isAccepted(fundingType: .other), "Other should not be accepted with allow list")
    }

    func testIsAccepted_disallowedFundingTypes() {
        let disallowedFundingTypes: [PaymentSheet.CardFundingAcceptance.CardFundingCategory] = [.credit, .prepaid]
        let filter = CardFundingFilter(cardFundingAcceptance: .disallowed(fundingTypes: disallowedFundingTypes))

        // Credit should not be accepted
        XCTAssertFalse(filter.isAccepted(fundingType: .credit), "Credit should not be accepted when in disallowed list")

        // Debit should be accepted
        XCTAssertTrue(filter.isAccepted(fundingType: .debit), "Debit should be accepted when not in disallowed list")

        // Prepaid should not be accepted
        XCTAssertFalse(filter.isAccepted(fundingType: .prepaid), "Prepaid should not be accepted when in disallowed list")

        // Unknown should be accepted (no category mapping, accepted by default with disallow list)
        XCTAssertTrue(filter.isAccepted(fundingType: .unknown), "Unknown should be accepted with disallow list")

        // Other should be accepted (no category mapping, accepted by default with disallow list)
        XCTAssertTrue(filter.isAccepted(fundingType: .other), "Other should be accepted with disallow list")
    }

    func testIsAccepted_unknownFundingCategory() {
        let allowedFundingTypes: [PaymentSheet.CardFundingAcceptance.CardFundingCategory] = [.credit]
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: allowedFundingTypes))

        // Funding types without a category should not be accepted with allow list
        XCTAssertFalse(filter.isAccepted(fundingType: .unknown), "Unknown funding type without category should not be accepted.")
        XCTAssertFalse(filter.isAccepted(fundingType: .other), "Other funding type without category should not be accepted.")
    }

    func testIsAccepted_allowsFundingWithNilCategory_whenDisallowed() {
        let disallowedFundingTypes: [PaymentSheet.CardFundingAcceptance.CardFundingCategory] = [.credit]
        let filter = CardFundingFilter(cardFundingAcceptance: .disallowed(fundingTypes: disallowedFundingTypes))

        // Funding types without a category should be accepted with disallow list
        XCTAssertTrue(filter.isAccepted(fundingType: .unknown), "Unknown funding type without category should be accepted.")
        XCTAssertTrue(filter.isAccepted(fundingType: .other), "Other funding type without category should be accepted.")
    }

    func testMerchantCapabilities_all() {
        let filter = CardFundingFilter(cardFundingAcceptance: .all)
        let capabilities = filter.merchantCapabilities()

        // Should only have 3DS capability, no credit/debit restrictions
        XCTAssertEqual(capabilities, .capability3DS, "All funding types should only have 3DS capability")
    }

    func testMerchantCapabilities_creditOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.credit]))
        let capabilities = filter.merchantCapabilities()

        // Should have 3DS + capabilityCredit
        XCTAssertTrue(capabilities.contains(.capability3DS), "Should contain 3DS")
        XCTAssertTrue(capabilities.contains(.capabilityCredit), "Should contain capabilityCredit")
        XCTAssertFalse(capabilities.contains(.capabilityDebit), "Should not contain capabilityDebit")
    }

    func testMerchantCapabilities_debitOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.debit]))
        let capabilities = filter.merchantCapabilities()

        // Should have 3DS + capabilityDebit
        XCTAssertTrue(capabilities.contains(.capability3DS), "Should contain 3DS")
        XCTAssertTrue(capabilities.contains(.capabilityDebit), "Should contain capabilityDebit")
        XCTAssertFalse(capabilities.contains(.capabilityCredit), "Should not contain capabilityCredit")
    }

    func testMerchantCapabilities_prepaidOnly() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.prepaid]))
        let capabilities = filter.merchantCapabilities()

        // Prepaid is handled by delegate, not merchantCapabilities
        // Should only have 3DS
        XCTAssertEqual(capabilities, .capability3DS, "Prepaid only should only have 3DS capability (handled by delegate)")
    }

    func testMerchantCapabilities_creditAndDebit() {
        let filter = CardFundingFilter(cardFundingAcceptance: .allowed(fundingTypes: [.credit, .debit]))
        let capabilities = filter.merchantCapabilities()

        // Both credit and debit allowed = no restriction
        XCTAssertEqual(capabilities, .capability3DS, "Both credit and debit should only have 3DS capability")
    }

    func testMerchantCapabilities_disallowCredit() {
        let filter = CardFundingFilter(cardFundingAcceptance: .disallowed(fundingTypes: [.credit]))
        let capabilities = filter.merchantCapabilities()

        // Disallow credit = allow only debit
        XCTAssertTrue(capabilities.contains(.capability3DS), "Should contain 3DS")
        XCTAssertTrue(capabilities.contains(.capabilityDebit), "Should contain capabilityDebit")
        XCTAssertFalse(capabilities.contains(.capabilityCredit), "Should not contain capabilityCredit")
    }

    func testMerchantCapabilities_disallowDebit() {
        let filter = CardFundingFilter(cardFundingAcceptance: .disallowed(fundingTypes: [.debit]))
        let capabilities = filter.merchantCapabilities()

        // Disallow debit = allow only credit
        XCTAssertTrue(capabilities.contains(.capability3DS), "Should contain 3DS")
        XCTAssertTrue(capabilities.contains(.capabilityCredit), "Should contain capabilityCredit")
        XCTAssertFalse(capabilities.contains(.capabilityDebit), "Should not contain capabilityDebit")
    }

    func testMerchantCapabilities_disallowPrepaid() {
        let filter = CardFundingFilter(cardFundingAcceptance: .disallowed(fundingTypes: [.prepaid]))
        let capabilities = filter.merchantCapabilities()

        // Prepaid disallow is handled by delegate, not merchantCapabilities
        XCTAssertEqual(capabilities, .capability3DS, "Disallowing prepaid should only have 3DS capability (handled by delegate)")
    }

    func testDefault() {
        let filter = CardFundingFilter.default

        // Default should accept all funding types
        XCTAssertTrue(filter.isAccepted(fundingType: .credit))
        XCTAssertTrue(filter.isAccepted(fundingType: .debit))
        XCTAssertTrue(filter.isAccepted(fundingType: .prepaid))
        XCTAssertTrue(filter.isAccepted(fundingType: .unknown))
        XCTAssertTrue(filter.isAccepted(fundingType: .other))
    }

    func testFundingCategoryMapping() {
        // Test that funding types map correctly to categories
        XCTAssertEqual(STPCardFundingType.credit.asFundingCategory, .credit)
        XCTAssertEqual(STPCardFundingType.debit.asFundingCategory, .debit)
        XCTAssertEqual(STPCardFundingType.prepaid.asFundingCategory, .prepaid)
        XCTAssertNil(STPCardFundingType.unknown.asFundingCategory)
        XCTAssertNil(STPCardFundingType.other.asFundingCategory)
    }
}

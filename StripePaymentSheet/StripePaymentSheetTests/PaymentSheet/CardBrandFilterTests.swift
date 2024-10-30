//
//  CardBrandFilterTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/10/24.
//

import XCTest
@testable @_spi(CardBrandFilteringBeta) import StripePaymentSheet
@_spi(STP) import StripeCore

class CardBrandFilterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        STPAnalyticsClient.sharedClient._testLogHistory = []
    }

    func testIsAccepted_allBrandsAccepted() {
        let filter = CardBrandFilter(cardBrandAcceptance: .all)

        for brand in STPCardBrand.allCases {
            XCTAssertTrue(filter.isAccepted(cardBrand: brand), "Brand \(brand) should be accepted when all brands are accepted.")
        }
    }

    func testIsAccepted_allowedBrands() {
        let allowedBrands: [PaymentSheet.CardBrandAcceptance.BrandCategory] = [.visa, .mastercard]
        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: allowedBrands))

        for brand in STPCardBrand.allCases {
            let isExpectedToBeAccepted: Bool
            if let brandCategory = brand.asBrandCategory {
                isExpectedToBeAccepted = allowedBrands.contains(brandCategory)
            } else {
                // Brands without a category should not be accepted
                isExpectedToBeAccepted = false
            }
            let isAccepted = filter.isAccepted(cardBrand: brand)
            XCTAssertEqual(isAccepted, isExpectedToBeAccepted, "Brand \(brand) acceptance mismatch. Expected \(isExpectedToBeAccepted), got \(isAccepted).")
        }
    }

    func testIsAccepted_disallowedBrands() {
        let disallowedBrands: [PaymentSheet.CardBrandAcceptance.BrandCategory] = [.amex, .discover]
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: disallowedBrands))

        for brand in STPCardBrand.allCases {
            let isExpectedToBeAccepted: Bool
            if let brandCategory = brand.asBrandCategory {
                isExpectedToBeAccepted = !disallowedBrands.contains(brandCategory)
            } else {
                // Brands without a category should be accepted
                isExpectedToBeAccepted = true
            }
            let isAccepted = filter.isAccepted(cardBrand: brand)
            XCTAssertEqual(isAccepted, isExpectedToBeAccepted, "Brand \(brand) acceptance mismatch. Expected \(isExpectedToBeAccepted), got \(isAccepted).")
        }
    }

    func testIsAccepted_unknownBrandCategory() {
        let allowedBrands: [PaymentSheet.CardBrandAcceptance.BrandCategory] = [.visa]
        let filter = CardBrandFilter(cardBrandAcceptance: .allowed(brands: allowedBrands))

        for brand in STPCardBrand.allCases where brand.asBrandCategory == nil {
            XCTAssertFalse(filter.isAccepted(cardBrand: brand), "Brand \(brand) without category should be accepted.")
        }
    }

    func testIsAccepted_allowsBrandWithNilCategory_whenDisallowed() {
        let disallowedBrands: [PaymentSheet.CardBrandAcceptance.BrandCategory] = [.visa]
        let filter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: disallowedBrands))

        for brand in STPCardBrand.allCases where brand.asBrandCategory == nil {
            XCTAssertTrue(filter.isAccepted(cardBrand: brand), "Brand \(brand) without category should be accepted.")
        }
    }
}

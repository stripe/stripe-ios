//
//  RotatingCardBrandsViewTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 6/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
import XCTest

@testable import Stripe
@testable @_spi(STP) import StripePaymentSheet

class RotatingCardBrandsViewTests: XCTestCase {

    func testOrdering() {
        XCTAssertEqual([.visa,
                        .mastercard,
                        .amex,
                        .discover,
                        .dinersClub,
                        .JCB,
                        .unionPay,
                        .cartesBancaires,
                       ], RotatingCardBrandsView.orderedCardBrands(from: STPCardBrand.allCases))
    }

    func testRotatesOnMoreThreeOrMoreBrands() {
        let rotatingCardBrandsView = RotatingCardBrandsView()
        rotatingCardBrandsView.cardBrands = [.visa]
        XCTAssertTrue(rotatingCardBrandsView.rotatingCardBrandView.isHidden)
        rotatingCardBrandsView.cardBrands = [.visa, .mastercard]
        XCTAssertTrue(rotatingCardBrandsView.rotatingCardBrandView.isHidden)
        rotatingCardBrandsView.cardBrands = [.visa, .mastercard, .amex]
        XCTAssertTrue(rotatingCardBrandsView.rotatingCardBrandView.isHidden)
        rotatingCardBrandsView.cardBrands = [.visa, .mastercard, .amex, .dinersClub]
        XCTAssertFalse(rotatingCardBrandsView.rotatingCardBrandView.isHidden)
        rotatingCardBrandsView.cardBrands = [.visa, .mastercard, .amex, .dinersClub, .JCB]
        XCTAssertFalse(rotatingCardBrandsView.rotatingCardBrandView.isHidden)
        rotatingCardBrandsView.cardBrands = [.visa, .mastercard, .amex, .dinersClub, .JCB, .cartesBancaires]
        XCTAssertFalse(rotatingCardBrandsView.rotatingCardBrandView.isHidden)
    }

    func testCartesBancairesFirstInRotatingBrands() {
        let view = RotatingCardBrandsView()
        // CB is last in the ordered list, so it would normally be last in rotating brands
        view.cardBrands = [.visa, .mastercard, .amex, .discover, .JCB, .cartesBancaires]
        XCTAssertEqual(view.rotatingCardBrands.first, .cartesBancaires)
    }
}

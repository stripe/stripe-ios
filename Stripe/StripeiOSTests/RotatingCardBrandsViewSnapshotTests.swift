//
//  RotatingCardBrandsViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 6/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) import StripePayments

@testable @_spi(STP) import StripePaymentSheet
@testable import Stripe

class RotatingCardBrandsViewSnapshotTests: FBSnapshotTestCase {


    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testAllCardBrands() {
        let rotatingCardBrandsView = RotatingCardBrandsView()
        rotatingCardBrandsView.cardBrands = RotatingCardBrandsView.orderedCardBrands(from: STPCardBrand.allCases)
        rotatingCardBrandsView.autosizeHeight(width: 140)
        STPSnapshotVerifyView(rotatingCardBrandsView)
    }

    func testSingleCardBrand() {
        let rotatingCardBrandsView = RotatingCardBrandsView()
        rotatingCardBrandsView.cardBrands = [.visa]
        rotatingCardBrandsView.autosizeHeight(width: 140)
        STPSnapshotVerifyView(rotatingCardBrandsView)
    }

}

//
//  ImageTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class ImageTest: XCTestCase {
    func testAllImagesExist() throws {
        for image in Image.allCases {
            let image = UIImage(
                named: image.rawValue,
                in: StripePaymentSheetBundleLocator.resourcesBundle,
                compatibleWith: nil
            )
            XCTAssertNotNil(image)
        }
    }
}

//
//  ImageTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class ImageTest: XCTestCase {
    func testAllImagesExist() throws {
        for image in Image.allCases {
            let image = UIImage(
                named: image.rawValue,
                in: StripeBundleLocator.resourcesBundle, compatibleWith: nil
            )
            XCTAssertNotNil(image)
        }
    }
}

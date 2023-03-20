//
//  StripeIdentityAssetTests.swift
//  StripeIdentityAssetTests
//

import UIKit
import XCTest

@testable import StripeIdentity
@_spi(STP) import StripeUICore

class StripeIdentityAssetTests: XCTestCase {
    
    func testImages() {
        let emptyImage = UIImage()
        for image in StripeIdentity.Image.allCases {
            let safeImage = image.makeImage()
            XCTAssert(!safeImage.isEqual(emptyImage))
        }
    }
}

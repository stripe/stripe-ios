//
//  StripeIdentityAssetTests.swift
//  StripeIdentityAssetTests
//

@_spi(STP) import StripeUICore
import UIKit
import XCTest

@_spi(STP) import StripeIdentity

class StripeIdentityAssetTests: XCTestCase {

    func testImages() {
        let emptyImage = UIImage()
        for image in StripeIdentity.Image.allCases {
            let safeImage = image.makeImage()
            XCTAssert(!safeImage.isEqual(emptyImage))
        }
    }
}

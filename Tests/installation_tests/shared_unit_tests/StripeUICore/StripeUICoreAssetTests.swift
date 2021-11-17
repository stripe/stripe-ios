//
//  StripeUICoreAssetTests.swift
//  StripeUICoreAssetTests
//

import UIKit
import XCTest

@_spi(STP) import StripeUICore

class StripeUICoreAssetTests: XCTestCase {
    
    func testImages() {
        let emptyImage = UIImage()
        for image in StripeUICore.Image.allCases {
            let safeImage = image.makeImage()
            XCTAssert(!safeImage.isEqual(emptyImage))
        }
    }
}

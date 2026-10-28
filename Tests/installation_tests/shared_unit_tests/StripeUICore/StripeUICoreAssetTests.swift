//
//  StripeUICoreAssetTests.swift
//  StripeUICoreAssetTests
//

@_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

class StripeUICoreAssetTests: XCTestCase {

    func testImages() {
        let emptyImage = UIImage()
        for image in StripeUICore.Image.allCases {
            let safeImage = image.makeImage()
            XCTAssert(!safeImage.isEqual(emptyImage))
        }
    }
}

//
//  PaymentSheetSnapshotTests.swift
//  PaymentSheetUITest
//
//  Created by Nick Porter on 2/25/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe
@_spi(STP) @testable import StripeUICore

class PaymentSheetSnapshotTests: FBSnapshotTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }
    
    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }
    
    func testPaymentSheetStandardCardSnapshot() throws {
        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()

        XCTAssertTrue(app.buttons["Pay €9.73"].waitForExistence(timeout: 60.0))
        let screenshot = app.screenshot().image.removingStatusBar
        let imageView = UIImageView(image: screenshot)
        
        verify(imageView)
    }
    
    // Test sepa to ensure the address section looks correct
    func testPaymentSheetStandardSEPASnapshot() throws {
        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()

        XCTAssertTrue(app.buttons["Pay €9.73"].waitForExistence(timeout: 60.0))
        
        // Select SEPA
        guard let sepa = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "SEPA Debit") else {
            XCTFail()
            return
        }
        sepa.tap()
        let _ = app.textFields["IBAN"].waitForExistence(timeout: 60.0)
        
        let screenshot = app.screenshot().image.removingStatusBar
        let imageView = UIImageView(image: screenshot)
        verify(imageView)
    }
    
    func testPaymentSheetCustomSnapshot() throws {
        app.staticTexts["PaymentSheet (Custom)"].tap()
        let paymentMethodButton = app.staticTexts["Apple Pay"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        
        let screenshot = app.screenshot().image.removingStatusBar
        let imageView = UIImageView(image: screenshot)
        verify(imageView)
    }
    
    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 375)
        /*
         Needed to introduce <1% tolerance, the snapshot isn't pixel perfect. For some reason the image captured on CI is slightly different, but nothing noticeable to the eye. I toyed around with the cornerRadius and spacing of elements by just 1pt and noticed that these tests would fail, so I think they should still satisfy what we're trying to accomplish with these tests.
         */
        FBSnapshotVerifyView(view,
                             identifier: identifier,
                             suffixes: FBSnapshotTestCaseDefaultSuffixes(),
                             perPixelTolerance: 0.009,
                             overallTolerance: 0.009,
                             file: file,
                             line: line)
    }
}

private extension UIImage {

    var removingStatusBar: UIImage? {
        guard let cgImage = cgImage else {
            return nil
        }

        let yOffset = 44 * scale
        let rect = CGRect(
            x: 0,
            y: Int(yOffset),
            width: cgImage.width,
            height: cgImage.height - Int(yOffset)
        )

        if let croppedCGImage = cgImage.cropping(to: rect) {
            return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
        }

        return nil
    }
}

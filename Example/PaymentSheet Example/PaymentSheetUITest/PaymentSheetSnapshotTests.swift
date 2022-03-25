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
        testCard()
    }
    
    // Test sepa to ensure the address section looks correct
    func testPaymentSheetStandardSEPASnapshot() throws {
        testSepa()
    }
    
    func testPaymentSheetCustomSnapshot() throws {
        testCustom()
    }
    
    func testPaymentSheetStandardCardSnapshot_darkMode() throws {
        launchInDarkMode()
        testCard()
    }
    
    // Test sepa to ensure the address section looks correct
    func testPaymentSheetStandardSEPASnapshot_darkMode() throws {
        launchInDarkMode()
        testSepa()
    }
    
    func testPaymentSheetCustomSnapshot_darkMode() throws {
        launchInDarkMode()
        testCustom()
    }
    
    func testCardRespectsDynamicType() {
        launchWithXLDynamicType()
        testCard()
    }
    
    func testCustomRespectsDynamicType() {
        launchWithXLDynamicType()
        testCustom()
    }
    
    func testCustomWithAppearance() {
        app.staticTexts["PaymentSheet (test playground)"].tap()
        
        applySnapshotTestingAppearance()
        reload()
        let paymentMethodButton = app.buttons["present_saved_pms"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        
        let screenshot = app.screenshot().image.removingStatusBar
        let imageView = UIImageView(image: screenshot)
        verify(imageView)
    }
    
    // Test sepa as it has a lot of UI elements which make it a good candidate
    func testSepaWithAppearance() {
        app.staticTexts["PaymentSheet (test playground)"].tap()
        
        applySnapshotTestingAppearance()
        
        app.buttons["new"].tap() // new customer
        app.buttons["EUR"].tap() // EUR currency
        app.buttons["true"].tap() // delayed payment methods
        reload()
        app.buttons["Checkout (Complete)"].tap()

        XCTAssertTrue(app.buttons["Pay €50.99"].waitForExistence(timeout: 60.0))

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
    
    // Tests that the section container view animates properly when changing height
    func testSepaAnimatesSection() {
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
        
        // Change country to get section to animate
        let countryPicker = app.textFields["Country or region"]
        countryPicker.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Tuvalu")
        app.toolbars.buttons["Done"].tap()
        sepa.tap() // dismiss keyboard after auto stepping to next field
        
        let _ = app.textFields["IBAN"].waitForExistence(timeout: 60.0)
        
        let screenshot = app.screenshot().image.removingStatusBar
        let imageView = UIImageView(image: screenshot)
        verify(imageView)
    }
    
    private func testCard() {
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
    
    private func testCustom() {
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
    
    private func testSepa() {
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
    
    private func launchInDarkMode() {
        app = XCUIApplication()
        app.launchArguments.append("UITestingDarkModeEnabled")
        app.launch()
    }
    
    private func launchWithXLDynamicType() {
        app = XCUIApplication()
        app.launchArguments += [ "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL" ]
        app.launch()
    }
    
    private func applySnapshotTestingAppearance() {
        let appearanceButton = app.buttons["appearance_button"]
        XCTAssertTrue(appearanceButton.waitForExistence(timeout: 60.0))
        appearanceButton.tap()
        app.scrollViews.accessibilityScroll(.down)
        XCTAssertTrue(app.buttons["testing_appearance"].waitForExistence(timeout: 60.0))
        app.buttons["testing_appearance"].tap()
        
        XCTAssertTrue(app.buttons["Checkout (Complete)"].waitForExistence(timeout: 60.0))
    }
    
    private func reload() {
        app.buttons["Reload PaymentSheet"].tap()

        let checkout = app.buttons["Checkout (Complete)"]
        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: checkout,
            handler: nil
        )
        waitForExpectations(timeout: 10, handler: nil)
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

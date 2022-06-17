//
//  PaymentSheet+ShippingTests.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 6/16/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheet_ShippingTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    func testShippingManual() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        
        // The Continue button should be disabled
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        
        // Tapping the address line 1 field should go to autocomplete
        app.textFields["Address line 1"].tap()
        app.buttons["Enter address manually"].tap()
        
        // Tapping the address line 1 field should now just let us enter the field manually
        app.textFields["Address line 1"].tap()
        app.typeText("510 Townsend St")
        app.textFields["Address line 2"].tap()
        app.typeText("Apt 152")
        app.textFields["City"].tap()
        app.typeText("San Francisco")
        app.textFields["State"].tap()
        app.typeText("California")
        // The continue button should still be disabled until we fill in all required fields
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
        
        // The merchant app should get back the expected address
        XCTAssertEqual(shippingButton.label, "510 Townsend St, Apt 152, San Francisco California 94102, US")
        
        // Opening the shipping address back up...
        shippingButton.tap()
        // ...and editing ZIP to be invalid...
        let zip = app.textFields["ZIP"]
        XCTAssertEqual(zip.value as! String, "94102")
        zip.tap()
        app.typeText(XCUIKeyboardKey.delete.rawValue) // Invalid length
        // ...should disable the continue button
        XCTAssertFalse(continueButton.isEnabled)
        // If we dismiss the sheet while its invalid...
        app.buttons["Close"].tap()
        // The merchant app should get back nil
        XCTAssertEqual(shippingButton.label, "Add")
    }
}

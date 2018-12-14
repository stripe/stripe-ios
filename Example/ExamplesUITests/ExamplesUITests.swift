//
//  ExamplesUITests.swift
//  ExamplesUITests
//
//  Created by Aaltan Ahmad on 11/20/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

import XCTest

class ExamplesUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func takeScreenshot(name: String) {
        let app = XCUIApplication()
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        attachment.name = name
        add(attachment)
    }
    
    func waitForElementToAppear(_ element: XCUIElement) {
        XCTAssert(element.waitForExistence(timeout: 5), "An exepected element did not appear on screen: \(element)")
    }
    
    func testVisitAll() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        
        // Visit Add Card VC
        tablesQuery.staticTexts["STPPaymentCardTextField"].tap()
        waitForElementToAppear(app.navigationBars.buttons["CardFieldViewControllerDoneButtonIdentifier"])
        // tapping expiry date field shows all forms
        app.textFields["expiration date"].tap()
        takeScreenshot(name: "Add Card")

        app.navigationBars.buttons["CardFieldViewControllerDoneButtonIdentifier"].tap()
        
        // Visit Card Form VC
        tablesQuery.staticTexts["Card Form with Billing Address"].tap()
        
        waitForElementToAppear(app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"])
        takeScreenshot(name: "Card Form with Billing Address")
        // TODO : Looks like we'll need new code to preset address and change type to delivery
        // TODO : Fill with invalid info, press next. Wait for error to pop up. screenshot
        app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"].tap()
        
        // Visit Payment Method VC
        tablesQuery.staticTexts["Payment Method Picker"].tap()
        // TODO: Add code for long loading...
        waitForElementToAppear(tablesQuery.cells["PaymentMethodTableViewAddNewCardButtonIdentifier"])
        takeScreenshot(name: "Payment Method Picker")
        
        // Add a new card in the Payment Method VC
        tablesQuery.cells["PaymentMethodTableViewAddNewCardButtonIdentifier"].tap()
        waitForElementToAppear(app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"])
        takeScreenshot(name: "Payment Method Picker - Add Card")
        
        app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"].tap()
        app.buttons["PaymentMethodViewControllerCancelButtonIdentifier"].tap()
        
        // Visit the Shipping Info VC
        tablesQuery.staticTexts["Shipping Info Form"].tap()
        waitForElementToAppear(app.navigationBars.buttons["ShippingViewControllerNextButtonIdentifier"])
        takeScreenshot(name: "Shipping Info")
        
        // Fill out the Shipping Info
        tablesQuery.textFields["ShippingAddressFieldTypeNameIdentifier"].typeText("Test")
        
        tablesQuery.textFields["ShippingAddressFieldTypeLine1Identifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeLine1Identifier"].typeText("Test")
        
        tablesQuery.textFields["ShippingAddressFieldTypeLine2Identifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeLine2Identifier"].typeText("Test")
        
        tablesQuery.textFields["ShippingAddressFieldTypeZipIdentifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeZipIdentifier"].typeText("1001")
        
        tablesQuery.textFields["ShippingAddressFieldTypeCityIdentifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeCityIdentifier"].typeText("Kabul")
        
        tablesQuery.textFields["ShippingAddressFieldTypeStateIdentifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeStateIdentifier"].typeText("Kabul")
        
        tablesQuery.textFields["ShippingAddressFieldTypeCountryIdentifier"].tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "Afghanistan")
        
        // Go to Shipping Methods
        app.navigationBars.buttons["ShippingViewControllerNextButtonIdentifier"].tap()
        waitForElementToAppear(app.navigationBars.buttons["ShippingMethodsViewControllerDoneButtonIdentifier"])
        takeScreenshot(name: "Shipping Methods")
        
        // Back to main menu
        app.navigationBars.buttons["ShippingMethodsViewControllerDoneButtonIdentifier"].tap()
    }
    
}


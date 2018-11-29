//
//  Stripe_UI_ExamplesUITests.swift
//  Stripe UI ExamplesUITests
//
//  Created by Aaltan Ahmad on 11/20/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

import XCTest

class ExamplesUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["STPPaymentCardTextField"]/*[[".cells.staticTexts[\"STPPaymentCardTextField\"]",".staticTexts[\"STPPaymentCardTextField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        waitForElementToAppear(app.navigationBars.buttons["CardFieldViewControllerDoneButtonIdentifier"])
        takeScreenshot(name: "Add Card")
        app.navigationBars.buttons["CardFieldViewControllerDoneButtonIdentifier"].tap()
        
        // Visit Card Form VC
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Card Form with Billing Address"]/*[[".cells.staticTexts[\"Card Form with Billing Address\"]",".staticTexts[\"Card Form with Billing Address\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        waitForElementToAppear(app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"])
        takeScreenshot(name: "Card Form with Billing Address")
        app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"].tap()
        
        // Visit Payment Method VC
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Payment Method Picker"]/*[[".cells.staticTexts[\"Payment Method Picker\"]",".staticTexts[\"Payment Method Picker\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        waitForElementToAppear(tablesQuery.cells["PaymentMethodTableViewAddNewCardButtonIdentifier"])
        takeScreenshot(name: "Payment Method Picker")
        
        // Add a new card in the Payment Method VC
        tablesQuery.cells["PaymentMethodTableViewAddNewCardButtonIdentifier"].tap()
        waitForElementToAppear(app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"])
        takeScreenshot(name: "Payment Method Picker - Add Card")
        
        app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"].tap()
        app.buttons["PaymentMethodViewControllerCancelButtonIdentifier"].tap()
        
        // Visit the Shipping Info VC
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Shipping Info Form"]/*[[".cells.staticTexts[\"Shipping Info Form\"]",".staticTexts[\"Shipping Info Form\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        waitForElementToAppear(app.navigationBars/*@START_MENU_TOKEN@*/.buttons["ShippingViewControllerNextButtonIdentifier"]/*[[".buttons[\"Next\"]",".buttons[\"ShippingViewControllerNextButtonIdentifier\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/)
        takeScreenshot(name: "Shipping Info")
        
        // Fill out the Shipping Info
        tablesQuery.textFields["ShippingAddressFieldTypeNameIdentifier"].typeText("Test")
        
        tablesQuery.textFields["ShippingAddressFieldTypeLine1Identifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeLine1Identifier"].typeText("Test")
        
        tablesQuery.textFields["ShippingAddressFieldTypeLine2Identifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeLine2Identifier"].typeText("Test")
        
        tablesQuery.textFields["ShippingAddressFieldTypeZipIdentifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeZipIdentifier"].typeText("95014")
        
        tablesQuery.textFields["ShippingAddressFieldTypeCityIdentifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeCityIdentifier"].typeText("Cupertino")
        
        tablesQuery.textFields["ShippingAddressFieldTypeStateIdentifier"].tap()
        tablesQuery.textFields["ShippingAddressFieldTypeStateIdentifier"].typeText("CA")
        
        tablesQuery.textFields["ShippingAddressFieldTypeCountryIdentifier"].tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "Afghanistan")
        
        // Go to Shipping Methods
        app.navigationBars/*@START_MENU_TOKEN@*/.buttons["ShippingViewControllerNextButtonIdentifier"]/*[[".buttons[\"Next\"]",".buttons[\"ShippingViewControllerNextButtonIdentifier\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        waitForElementToAppear(app.navigationBars.buttons["ShippingMethodsViewControllerDoneButtonIdentifier"])
        takeScreenshot(name: "Shipping Methods")
        
        // Back to main menu
        app.navigationBars.buttons["ShippingMethodsViewControllerDoneButtonIdentifier"].tap()
    }
    
}


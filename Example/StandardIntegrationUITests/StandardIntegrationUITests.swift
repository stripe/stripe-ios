//
//  StandardIntegrationUITests.swift
//  StandardIntegrationUITests
//
//  Created by David Estes on 8/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import XCTest

class StandardIntegrationUITests: XCTestCase {

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        let stripePublishableKey = "pk_test_6Q7qTzl8OkUj5K5ArgayVsFD00Sa5AHMj3"
        let backendBaseURL = "https://stripe-mobile-test-backend.herokuapp.com/"
        app.launchArguments.append(contentsOf: ["-StripePublishableKey", stripePublishableKey, "-StripeBackendBaseURL", backendBaseURL])
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func disableAddressEntry(_ app: XCUIApplication) {
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tap()
        app.tables.children(matching: .cell).element(boundBy: 8).staticTexts["None"].tap()
        app.navigationBars["Settings"].buttons["Done"].tap()
    }
    
    func selectItems(_ app: XCUIApplication) {
        let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier:"👠").element.tap()
        app.collectionViews.staticTexts["👞"].tap()
        cellsQuery.otherElements.containing(.staticText, identifier:"👗").children(matching: .other).element(boundBy: 0).tap()
    }
    
    func waitToAppear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }
    
    func testSimpleTransaction() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)
        
        app.buttons["Buy Now"].tap()
        app.tables.otherElements.containing(.staticText, identifier:"Pay from").children(matching: .button).element.tap()
        let visa = app.tables.staticTexts["Visa Ending In 4242"]
        waitToAppear(visa)
        visa.tap()
        app.buttons["Buy"].tap()
        let success = app.alerts["Success"].buttons["OK"]
        waitToAppear(success)
        success.tap()
    }
    
    func test3DS1() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()

        app.tables.otherElements.containing(.staticText, identifier:"Pay from").children(matching: .button).element.tap()
        let visa3063 = app.tables.staticTexts["Visa Ending In 3063"]
        waitToAppear(visa3063)
        visa3063.tap()

        let buyButton = app.buttons["Buy"]
        buyButton.tap()
        
        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
        waitToAppear(completeAuth)
        completeAuth.tap()
        let successButton = app.alerts["Success"].buttons["OK"]
        waitToAppear(successButton)
        successButton.tap()
        buyButton.tap()

        let failAuth = webViewsQuery.buttons["FAIL AUTHENTICATION"]
        waitToAppear(failAuth)
        failAuth.tap()
        let errorButton = app.alerts["Error"].buttons["OK"]
        waitToAppear(errorButton)
        errorButton.tap()
    }
    
    func test3DS2() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        app.tables.otherElements.containing(.staticText, identifier:"Pay from").children(matching: .button).element.tap()
        let visa = app.tables.staticTexts["Visa Ending In 3220"]
        waitToAppear(visa)
        visa.tap()
        app.buttons["Buy"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let learnMore = elementsQuery.staticTexts["Learn more about authentication"]
        waitToAppear(learnMore)
        learnMore.tap()
        elementsQuery.staticTexts["Need help?"].tap()
        app.scrollViews.otherElements.buttons["Continue"].tap()
        let success = app.alerts["Success"].buttons["OK"]
        waitToAppear(success)
        success.tap()
    }
    
    func testPopApplePaySheet() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        
        let tablesQuery = app.tables
        tablesQuery.otherElements.containing(.staticText, identifier:"Pay from").children(matching: .button).element.tap()
        let applePay = tablesQuery.staticTexts["Apple Pay"]
        waitToAppear(applePay)
        applePay.tap()
        app.buttons["Buy"].tap()
    }
    
    func testCCEntry() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)
        
        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        let tablesQuery = app.tables
        tablesQuery.otherElements.containing(.staticText, identifier:"Pay from").children(matching: .button).element.tap()
        
        let addButton = app.tables.staticTexts["Add New Card…"]
        waitToAppear(addButton)
        addButton.tap()
        
        let cardNumberField = tablesQuery.textFields["card number"]
        let cvcField = tablesQuery.textFields["CVC"]
        let expirationDateField = tablesQuery.textFields["expiration date"]
        cardNumberField.tap()
        cardNumberField.typeText("4000000000000069")
        expirationDateField.tap()
        expirationDateField.typeText("02/28")
        cvcField.tap()
        cvcField.typeText("223")

        let addcardviewcontrollernavbardonebuttonidentifierButton = app.navigationBars["Add a Card"].buttons["AddCardViewControllerNavBarDoneButtonIdentifier"]
        addcardviewcontrollernavbardonebuttonidentifierButton.tap()
        app.alerts["Your card has expired"].buttons["OK"].tap()
        cardNumberField.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4)
        cardNumberField.typeText(deleteString)
        cardNumberField.typeText("0341")
        addcardviewcontrollernavbardonebuttonidentifierButton.tap()
        let buyButton = app.buttons["Buy"]
        waitToAppear(buyButton)
        buyButton.tap()
        let errorButton = app.alerts["Error"].buttons["OK"]
        waitToAppear(errorButton)
        errorButton.tap()
    }

}

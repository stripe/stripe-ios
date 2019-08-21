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
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["👞"]/*[[".cells.staticTexts[\"👞\"]",".staticTexts[\"👞\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
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
        let visa = app.tables/*@START_MENU_TOKEN@*/.staticTexts["Visa Ending In 4242"]/*[[".cells.staticTexts[\"Visa Ending In 4242\"]",".staticTexts[\"Visa Ending In 4242\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
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
        let visa3063 = app.tables/*@START_MENU_TOKEN@*/.staticTexts["Visa Ending In 3063"]/*[[".cells.staticTexts[\"Visa Ending In 3063\"]",".staticTexts[\"Visa Ending In 3063\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(visa3063)
        visa3063.tap()

        let buyButton = app.buttons["Buy"]
        buyButton.tap()
        
        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery/*@START_MENU_TOKEN@*/.buttons["COMPLETE AUTHENTICATION"]/*[[".otherElements[\"Stripe payment test page\"]",".otherElements[\"main\"].buttons[\"COMPLETE AUTHENTICATION\"]",".buttons[\"COMPLETE AUTHENTICATION\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(completeAuth)
        completeAuth.tap()
        var returnToMerchant = webViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["Return to Merchant"]/*[[".links.matching(identifier: \"Return to Merchant\").staticTexts[\"Return to Merchant\"]",".staticTexts[\"Return to Merchant\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(returnToMerchant)
        returnToMerchant.tap()
        let successButton = app.alerts["Success"].buttons["OK"]
        waitToAppear(successButton)
        successButton.tap()
        buyButton.tap()

        let failAuth = webViewsQuery/*@START_MENU_TOKEN@*/.buttons["FAIL AUTHENTICATION"]/*[[".otherElements[\"Stripe payment test page\"]",".otherElements[\"main\"].buttons[\"FAIL AUTHENTICATION\"]",".buttons[\"FAIL AUTHENTICATION\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(failAuth)
        failAuth.tap()
        returnToMerchant = webViewsQuery/*@START_MENU_TOKEN@*/.staticTexts["Return to Merchant"]/*[[".links.matching(identifier: \"Return to Merchant\").staticTexts[\"Return to Merchant\"]",".staticTexts[\"Return to Merchant\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(returnToMerchant)
        app.buttons["Close"].tap()
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
        let visa = app.tables/*@START_MENU_TOKEN@*/.staticTexts["Visa Ending In 3220"]/*[[".cells.staticTexts[\"Visa Ending In 3220\"]",".staticTexts[\"Visa Ending In 3220\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(visa)
        visa.tap()
        app.buttons["Buy"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let learnMore = elementsQuery/*@START_MENU_TOKEN@*/.staticTexts["Learn more about authentication"]/*[[".otherElements.matching(identifier: \"STDSExpandableInformationView\").staticTexts[\"Learn more about authentication\"]",".staticTexts[\"Learn more about authentication\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(learnMore)
        learnMore.tap()
        elementsQuery/*@START_MENU_TOKEN@*/.staticTexts["Need help?"]/*[[".otherElements.matching(identifier: \"STDSExpandableInformationView\").staticTexts[\"Need help?\"]",".staticTexts[\"Need help?\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.buttons["Continue"]/*[[".buttons[\"Complete Authentication\"]",".buttons[\"Continue\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
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
        let applePay = tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Apple Pay"]/*[[".cells.staticTexts[\"Apple Pay\"]",".staticTexts[\"Apple Pay\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
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
        
        let addButton = app.tables/*@START_MENU_TOKEN@*/.staticTexts["Add New Card…"]/*[[".cells[\"PaymentOptionsTableViewAddNewCardButtonIdentifier\"].staticTexts[\"Add New Card…\"]",".staticTexts[\"Add New Card…\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        waitToAppear(addButton)
        addButton.tap()
        
        let cardNumberField = tablesQuery/*@START_MENU_TOKEN@*/.textFields["card number"]/*[[".cells.textFields[\"card number\"]",".textFields[\"card number\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let cvcField = tablesQuery/*@START_MENU_TOKEN@*/.textFields["CVC"]/*[[".cells.textFields[\"CVC\"]",".textFields[\"CVC\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expirationDateField = tablesQuery/*@START_MENU_TOKEN@*/.textFields["expiration date"]/*[[".cells.textFields[\"expiration date\"]",".textFields[\"expiration date\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        cardNumberField.tap()
        cardNumberField.typeText("4000000000000069")
        expirationDateField.tap()
        expirationDateField.typeText("02/28")
        cvcField.tap()
        cvcField.typeText("223")

        let addcardviewcontrollernavbardonebuttonidentifierButton = app.navigationBars["Add a Card"]/*@START_MENU_TOKEN@*/.buttons["AddCardViewControllerNavBarDoneButtonIdentifier"]/*[[".buttons[\"Done\"]",".buttons[\"AddCardViewControllerNavBarDoneButtonIdentifier\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
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

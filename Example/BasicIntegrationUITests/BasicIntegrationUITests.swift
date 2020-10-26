//
//  BasicIntegrationUITests.swift
//  BasicIntegrationUITests
//
//  Created by David Estes on 8/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import XCTest

extension XCUIElement {
  func tapInTestCase(testCase: XCTestCase) {
    let predicate = NSPredicate(format: "hittable == true")
    testCase.expectation(for: predicate, evaluatedWith: self, handler: nil)
    testCase.waitForExpectations(timeout: 10.0, handler: nil)
    self.tap()
  }
}

class BasicIntegrationUITests: XCTestCase {

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        let stripePublishableKey = "pk_test_6Q7qTzl8OkUj5K5ArgayVsFD00Sa5AHMj3"
        let backendBaseURL = "https://stripe-mobile-test-backend-17.herokuapp.com/"
        app.launchArguments.append(contentsOf: ["-StripePublishableKey", stripePublishableKey, "-StripeBackendBaseURL", backendBaseURL])
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func disableAddressEntry(_ app: XCUIApplication) {
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tap()
        let noneButton = app.tables.children(matching: .cell).element(boundBy: 12).staticTexts["None"]
        waitToAppear(noneButton)
        app.tables.firstMatch.swipeUp()
        noneButton.tapInTestCase(testCase: self)
        app.navigationBars["Settings"].buttons["Done"].tap()
    }

    func selectItems(_ app: XCUIApplication) {
        let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier: "👠").element.tap()
        app.collectionViews.staticTexts["👞"].tap()
        cellsQuery.otherElements.containing(.staticText, identifier: "👗").children(matching: .other).element(boundBy: 0).tap()
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
        app.buttons.matching(identifier: "Pay from").element.tap()
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

        app.buttons.matching(identifier: "Pay from").element.tap()
        let visa3063 = app.tables.staticTexts["Visa Ending In 3063"]
        waitToAppear(visa3063)
        visa3063.tap()

        let buyButton = app.buttons["Buy"]
        buyButton.tap()

        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
        waitToAppear(completeAuth)
        completeAuth.tapInTestCase(testCase: self)
        let successButton = app.alerts["Success"].buttons["OK"]
        waitToAppear(successButton)
        successButton.tapInTestCase(testCase: self)
        buyButton.tap()

        let failAuth = webViewsQuery.buttons["FAIL AUTHENTICATION"]
        waitToAppear(failAuth)
        failAuth.tapInTestCase(testCase: self)
        let errorButton = app.alerts["Error"].buttons["OK"]
        waitToAppear(errorButton)
        errorButton.tapInTestCase(testCase: self)
    }

    func test3DS2() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        app.buttons.matching(identifier: "Pay from").element.tap()
        let visa = app.tables.staticTexts["Visa Ending In 3220"]
        waitToAppear(visa)
        visa.tap()
        app.buttons["Buy"].tap()

        let elementsQuery = app.scrollViews.otherElements
        let learnMore = elementsQuery.buttons["Learn more about authentication"]
        waitToAppear(learnMore)
        learnMore.tap()
        elementsQuery.buttons["Need help?"].tap()
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
        app.buttons.matching(identifier: "Pay from").element.tap()
        let tablesQuery = app.tables
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
        app.buttons.matching(identifier: "Pay from").element.tap()
        let tablesQuery = app.tables
        let addButton = app.tables.staticTexts["Add New Card…"]
        waitToAppear(addButton)
        addButton.tap()

        let cardNumberField = tablesQuery.textFields["card number"]
        let cvcField = tablesQuery.textFields["CVC"]
        let zipField = tablesQuery.textFields["ZIP"]
        cardNumberField.tap()
        cardNumberField.typeText("4000000000000069")
        let expirationDateField = tablesQuery.textFields["expiration date"]
        expirationDateField.typeText("02/28")
        cvcField.typeText("223")
        zipField.typeText("90210")

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

    func testPaymentOptionsDefault() {
        // Note that the example backend creates a new Customer every time you start the app
        // A STPPaymentOptionsVC w/o a selected card...
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)
        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tap()

        let tablesQuery = app.tables

        // ...preselects Apple Pay by default
        let applePay = tablesQuery.cells["Apple Pay"]
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)

        // Selecting another payment method...
        let visa = tablesQuery.cells["Visa Ending In 3220"]
        visa.tap()

        // ...and resetting the PaymentOptions VC...
        // Note that STPPaymentContext clears its cache and refetches every time it's initialized, which happens whenever CheckoutViewController is pushed on
        app.navigationBars["Checkout"].buttons["Products"].tap()
        buyNowButton.tap()
        payFromButton.tap()

        // ...should keep the 3220 card selected
        XCTAssertTrue(visa.isSelected)
        XCTAssertFalse(applePay.isSelected)

        // Reselecting Apple Pay...
        applePay.tap()

        // ...and resetting the PaymentOptions VC...
        app.navigationBars["Checkout"].buttons["Products"].tap()
        buyNowButton.tap()
        payFromButton.tap()

        // ...should keep Apple Pay selected
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)

        // Selecting another payment method...
        visa.tap()

        // ...and logging out...
        app.navigationBars["Checkout"].buttons["Products"].tap()
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tap()
        app.tables.children(matching: .cell).element(boundBy: 18).staticTexts["Log out"].tap()
        app.navigationBars["Settings"].buttons["Done"].tap()

        // ...and going back to PaymentOptionsVC...
        buyNowButton.tap()
        payFromButton.tap()

        // ..should not retain the visa default
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)
    }
}

class FrenchAndBelizeBasicIntegrationUITests: XCTestCase {

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        let stripePublishableKey = "pk_test_6Q7qTzl8OkUj5K5ArgayVsFD00Sa5AHMj3"
        let backendBaseURL = "https://stripe-mobile-test-backend-17.herokuapp.com/"
        app.launchArguments.append(contentsOf: ["-StripePublishableKey", stripePublishableKey, "-StripeBackendBaseURL", backendBaseURL, "-AppleLanguages", "(fr)", "-AppleLocale", "en_BZ"])
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func disableAddressEntry(_ app: XCUIApplication) {
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tap()
        app.tables.children(matching: .cell).element(boundBy: 12).staticTexts["None"].tap()
        waitToAppear(app.navigationBars["Settings"].buttons["OK"])
        app.navigationBars["Settings"].buttons["OK"].tap()
    }

    func selectItems(_ app: XCUIApplication) {
        let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier: "👠").element.tap()
        app.collectionViews.staticTexts["👞"].tap()
        cellsQuery.otherElements.containing(.staticText, identifier: "👗").children(matching: .other).element(boundBy: 0).tap()
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
        app.buttons.matching(identifier: "Pay from").element.tap()
        let visa = app.tables.staticTexts["Visa se terminant par 4242"]
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

        app.buttons.matching(identifier: "Pay from").element.tap()
        let visa3063 = app.tables.staticTexts["Visa se terminant par 3063"]
        waitToAppear(visa3063)
        visa3063.tap()

        let buyButton = app.buttons["Buy"]
        buyButton.tapInTestCase(testCase: self)

        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
        waitToAppear(completeAuth)
        completeAuth.tapInTestCase(testCase: self)
        let successButton = app.alerts["Success"].buttons["OK"]
        waitToAppear(successButton)
        successButton.tapInTestCase(testCase: self)
        buyButton.tap()

        let failAuth = webViewsQuery.buttons["FAIL AUTHENTICATION"]
        waitToAppear(failAuth)
        failAuth.tapInTestCase(testCase: self)
        let errorButton = app.alerts["Error"].buttons["OK"]
        waitToAppear(errorButton)
        errorButton.tapInTestCase(testCase: self)
    }

    func test3DS2() {
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        app.buttons.matching(identifier: "Pay from").element.tap()
        let visa = app.tables.staticTexts["Visa se terminant par 3220"]
        waitToAppear(visa)
        visa.tap()
        app.buttons["Buy"].tap()

        let elementsQuery = app.scrollViews.otherElements
        let learnMore = elementsQuery.buttons["Learn more about authentication"]
        waitToAppear(learnMore)
        learnMore.tap()
        elementsQuery.buttons["Need help?"].tap()
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

        app.buttons.matching(identifier: "Pay from").element.tap()
        let tablesQuery = app.tables
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
        app.buttons.matching(identifier: "Pay from").element.tap()

        let addButton = app.tables.staticTexts["Ajouter une nouvelle carte..."]
        waitToAppear(addButton)
        addButton.tap()

        let tablesQuery = app.tables
        let cardNumberField = tablesQuery.textFields["numéro de carte"]
        let cvcField = tablesQuery.textFields["Code CVC"]
        let expirationDateField = tablesQuery.textFields["date d\'expiration"]
        cardNumberField.tap()
        cardNumberField.typeText("4000000000000069")
        expirationDateField.typeText("02/28")
        cvcField.typeText("223")

        let addcardviewcontrollernavbardonebuttonidentifierButton = app.navigationBars["Ajouter une carte"].buttons["AddCardViewControllerNavBarDoneButtonIdentifier"]
        addcardviewcontrollernavbardonebuttonidentifierButton.tap()
        app.alerts["Votre carte est arrivée à expiration."].buttons["OK"].tap()
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

    func testPaymentOptionsDefault() {
        // Note that the example backend creates a new Customer every time you start the app
        // A STPPaymentOptionsVC w/o a selected card...
        let app = XCUIApplication()
        disableAddressEntry(app)
        selectItems(app)
        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tap()
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tap()

        let tablesQuery = app.tables

        // ...preselects Apple Pay by default
        let applePay = tablesQuery.cells["Apple Pay"]
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)

        // Selecting another payment method...
        let visa = tablesQuery.cells["Visa se terminant par 3220"]
        visa.tap()

        // ...and resetting the PaymentOptions VC...
        // Note that STPPaymentContext clears its cache and refetches every time it's initialized, which happens whenever CheckoutViewController is pushed on
        app.navigationBars["Checkout"].buttons["Products"].tap()
        buyNowButton.tap()
        payFromButton.tap()

        // ...should keep the 3220 card selected
        XCTAssertTrue(visa.isSelected)
        XCTAssertFalse(applePay.isSelected)

        // Reselecting Apple Pay...
        applePay.tap()

        // ...and resetting the PaymentOptions VC...
        app.navigationBars["Checkout"].buttons["Products"].tap()
        buyNowButton.tap()
        payFromButton.tap()

        // ...should keep Apple Pay selected
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)

        // Selecting another payment method...
        visa.tap()

        // ...and logging out...
        app.navigationBars["Checkout"].buttons["Products"].tap()
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tap()
        app.tables.children(matching: .cell).element(boundBy: 18).staticTexts["Log out"].tap()
        app.navigationBars["Settings"].buttons["OK"].tap()

        // ...and going back to PaymentOptionsVC...
        buyNowButton.tap()
        payFromButton.tap()

        // ..should not retain the visa default
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)
    }
}

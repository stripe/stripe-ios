//
//  BasicIntegrationUITests.swift
//  BasicIntegrationUITests
//
//  Created by David Estes on 8/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import XCTest

extension XCUIElement {
    func tapWhenHittableInTestCase(_ testCase: XCTestCase) {
        let predicate = NSPredicate(format: "hittable == true")
        testCase.expectation(for: predicate, evaluatedWith: self, handler: nil)
        testCase.waitForExpectations(timeout: 15.0, handler: nil)
        self.tap()
    }
}

class BasicIntegrationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        let stripePublishableKey = "pk_test_6Q7qTzl8OkUj5K5ArgayVsFD00Sa5AHMj3"
        let backendBaseURL = "https://stp-mobile-legacy-test-backend-17.stripedemos.com/"
        app.launchArguments.append(contentsOf: [
            "-StripePublishableKey", stripePublishableKey, "-StripeBackendBaseURL", backendBaseURL,
        ])
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func disableAddressEntry(_ app: XCUIApplication) {
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tapWhenHittableInTestCase(self)
        let noneButton = app.tables.children(matching: .cell).element(boundBy: 12).staticTexts[
            "None"]
        waitToAppear(noneButton)
        app.tables.firstMatch.swipeUp()
        noneButton.tapWhenHittableInTestCase(self)
        app.navigationBars["Settings"].buttons["Done"].tapWhenHittableInTestCase(self)
    }

    func selectItems(_ app: XCUIApplication) {
        let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier: "👠").element.tapWhenHittableInTestCase(self)
        app.collectionViews.staticTexts["👞"].tapWhenHittableInTestCase(self)
        cellsQuery.otherElements.containing(.staticText, identifier: "👗").children(matching: .other)
            .element(boundBy: 0).tapWhenHittableInTestCase(self)
    }

    func waitToAppear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }

    func testSimpleTransaction() {
        disableAddressEntry(app)
        selectItems(app)

        app.buttons["Buy Now"].tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        waitToAppear(payFromButton)
        payFromButton.tapWhenHittableInTestCase(self)
        let visa = app.tables.staticTexts["Visa ending in 4242"]
        visa.tapWhenHittableInTestCase(self)
        app.buttons["Buy"].tapWhenHittableInTestCase(self)
        let success = app.alerts["Success"].buttons["OK"]
        success.tapWhenHittableInTestCase(self)
    }

    func test3DS1() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)

        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tapWhenHittableInTestCase(self)
        let visa3063 = app.tables.staticTexts["Visa ending in 3063"]
        visa3063.tapWhenHittableInTestCase(self)

        let buyButton = app.buttons["Buy"]
        buyButton.tapWhenHittableInTestCase(self)

        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
        completeAuth.tapWhenHittableInTestCase(self)
        let successButton = app.alerts["Success"].buttons["OK"]
        successButton.tapWhenHittableInTestCase(self)
        buyButton.tapWhenHittableInTestCase(self)

        let failAuth = webViewsQuery.buttons["FAIL AUTHENTICATION"]
        failAuth.tapWhenHittableInTestCase(self)
        let errorButton = app.alerts["Error"].buttons["OK"]
        errorButton.tapWhenHittableInTestCase(self)
    }

    func test3DS2() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tapWhenHittableInTestCase(self)
        let visa = app.tables.staticTexts["Visa ending in 3220"]
        visa.tapWhenHittableInTestCase(self)
        app.buttons["Buy"].tapWhenHittableInTestCase(self)

        let elementsQuery = app.scrollViews.otherElements
        let learnMore = elementsQuery.buttons["Learn more about authentication"]
        learnMore.tapWhenHittableInTestCase(self)
        elementsQuery.buttons["Need help?"].tapWhenHittableInTestCase(self)
        app.scrollViews.otherElements.buttons["Continue"].tapWhenHittableInTestCase(self)
        let success = app.alerts["Success"].buttons["OK"]

        success.tapWhenHittableInTestCase(self)
    }

    func testPopApplePaySheet() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tapWhenHittableInTestCase(self)
        let tablesQuery = app.tables
        let applePay = tablesQuery.staticTexts["Apple Pay"]
        applePay.tapWhenHittableInTestCase(self)
        app.buttons["Buy"].tapWhenHittableInTestCase(self)
    }

    func testCCEntry() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tapWhenHittableInTestCase(self)
        let tablesQuery = app.tables
        let addButton = app.tables.staticTexts["Add New Card…"]
        addButton.tapWhenHittableInTestCase(self)

        let cardNumberField = tablesQuery.textFields["card number"]
        let cvcField = tablesQuery.textFields["CVC"]
        let zipField = tablesQuery.textFields["ZIP"]
        cardNumberField.tapWhenHittableInTestCase(self)
        cardNumberField.typeText("4000000000000069")
        let expirationDateField = tablesQuery.textFields["expiration date"]
        expirationDateField.typeText("02/28")
        cvcField.typeText("223")
        zipField.typeText("90210")

        let addcardviewcontrollernavbardonebuttonidentifierButton = app.navigationBars["Add a Card"]
            .buttons["AddCardViewControllerNavBarDoneButtonIdentifier"]
        addcardviewcontrollernavbardonebuttonidentifierButton.tapWhenHittableInTestCase(self)
        app.alerts["Your card has expired."].buttons["OK"].tapWhenHittableInTestCase(self)
        cardNumberField.tapWhenHittableInTestCase(self)
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4)
        cardNumberField.typeText(deleteString)
        cardNumberField.typeText("0341")
        addcardviewcontrollernavbardonebuttonidentifierButton.tapWhenHittableInTestCase(self)
        let buyButton = app.buttons["Buy"]
        buyButton.tapWhenHittableInTestCase(self)
        let errorButton = app.alerts["Error"].buttons["OK"]
        errorButton.tapWhenHittableInTestCase(self)
    }

    func testPaymentOptionsDefault() {
        // Note that the example backend creates a new Customer every time you start the app
        // A STPPaymentOptionsVC w/o a selected card...
        disableAddressEntry(app)
        selectItems(app)
        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tapWhenHittableInTestCase(self)

        let tablesQuery = app.tables

        // ...preselects Apple Pay by default
        let applePay = tablesQuery.cells["Apple Pay"]
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)

        // Selecting another payment method...
        let visa = tablesQuery.cells["Visa ending in 3220"]
        visa.tapWhenHittableInTestCase(self)

        // ...and resetting the PaymentOptions VC...
        // Note that STPPaymentContext clears its cache and refetches every time it's initialized, which happens whenever CheckoutViewController is pushed on
        app.navigationBars["Checkout"].buttons["Products"].tapWhenHittableInTestCase(self)
        buyNowButton.tapWhenHittableInTestCase(self)
        payFromButton.tapWhenHittableInTestCase(self)

        // ...should keep the 3220 card selected
        XCTAssertTrue(visa.isSelected)
        XCTAssertFalse(applePay.isSelected)

        // Reselecting Apple Pay...
        applePay.tapWhenHittableInTestCase(self)

        // ...and resetting the PaymentOptions VC...
        app.navigationBars["Checkout"].buttons["Products"].tapWhenHittableInTestCase(self)
        buyNowButton.tapWhenHittableInTestCase(self)
        payFromButton.tapWhenHittableInTestCase(self)

        // ...should keep Apple Pay selected
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)

        // Selecting another payment method...
        visa.tapWhenHittableInTestCase(self)

        // ...and logging out...
        app.navigationBars["Checkout"].buttons["Products"].tapWhenHittableInTestCase(self)
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tapWhenHittableInTestCase(self)
        app.tables.children(matching: .cell).element(boundBy: 18).staticTexts["Log out"].tapWhenHittableInTestCase(self)
        app.navigationBars["Settings"].buttons["Done"].tapWhenHittableInTestCase(self)

        // ...and going back to PaymentOptionsVC...
        buyNowButton.tapWhenHittableInTestCase(self)
        payFromButton.tapWhenHittableInTestCase(self)

        // ..should not retain the visa default
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)
    }
}

class FrenchAndBelizeBasicIntegrationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        let stripePublishableKey = "pk_test_6Q7qTzl8OkUj5K5ArgayVsFD00Sa5AHMj3"
        let backendBaseURL = "https://stp-mobile-legacy-test-backend-17.stripedemos.com/"
        app.launchArguments.append(contentsOf: [
            "-StripePublishableKey", stripePublishableKey, "-StripeBackendBaseURL", backendBaseURL,
            "-AppleLanguages", "(fr)", "-AppleLocale", "en_BZ",
        ])
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func disableAddressEntry(_ app: XCUIApplication) {
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tapWhenHittableInTestCase(self)
        let noneButton = app.tables.children(matching: .cell).element(boundBy: 12).staticTexts[
            "None"]
        waitToAppear(noneButton)
        app.tables.firstMatch.swipeUp()
        noneButton.tapWhenHittableInTestCase(self)
        app.navigationBars["Settings"].buttons["OK"].tapWhenHittableInTestCase(self)
    }

    func selectItems(_ app: XCUIApplication) {
        let cellsQuery = app.collectionViews.cells
        cellsQuery.otherElements.containing(.staticText, identifier: "👠").element.tapWhenHittableInTestCase(self)
        app.collectionViews.staticTexts["👞"].tapWhenHittableInTestCase(self)
        cellsQuery.otherElements.containing(.staticText, identifier: "👗").children(matching: .other)
            .element(boundBy: 0).tapWhenHittableInTestCase(self)
    }

    func waitToAppear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }

    func testSimpleTransaction() {
        disableAddressEntry(app)
        selectItems(app)

        app.buttons["Buy Now"].tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        payFromButton.tapWhenHittableInTestCase(self)
        let visa = app.tables.staticTexts["Visa se terminant par 4242"]
        visa.tapWhenHittableInTestCase(self)
        app.buttons["Buy"].tapWhenHittableInTestCase(self)
        let success = app.alerts["Success"].buttons["OK"]
        waitToAppear(success)
        success.tapWhenHittableInTestCase(self)
    }

    func test3DS1() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)

        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        waitToAppear(payFromButton)
        payFromButton.tapWhenHittableInTestCase(self)
        let visa3063 = app.tables.staticTexts["Visa se terminant par 3063"]
        waitToAppear(visa3063)
        visa3063.tapWhenHittableInTestCase(self)

        let buyButton = app.buttons["Buy"]
        buyButton.tapWhenHittableInTestCase(self)

        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
        waitToAppear(completeAuth)
        completeAuth.tapWhenHittableInTestCase(self)
        let successButton = app.alerts["Success"].buttons["OK"]
        waitToAppear(successButton)
        successButton.tapWhenHittableInTestCase(self)
        buyButton.tapWhenHittableInTestCase(self)

        let failAuth = webViewsQuery.buttons["FAIL AUTHENTICATION"]
        waitToAppear(failAuth)
        failAuth.tapWhenHittableInTestCase(self)
        let errorButton = app.alerts["Error"].buttons["OK"]
        waitToAppear(errorButton)
        errorButton.tapWhenHittableInTestCase(self)
    }

    func test3DS2() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        waitToAppear(payFromButton)
        payFromButton.tapWhenHittableInTestCase(self)
        let visa = app.tables.staticTexts["Visa se terminant par 3220"]
        waitToAppear(visa)
        visa.tapWhenHittableInTestCase(self)
        app.buttons["Buy"].tapWhenHittableInTestCase(self)

        let elementsQuery = app.scrollViews.otherElements
        let learnMore = elementsQuery.buttons["Learn more about authentication"]
        waitToAppear(learnMore)
        learnMore.tapWhenHittableInTestCase(self)
        elementsQuery.buttons["Need help?"].tapWhenHittableInTestCase(self)
        app.scrollViews.otherElements.buttons["Continue"].tapWhenHittableInTestCase(self)
        let success = app.alerts["Success"].buttons["OK"]
        waitToAppear(success)
        success.tapWhenHittableInTestCase(self)
    }

    func testPopApplePaySheet() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)

        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        waitToAppear(payFromButton)
        payFromButton.tapWhenHittableInTestCase(self)
        let tablesQuery = app.tables
        let applePay = tablesQuery.staticTexts["Apple Pay"]
        waitToAppear(applePay)
        applePay.tapWhenHittableInTestCase(self)
        app.buttons["Buy"].tapWhenHittableInTestCase(self)
    }

    func testCCEntry() {
        disableAddressEntry(app)
        selectItems(app)

        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        waitToAppear(payFromButton)
        payFromButton.tapWhenHittableInTestCase(self)

        let addButton = app.tables.staticTexts["Ajouter une nouvelle carte..."]
        waitToAppear(addButton)
        addButton.tapWhenHittableInTestCase(self)

        let tablesQuery = app.tables
        let cardNumberField = tablesQuery.textFields["numéro de carte"]
        let cvcField = tablesQuery.textFields["Code CVC"]
        cardNumberField.tapWhenHittableInTestCase(self)
        cardNumberField.typeText("4000000000000069")
        let expirationDateField = tablesQuery.textFields["date d\'expiration"]
        expirationDateField.typeText("02/28")
        cvcField.typeText("223")

        let addcardviewcontrollernavbardonebuttonidentifierButton = app.navigationBars[
            "Ajouter une carte"
        ].buttons["AddCardViewControllerNavBarDoneButtonIdentifier"]
        addcardviewcontrollernavbardonebuttonidentifierButton.tapWhenHittableInTestCase(self)
        app.alerts["Votre carte a expiré."].buttons["OK"].tapWhenHittableInTestCase(self)
        cardNumberField.tapWhenHittableInTestCase(self)
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4)
        cardNumberField.typeText(deleteString)
        cardNumberField.typeText("0341")
        addcardviewcontrollernavbardonebuttonidentifierButton.tapWhenHittableInTestCase(self)
        let buyButton = app.buttons["Buy"]
        waitToAppear(buyButton)
        buyButton.tapWhenHittableInTestCase(self)
        let errorButton = app.alerts["Error"].buttons["OK"]
        waitToAppear(errorButton)
        errorButton.tapWhenHittableInTestCase(self)
    }

    func testPaymentOptionsDefault() {
        // Note that the example backend creates a new Customer every time you start the app
        // A STPPaymentOptionsVC w/o a selected card...
        disableAddressEntry(app)
        selectItems(app)
        let buyNowButton = app.buttons["Buy Now"]
        buyNowButton.tapWhenHittableInTestCase(self)
        let payFromButton = app.buttons.matching(identifier: "Pay from").element
        waitToAppear(payFromButton)
        payFromButton.tapWhenHittableInTestCase(self)

        let tablesQuery = app.tables

        // ...preselects Apple Pay by default
        let applePay = tablesQuery.cells["Apple Pay"]
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)

        // Selecting another payment method...
        let visa = tablesQuery.cells["Visa se terminant par 3220"]
        visa.tapWhenHittableInTestCase(self)

        // ...and resetting the PaymentOptions VC...
        // Note that STPPaymentContext clears its cache and refetches every time it's initialized, which happens whenever CheckoutViewController is pushed on
        app.navigationBars["Checkout"].buttons["Products"].tapWhenHittableInTestCase(self)
        buyNowButton.tapWhenHittableInTestCase(self)
        payFromButton.tapWhenHittableInTestCase(self)

        // ...should keep the 3220 card selected
        XCTAssertTrue(visa.isSelected)
        XCTAssertFalse(applePay.isSelected)

        // Reselecting Apple Pay...
        applePay.tapWhenHittableInTestCase(self)

        // ...and resetting the PaymentOptions VC...
        app.navigationBars["Checkout"].buttons["Products"].tapWhenHittableInTestCase(self)
        buyNowButton.tapWhenHittableInTestCase(self)
        payFromButton.tapWhenHittableInTestCase(self)

        // ...should keep Apple Pay selected
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)

        // Selecting another payment method...
        visa.tapWhenHittableInTestCase(self)

        // ...and logging out...
        app.navigationBars["Checkout"].buttons["Products"].tapWhenHittableInTestCase(self)
        app.navigationBars["Emoji Apparel"].buttons["Settings"].tapWhenHittableInTestCase(self)
        app.tables.children(matching: .cell).element(boundBy: 18).staticTexts["Log out"].tapWhenHittableInTestCase(self)
        app.navigationBars["Settings"].buttons["OK"].tapWhenHittableInTestCase(self)

        // ...and going back to PaymentOptionsVC...
        buyNowButton.tapWhenHittableInTestCase(self)
        payFromButton.tapWhenHittableInTestCase(self)

        // ..should not retain the visa default
        waitToAppear(applePay)
        XCTAssertTrue(applePay.isSelected)
        XCTAssertFalse(visa.isSelected)
    }
}

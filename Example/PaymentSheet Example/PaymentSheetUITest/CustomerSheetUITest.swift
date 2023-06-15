//
//  CustomerSheetUITest.swift
//  PaymentSheetUITest
//

import Foundation
import XCTest

class CustomerSheetUITest: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    func testCustomerSheetStandard_applePayOff_addCard() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()
        let paymentMethodButton = app.staticTexts["Success: ••••4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testCustomerSheetStandard_applePayOn_addCard() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()
        let paymentMethodButton = app.staticTexts["Success: ••••4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testCustomerSheetStandard_applePayOn_selectApplePay() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.collectionViews.staticTexts["Apple Pay"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: Apple Pay"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testAddTwoPaymentMethods_RemoveTwoPaymentMethods() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None")
        presentCSAndAddCardFrom(buttonLabel: "••••4242")

        let selectButton = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        removeFirstPaymentMethodInList()
        removeFirstPaymentMethodInList()

        let doneButton = app.staticTexts["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 60.0))
        doneButton.tap()

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method unset", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))

    }

    func presentCSAndAddCardFrom(buttonLabel: String) {
        let selectButton = app.staticTexts[buttonLabel]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()
        dismissAlertView(alertBody: "Success: ••••4242", alertTitle: "Complete", buttonToTap: "OK")
    }

    func removeFirstPaymentMethodInList() {
        let removeButton1 = app.buttons["Remove"].firstMatch
        removeButton1.tap()
        dismissAlertView(alertBody: "Remove Visa ending in 4242", alertTitle: "Remove Card", buttonToTap: "Remove")
    }

    func dismissAlertView(alertBody: String, alertTitle: String, buttonToTap: String) {
        let alertText = app.staticTexts[alertBody]
        XCTAssertTrue(alertText.waitForExistence(timeout: 60.0))

        let alert = app.alerts[alertTitle]
        alert.buttons[buttonToTap].tap()
    }
}

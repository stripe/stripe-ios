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

    func testPaymentSheetStandard_applePayOff_addCard() throws {
        app.staticTexts["CustomerSheet (test playground)"].tap()
        let loadButton = app.staticTexts["Load Ephemeral Key"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 60.0))
        app.segmentedControls["apple_pay_selector"].buttons["off"].tap()
        loadButton.tap()

        let selectButton = app.staticTexts["Select"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Save"].tap()
        let paymentMethodButton = app.staticTexts["Success: ••••4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testPaymentSheetStandard_applePayOn_addCard() throws {
        app.staticTexts["CustomerSheet (test playground)"].tap()
        let loadButton = app.staticTexts["Load Ephemeral Key"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 60.0))
        app.segmentedControls["apple_pay_selector"].buttons["on"].tap()
        loadButton.tap()

        let selectButton = app.staticTexts["Select"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: false)
        app.buttons["Save"].tap()
        let paymentMethodButton = app.staticTexts["Success: ••••4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testPaymentSheetStandard_applePayOn_selectApplePay() throws {
        app.staticTexts["CustomerSheet (test playground)"].tap()
        let loadButton = app.staticTexts["Load Ephemeral Key"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 60.0))
        app.segmentedControls["apple_pay_selector"].buttons["on"].tap()
        loadButton.tap()

        let selectButton = app.staticTexts["Select"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.collectionViews.staticTexts["Apple Pay"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: Apple Pay"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }
}

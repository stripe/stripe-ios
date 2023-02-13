//
//  PaymentSheetBillingCollectionUITests.swift
//  PaymentSheetUITest
//
//  Created by Eduardo Urias on 2/23/23.
//

import XCTest

final class PaymentSheetBillingCollectionUITests: XCTestCase {
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

    func testCard_AutomaticFields_NoDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "guestmode",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "link": "off",
                "attach_defaults": "off",
                "collect_name": "auto",
                "collect_email": "auto",
                "collect_phone": "auto",
                "collect_address": "auto",
            ]
        )
        app.buttons["Checkout (Complete)"].tap()

        guard let card = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "card") else {
            XCTFail()
            return
        }
        card.tap()
        try! fillCardData(app)

        // Complete payment
        app.buttons["Pay $50.99"].tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }

    func testCard_AllFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "guestmode",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "link": "off",
                "default_billing_address": "on",
                "attach_defaults": "on",
                "collect_name": "always",
                "collect_email": "always",
                "collect_phone": "always",
                "collect_address": "full",
            ]
        )
        app.buttons["Checkout (Complete)"].tap()

        guard let card = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "card") else {
            XCTFail()
            return
        }
        card.tap()

        XCTAssertTrue(app.staticTexts["Card information"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertEqual(app.textFields["Email"].value as? String, "foo@bar.com")
        XCTAssertEqual(app.textFields["Phone"].value as? String, "(310) 555-1234")
        XCTAssertEqual(app.textFields["Name on card"].value as? String, "Jane Doe")
        XCTAssertTrue(app.staticTexts["Billing address"].exists)
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["Address line 1"].value as? String, "510 Townsend St.")
        XCTAssertEqual(app.textFields["Address line 2"].value as? String, "")
        XCTAssertEqual(app.textFields["City"].value as? String, "San Francisco")
        XCTAssertEqual(app.textFields["State"].value as? String, "California")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].tap() // Dismiss keyboard.

        // Complete payment
        app.buttons["Pay $50.99"].tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }

    func testCard_OnlyCardInfo_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "guestmode",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "link": "off",
                "default_billing_address": "on",
                "attach_defaults": "on",
                "collect_name": "never",
                "collect_email": "never",
                "collect_phone": "never",
                "collect_address": "never",
            ]
        )
        app.buttons["Checkout (Complete)"].tap()

        guard let card = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "card") else {
            XCTFail()
            return
        }
        card.tap()

        XCTAssertTrue(app.staticTexts["Card information"].waitForExistence(timeout: 10.0))
        XCTAssertFalse(app.staticTexts["Contact information"].exists)
        XCTAssertFalse(app.textFields["Email"].exists)
        XCTAssertFalse(app.textFields["Phone"].exists)
        XCTAssertFalse(app.textFields["Name on card"].exists)
        XCTAssertFalse(app.staticTexts["Billing address"].exists)
        XCTAssertFalse(app.staticTexts["Country or region"].exists)
        XCTAssertFalse(app.staticTexts["Address line 1"].exists)
        XCTAssertFalse(app.staticTexts["Address line 2"].exists)
        XCTAssertFalse(app.staticTexts["City"].exists)
        XCTAssertFalse(app.staticTexts["State"].exists)
        XCTAssertFalse(app.staticTexts["ZIP"].exists)

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].tap() // Dismiss keyboard.

        // Complete payment
        app.buttons["Pay $50.99"].tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }
}

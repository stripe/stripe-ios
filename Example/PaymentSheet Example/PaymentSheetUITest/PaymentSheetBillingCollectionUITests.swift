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

    func testUSBankAccount_AutomaticFields_NoDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "allows_delayed_pms": "true",
                "link": "off",
                "attach_defaults": "off",
                "collect_name": "auto",
                "collect_email": "auto",
                "collect_phone": "auto",
                "collect_address": "auto",
            ]
        )
        app.buttons["Checkout (Complete)"].tap()

        guard let cell = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account")
        else {
            XCTFail()
            return
        }
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)

        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.textFields["Full name"].exists)
        XCTAssertFalse(app.textFields["Phone"].exists)
        XCTAssertFalse(app.staticTexts["Billing address"].exists)
        XCTAssertFalse(app.staticTexts["Country or region"].exists)
        XCTAssertFalse(app.staticTexts["Address line 1"].exists)
        XCTAssertFalse(app.staticTexts["Address line 2"].exists)
        XCTAssertFalse(app.staticTexts["City"].exists)
        XCTAssertFalse(app.staticTexts["State"].exists)
        XCTAssertFalse(app.staticTexts["ZIP"].exists)

        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = app.textFields["Email"]
        email.tap()
        email.typeText("test@example.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 5))

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testUSBankAccount_AutomaticFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "allows_delayed_pms": "true",
                "link": "off",
                "default_billing_address": "on",
                "attach_defaults": "on",
                "collect_name": "auto",
                "collect_email": "auto",
                "collect_phone": "auto",
                "collect_address": "auto",
            ]
        )
        app.buttons["Checkout (Complete)"].tap()

        guard let cell = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account")
        else {
            XCTFail()
            return
        }
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)

        XCTAssertEqual(app.textFields["Email"].value as? String, "foo@bar.com")
        XCTAssertEqual(app.textFields["Full name"].value as? String, "Jane Doe")

        XCTAssertFalse(app.textFields["Phone"].exists)
        XCTAssertFalse(app.staticTexts["Billing address"].exists)
        XCTAssertFalse(app.staticTexts["Country or region"].exists)
        XCTAssertFalse(app.staticTexts["Address line 1"].exists)
        XCTAssertFalse(app.staticTexts["Address line 2"].exists)
        XCTAssertFalse(app.staticTexts["City"].exists)
        XCTAssertFalse(app.staticTexts["State"].exists)
        XCTAssertFalse(app.staticTexts["ZIP"].exists)

        continueButton.tap()

        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 5))

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testUSBankAccount_AllFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "allows_delayed_pms": "true",
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

        guard let cell = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account")
        else {
            XCTFail()
            return
        }
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)

        XCTAssertEqual(app.textFields["Email"].value as? String, "foo@bar.com")
        XCTAssertEqual(app.textFields["Full name"].value as? String, "Jane Doe")
        XCTAssertEqual(app.textFields["Phone"].value as? String, "(310) 555-1234")
        XCTAssertTrue(app.staticTexts["Billing address"].exists)
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["Address line 1"].value as? String, "510 Townsend St.")
        XCTAssertEqual(app.textFields["Address line 2"].value as? String, "")
        XCTAssertEqual(app.textFields["City"].value as? String, "San Francisco")
        XCTAssertEqual(app.textFields["State"].value as? String, "California")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")

        continueButton.tap()

        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 5))

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testUSBankAccount_NoFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "automatic_payment_methods": "off",
                "allows_delayed_pms": "true",
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

        guard let cell = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account")
        else {
            XCTFail()
            return
        }
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)

        XCTAssertFalse(app.textFields["Email"].exists)
        XCTAssertFalse(app.textFields["Full name"].exists)
        XCTAssertFalse(app.textFields["Phone"].exists)
        XCTAssertFalse(app.staticTexts["Billing address"].exists)
        XCTAssertFalse(app.staticTexts["Country or region"].exists)
        XCTAssertFalse(app.staticTexts["Address line 1"].exists)
        XCTAssertFalse(app.staticTexts["Address line 2"].exists)
        XCTAssertFalse(app.staticTexts["City"].exists)
        XCTAssertFalse(app.staticTexts["State"].exists)
        XCTAssertFalse(app.staticTexts["ZIP"].exists)

        continueButton.tap()

        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 5))

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testUPI_AutomaticFields() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "merchant_country_code": "IN",
                "currency": "INR",
                "default_billing_address": "off",
                "attach_defaults": "off",
                "collect_name": "auto",
                "collect_email": "auto",
                "collect_phone": "auto",
                "collect_address": "auto",
            ]
        )

        app.buttons["Checkout (Complete)"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(app.textFields["Email"].exists)
        XCTAssertFalse(app.textFields["Full name"].exists)
        XCTAssertFalse(app.textFields["Phone"].exists)
        XCTAssertFalse(app.staticTexts["Billing address"].exists)
        XCTAssertFalse(app.staticTexts["Country or region"].exists)
        XCTAssertFalse(app.textFields["Address line 1"].exists)
        XCTAssertFalse(app.textFields["Address line 2"].exists)
        XCTAssertFalse(app.textFields["City"].exists)
        XCTAssertFalse(app.textFields["State"].exists)
        XCTAssertFalse(app.textFields["ZIP"].exists)

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }

    func testUPI_AllFields_NoDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "merchant_country_code": "IN",
                "currency": "INR",
                "default_billing_address": "off",
                "attach_defaults": "off",
                "collect_name": "always",
                "collect_email": "always",
                "collect_phone": "always",
                "collect_address": "full",
            ]
        )

        app.buttons["Checkout (Complete)"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.textFields["Full name"].exists)
        XCTAssertTrue(app.textFields["Phone"].exists)
        XCTAssertTrue(app.staticTexts["Billing address"].exists)
        XCTAssertTrue(app.textFields["Country or region"].exists)
        XCTAssertTrue(app.textFields["Address line 1"].exists)
        XCTAssertTrue(app.textFields["Address line 2"].exists)
        XCTAssertTrue(app.textFields["City"].exists)
        XCTAssertTrue(app.textFields["State"].exists)
        XCTAssertTrue(app.textFields["ZIP"].exists)

        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("Jane Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = app.textFields["Email"]
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        let phone = app.textFields["Phone"]
        phone.tap()
        phone.typeText("3105551234")
        phone.typeText(XCUIKeyboardKey.return.rawValue)

        let line1 = app.textFields["Address line 1"]
        line1.tap()
        line1.typeText("510 Townsend St.")
        line1.typeText(XCUIKeyboardKey.return.rawValue)

        let city = app.textFields["City"]
        city.tap()
        city.typeText("San Francisco")
        city.typeText(XCUIKeyboardKey.return.rawValue)

        app.textFields["State"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")

        let zip = app.textFields["ZIP"]
        zip.tap()
        zip.typeText("94102")
        zip.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }

    func testUPI_AllFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "merchant_country_code": "IN",
                "currency": "INR",
                "default_billing_address": "on",
                "attach_defaults": "on",
                "collect_name": "always",
                "collect_email": "always",
                "collect_phone": "always",
                "collect_address": "full",
            ]
        )

        app.buttons["Checkout (Complete)"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertEqual(app.textFields["Email"].value as? String, "foo@bar.com")
        XCTAssertEqual(app.textFields["Full name"].value as? String, "Jane Doe")
        XCTAssertEqual(app.textFields["Phone"].value as? String, "(310) 555-1234")
        XCTAssertTrue(app.staticTexts["Billing address"].exists)
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["Address line 1"].value as? String, "510 Townsend St.")
        XCTAssertEqual(app.textFields["Address line 2"].value as? String, "")
        XCTAssertEqual(app.textFields["City"].value as? String, "San Francisco")
        XCTAssertEqual(app.textFields["State"].value as? String, "California")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }

    func testUPI_SomeFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "new",
                "merchant_country_code": "IN",
                "currency": "INR",
                "default_billing_address": "on",
                "attach_defaults": "on",
                "collect_name": "always",
                "collect_email": "always",
                "collect_phone": "never",
                "collect_address": "never",
            ]
        )

        app.buttons["Checkout (Complete)"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertEqual(app.textFields["Email"].value as? String, "foo@bar.com")
        XCTAssertEqual(app.textFields["Full name"].value as? String, "Jane Doe")
        XCTAssertFalse(app.textFields["Phone"].exists)
        XCTAssertFalse(app.staticTexts["Billing address"].exists)
        XCTAssertFalse(app.staticTexts["Country or region"].exists)
        XCTAssertFalse(app.textFields["Address line 1"].exists)
        XCTAssertFalse(app.textFields["Address line 2"].exists)
        XCTAssertFalse(app.textFields["City"].exists)
        XCTAssertFalse(app.textFields["State"].exists)
        XCTAssertFalse(app.textFields["ZIP"].exists)

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
    }

}

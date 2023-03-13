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

    private var cardInfoField: XCUIElement { app.staticTexts["Card information"] }
    private var contactInfoField: XCUIElement { app.staticTexts["Contact information"] }
    private var fullNameField: XCUIElement { app.textFields["Full name"] }
    private var nameOnCardField: XCUIElement { app.textFields["Name on card"] }
    private var emailField: XCUIElement { app.textFields["Email"] }
    private var phoneField: XCUIElement { app.textFields["Phone"] }
    private var billingAddressField: XCUIElement { app.staticTexts["Billing address"] }
    private var countryField: XCUIElement { app.textFields["Country or region"] }
    private var line1Field: XCUIElement { app.textFields["Address line 1"] }
    private var line2Field: XCUIElement { app.textFields["Address line 2"] }
    private var cityField: XCUIElement { app.textFields["City"] }
    private var stateField: XCUIElement { app.textFields["State"] }
    private var zipField: XCUIElement { app.textFields["ZIP"] }
    private var checkoutButton: XCUIElement { app.buttons["Checkout (Complete)"] }
    private var payButton: XCUIElement { app.buttons["Pay $50.99"] }
    private var successText: XCUIElement { app.alerts.staticTexts["Success!"] }
    private var okButton: XCUIElement { app.alerts.scrollViews.otherElements.buttons["OK"] }

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
        checkoutButton.tap()

        let card = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "card"))
        card.tap()
        try! fillCardData(app)

        // Complete payment
        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
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
        checkoutButton.tap()

        let card = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "card"))
        card.tap()

        XCTAssertTrue(cardInfoField.waitForExistence(timeout: 10.0))
        XCTAssertTrue(contactInfoField.exists)
        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(phoneField.value as? String, "(310) 555-1234")
        XCTAssertEqual(nameOnCardField.value as? String, "Jane Doe")
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(line2Field.value as? String, "")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(zipField.value as? String, "94102")

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].tap() // Dismiss keyboard.

        // Complete payment
        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
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
        checkoutButton.tap()

        let card = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "card"))
        card.tap()

        XCTAssertTrue(cardInfoField.waitForExistence(timeout: 10.0))
        XCTAssertFalse(app.staticTexts["Contact information"].exists)
        XCTAssertFalse(emailField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(nameOnCardField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].tap() // Dismiss keyboard.

        // Complete payment
        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account"))
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)

        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        let name = fullNameField
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = emailField
        email.tap()
        email.typeText("test@example.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        let payButton = payButton
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account"))
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)

        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(fullNameField.value as? String, "Jane Doe")

        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        continueButton.tap()

        let payButton = payButton
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account"))
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)

        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(fullNameField.value as? String, "Jane Doe")
        XCTAssertEqual(phoneField.value as? String, "(310) 555-1234")
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(line2Field.value as? String, "")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(zipField.value as? String, "94102")

        continueButton.tap()

        let payButton = payButton
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account"))
        cell.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)

        XCTAssertFalse(emailField.exists)
        XCTAssertFalse(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        continueButton.tap()

        let payButton = payButton
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

        checkoutButton.tap()

        let payButton = app.buttons["Pay ₹50.99"]
        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI"))
        cell.tap()

        XCTAssertFalse(emailField.exists)
        XCTAssertFalse(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
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

        checkoutButton.tap()

        let payButton = app.buttons["Pay ₹50.99"]
        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI"))
        cell.tap()

        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(fullNameField.exists)
        XCTAssertTrue(phoneField.exists)
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertTrue(countryField.exists)
        XCTAssertTrue(line1Field.exists)
        XCTAssertTrue(line2Field.exists)
        XCTAssertTrue(cityField.exists)
        XCTAssertTrue(stateField.exists)
        XCTAssertTrue(zipField.exists)

        let name = fullNameField
        name.tap()
        name.typeText("Jane Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = emailField
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        let phone = phoneField
        phone.tap()
        phone.typeText("3105551234")
        phone.typeText(XCUIKeyboardKey.return.rawValue)

        let line1 = line1Field
        line1.tap()
        line1.typeText("510 Townsend St.")
        line1.typeText(XCUIKeyboardKey.return.rawValue)

        let city = cityField
        city.tap()
        city.typeText("San Francisco")
        city.typeText(XCUIKeyboardKey.return.rawValue)

        stateField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")

        let zip = zipField
        zip.tap()
        zip.typeText("94102")
        zip.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
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

        checkoutButton.tap()

        let payButton = app.buttons["Pay ₹50.99"]
        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI"))
        cell.tap()

        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(fullNameField.value as? String, "Jane Doe")
        XCTAssertEqual(phoneField.value as? String, "(310) 555-1234")
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(line2Field.value as? String, "")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(zipField.value as? String, "94102")

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
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

        checkoutButton.tap()

        let payButton = app.buttons["Pay ₹50.99"]
        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI"))
        cell.tap()

        XCTAssertTrue(app.staticTexts["Contact information"].exists)
        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(fullNameField.value as? String, "Jane Doe")
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
    }

    func testLpm_Afterpay_AutomaticFields_WithDefaultAddress() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "guestmode",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "shipping": "on w/ defaults",
                "automatic_payment_methods": "off",
                "link": "off",
                "attach_defaults": "off",
                "collect_name": "auto",
                "collect_email": "auto",
                "collect_phone": "auto",
                "collect_address": "auto",
            ]
        )

        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The defaults should be loaded, just need to save them.
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(
            collectionView: app.collectionViews.firstMatch,
            toFindCellWithId: "afterpay_clearpay")
        )
        cell.tap()

        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(line2Field.value as? String, "")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(zipField.value as? String, "94102")

        let name = fullNameField
        name.tap()
        name.typeText("Jane Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = emailField
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        // Complete payment
        payButton.tap()
        let authorizeButton = app.links["AUTHORIZE TEST PAYMENT"]
        authorizeButton.waitForExistenceAndTap(timeout: 10.0)
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
    }

    func testLpm_Afterpay_AllFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "guestmode",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "shipping": "on w/ defaults",
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

        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The defaults should be loaded, just need to save them.
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(
            collectionView: app.collectionViews.firstMatch,
            toFindCellWithId: "afterpay_clearpay")
        )
        cell.tap()

        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(phoneField.value as? String, "(310) 555-1234")
        XCTAssertEqual(fullNameField.value as? String, "Jane Doe")
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(line2Field.value as? String, "")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(zipField.value as? String, "94102")

        // Complete payment
        payButton.tap()
        let authorizeButton = app.links["AUTHORIZE TEST PAYMENT"]
        authorizeButton.waitForExistenceAndTap(timeout: 10.0)
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
    }

    func testLpm_Afterpay_MinimalFields_WithDefaults() throws {
        loadPlayground(
            app,
            settings: [
                "customer_mode": "guestmode",
                "currency": "USD",
                "merchant_country_code": "US",
                "apple_pay": "off",
                "shipping": "on w/ defaults",
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

        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The defaults should be loaded, just need to save them.
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(
            collectionView: app.collectionViews.firstMatch,
            toFindCellWithId: "afterpay_clearpay")
        )
        cell.tap()

        XCTAssertFalse(emailField.exists)
        XCTAssertFalse(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        // Complete payment
        payButton.tap()
        let authorizeButton = app.links["AUTHORIZE TEST PAYMENT"]
        authorizeButton.waitForExistenceAndTap(timeout: 10.0)
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        okButton.tap()
    }

    func testLpm_Klarna_AutomaticFields() throws {
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "klarna"))
        cell.tap()

        XCTAssertTrue(emailField.exists)
        XCTAssertFalse(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertFalse(app.textFields["Country"].exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        let email = emailField
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        // Just check the button is enabled, confirming a payment with Klarna is flaky.
        XCTAssertTrue(payButton.isEnabled)
    }

    func testLpm_Klarna_AllFields_WithDefaults() throws {
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "klarna"))
        cell.tap()

        XCTAssertEqual(emailField.value as? String, "foo@bar.com")
        XCTAssertEqual(phoneField.value as? String, "(310) 555-1234")
        XCTAssertEqual(fullNameField.value as? String, "Jane Doe")
        XCTAssertTrue(billingAddressField.exists)
        XCTAssertEqual(countryField.value as? String, "United States")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(line2Field.value as? String, "")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(zipField.value as? String, "94102")

        // Just check the button is enabled, confirming a payment with Klarna is flaky.
        XCTAssertTrue(payButton.isEnabled)
    }

    func testLpm_Klarna_MinimalFields_WithDefaults() throws {
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
        checkoutButton.tap()

        let cell = try XCTUnwrap(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "klarna"))
        cell.tap()

        XCTAssertFalse(emailField.exists)
        XCTAssertFalse(fullNameField.exists)
        XCTAssertFalse(phoneField.exists)
        XCTAssertFalse(billingAddressField.exists)
        XCTAssertTrue(countryField.exists)
        XCTAssertFalse(line1Field.exists)
        XCTAssertFalse(line2Field.exists)
        XCTAssertFalse(cityField.exists)
        XCTAssertFalse(stateField.exists)
        XCTAssertFalse(zipField.exists)

        // Just check the button is enabled, confirming a payment with Klarna is flaky.
        XCTAssertTrue(payButton.isEnabled)
    }
}

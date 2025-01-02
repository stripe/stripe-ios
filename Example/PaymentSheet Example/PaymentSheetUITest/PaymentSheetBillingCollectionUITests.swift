//
//  PaymentSheetBillingCollectionUITests.swift
//  PaymentSheetUITest
//
//  Created by Eduardo Urias on 2/23/23.
//

import XCTest

class PaymentSheetBillingCollectionUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
    }

    var cardInfoField: XCUIElement { app.staticTexts["Card information"] }
    var contactInfoField: XCUIElement { app.staticTexts["Contact information"] }
    var fullNameField: XCUIElement { app.textFields["Full name"] }
    var nameOnCardField: XCUIElement { app.textFields["Name on card"] }
    var emailField: XCUIElement { app.textFields["Email"] }
    var phoneField: XCUIElement { app.textFields["Phone number"] }
    var billingAddressField: XCUIElement { app.staticTexts["Billing address"] }
    var countryField: XCUIElement { app.textFields["Country or region"] }
    var line1Field: XCUIElement { app.textFields["Address line 1"] }
    var line2Field: XCUIElement { app.textFields["Address line 2"] }
    var cityField: XCUIElement { app.textFields["City"] }
    var stateField: XCUIElement { app.textFields["State"] }
    var zipField: XCUIElement { app.textFields["ZIP"] }
    var checkoutButton: XCUIElement { app.buttons["Present PaymentSheet"] }
    var payButton: XCUIElement { app.buttons["Pay $50.99"] }
    var successText: XCUIElement { app.staticTexts["Success!"] }

    // FlowController specific buttons
    var paymentMethodSelectorNoneButton: XCUIElement { app.buttons["None"] }
    var confirmButton: XCUIElement { app.buttons["Confirm"] }
    var continueButton: XCUIElement { app.buttons["Continue"] }

}

class PaymentSheetBillingCollectionUICardTests: PaymentSheetBillingCollectionUITestCase {
    func testCard_AllFields_flowController_WithDefaults() throws {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.uiStyle = .flowController
        settings.currency = .usd
        settings.merchantCountryCode = .US
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.defaultBillingAddress = .on
        settings.attachDefaults = .on
        settings.collectName = .always
        settings.collectEmail = .always
        settings.collectPhone = .always
        settings.collectAddress = .full
        loadPlayground(
            app,
            settings
        )
        paymentMethodSelectorNoneButton.tap()

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

        // Dismiss FlowController payment method selector
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["card"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["Jane Doe"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["foo@bar.com"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["+1 (310) 555-1234"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["510 Townsend St."].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["San Francisco"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["CA"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["94102"].waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["US"].waitForExistence(timeout: 10.0))

        confirmButton.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
}

class PaymentSheetBillingCollectionLPMUITests: PaymentSheetBillingCollectionUITestCase {
    func testLpm_Afterpay_AutomaticFields_WithDefaultAddress() throws {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.applePayEnabled = .off
        settings.shippingInfo = .onWithDefaults
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.attachDefaults = .off
        settings.collectName = .automatic
        settings.collectEmail = .automatic
        settings.collectPhone = .automatic
        settings.collectAddress = .automatic
        loadPlayground(
            app,
            settings
        )

        let shippingButton = app.buttons["Address"]
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
        let authorizeButton = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        authorizeButton.waitForExistenceAndTap(timeout: 10.0)
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testLpm_Afterpay_AllFields_WithDefaults() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.currency = .usd
        settings.merchantCountryCode = .US
        settings.applePayEnabled = .off
        settings.shippingInfo = .onWithDefaults
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.defaultBillingAddress =  .on
        settings.attachDefaults =  .on
        settings.collectName = .always
        settings.collectEmail = .always
        settings.collectPhone = .always
        settings.collectAddress = .full
        loadPlayground(
            app,
            settings
        )

        let shippingButton = app.buttons["Address"]
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
        let authorizeButton = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        authorizeButton.waitForExistenceAndTap(timeout: 10.0)
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testLpm_Afterpay_MinimalFields_WithDefaults() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.currency = .usd
        settings.merchantCountryCode = .US
        settings.applePayEnabled = .off
        settings.shippingInfo = .onWithDefaults
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.defaultBillingAddress =  .on
        settings.attachDefaults =  .on
        settings.collectName = .never
        settings.collectEmail = .never
        settings.collectPhone = .never
        settings.collectAddress = .never
        loadPlayground(
            app,
            settings
        )

        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The defaults should be loaded, just need to save them.
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        checkoutButton.tap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

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
        let authorizeButton = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        authorizeButton.waitForExistenceAndTap(timeout: 10.0)
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
}

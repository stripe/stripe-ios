//
//  PaymentSheetBillingCollectionLPMUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

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
        XCTAssertFalse(billingAddressField.exists)

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
        settings.linkEnabledMode = .native
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

        app.buttons["LinkVerificationCloseButton"].waitForExistenceAndTap()

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
        settings.linkEnabledMode = .native
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
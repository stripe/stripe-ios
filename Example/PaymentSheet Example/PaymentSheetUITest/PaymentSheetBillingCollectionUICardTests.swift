//
//  PaymentSheetBillingCollectionUICardTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

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
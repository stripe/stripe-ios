//
//  PaymentSheetCardBrandFilteringUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//

import XCTest

class PaymentSheetCardBrandFilteringUITests: PaymentSheetUITestCase {
    func testPaymentSheet_disallowedBrands() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.cardBrandAcceptance = .blockAmEx
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("3712")

        // Text should show that we cannot process American Express
        XCTAssertTrue(app.staticTexts["American Express is not accepted"].waitForExistence(timeout: 5.0))

        numberField.clearText()

        // Try and pay with a Visa
        try fillCardData(app)

        app.buttons["Pay $50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testPaymentSheet_allowedBrands() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.cardBrandAcceptance = .allowVisa
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("3712")

        // Text should show that we cannot process American Express
        XCTAssertTrue(app.staticTexts["American Express is not accepted"].waitForExistence(timeout: 5.0))

        numberField.clearText()

        // Try and pay with a Visa
        try fillCardData(app)

        app.buttons["Pay $50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
}

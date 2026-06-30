//
//  CheckoutSessionUITests.swift
//  PaymentSheet Example
//

import XCTest

class CheckoutSessionUITests: PaymentSheetUITestCase {

    // MARK: - Embedded Payment Element

    func testCheckoutSession_Embedded_Card() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .embedded
        settings.integrationType = .checkoutSession
        settings.mode = .payment
        settings.formSheetAction = .continue
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)
        app.buttons["Continue"].tap()
        // After dismissing the form, tap the confirm button
        app.buttons["Checkout"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    // MARK: - FlowController

    func testCheckoutSession_FlowController_Card() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.integrationType = .checkoutSession
        settings.mode = .payment
        loadPlayground(app, settings)

        // Open payment options
        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app)
        app.buttons["Continue"].tap()

        // Confirm
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }
}

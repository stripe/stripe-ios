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
        settings.linkDisplay = .never
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)
        app.buttons["Continue"].tap()
        // After dismissing the form, scroll down and tap the confirm button
        app.buttons["Checkout"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    // MARK: - FlowController

    func testCheckoutSession_FlowController_Card() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.integrationType = .checkoutSession
        settings.mode = .payment
        settings.linkDisplay = .never
        loadPlayground(app, settings)

        // Open payment options
        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app)

        let continueButton = app.buttons["Continue"]
        continueButton.tap()

        // Wait for sheet dismissal. The merchant Confirm button exists behind the sheet,
        // but should not be hittable until billing sync and the session reload complete.
        let confirmButton = app.buttons["Confirm"]
        confirmButton.forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }
}

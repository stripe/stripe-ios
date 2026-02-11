//
//  PaymentSheetCVCRecollectionUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

class PaymentSheetCVCRecollectionUITests: PaymentSheetUITestCase {
    func testCVCRecollectionFlowController_deferredCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]

        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app)

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Confirm"].waitForExistenceAndTap()
        // CVC field should already be selected
        app.typeText("123")

        let confirmButtons: XCUIElementQuery = app.buttons.matching(identifier: "Confirm")
        for index in 0..<confirmButtons.count {
            if confirmButtons.element(boundBy: index).isHittable {
                confirmButtons.element(boundBy: index).tap()
            }
        }
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCVCRecollectionComplete_deferredCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app)

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Pay $50.99"].waitForExistenceAndTap(timeout: 5.0)

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let cvcField = app.textFields["CVC"]
        cvcField.forceTapWhenHittableInTestCase(self)
        app.typeText("123")
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCVCRecollectionFlowController_intentFirstCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.integrationType = .normal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]

        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app)

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Confirm"].waitForExistenceAndTap()
        // CVC field should already be selected
        app.typeText("123")

        let confirmButtons: XCUIElementQuery = app.buttons.matching(identifier: "Confirm")
        for index in 0..<confirmButtons.count {
            if confirmButtons.element(boundBy: index).isHittable {
                confirmButtons.element(boundBy: index).tap()
            }
        }
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    func testCVCRecollectionComplete_intentFirstCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .paymentSheet
        settings.integrationType = .normal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app)

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        let payButton = app.buttons["Pay $50.99"]
        XCTAssert(payButton.isEnabled)
        payButton.tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let cvcField = app.textFields["CVC"]
        cvcField.forceTapWhenHittableInTestCase(self)
        app.typeText("123")
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    func testLinkOnlyFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        // Use the GB merchant to use web-based Link
        settings.merchantCountryCode = .GB
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.linkPassthroughMode = .pm

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["pay_with_link_button"].waitForExistenceAndTap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        // Cancel the Link sign in system dialog
        // Note: `addUIInterruptionMonitor` is flakey so we do this hack instead
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Cancel"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Payment canceled."].waitForExistence(timeout: 5))
        // Re-tapping the payment method button should present the main screen again
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Card information"].waitForExistence(timeout: 5))
    }

    /* Disable Link test
     func testDeferredIntentLinkSignIn_SeverSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try loginAndPay()
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkSignIn_ServerSideConfirmation_LostCardDecline() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistence(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let declineText = app.staticTexts["Your card was declined."]
     XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkFlowControllerFlow_SeverSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     let paymentMethodButton = app.buttons["Select Payment Method"]
     XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"]
     XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].tap()
     
     try loginAndPay()
     }
     */
}
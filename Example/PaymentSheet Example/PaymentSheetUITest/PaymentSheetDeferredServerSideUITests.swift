//
//  PaymentSheetDeferredServerSideUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

class PaymentSheetDeferredServerSideUITests: PaymentSheetUITestCase {
    // MARK: Deferred tests (server-side)

    func testDeferredPaymentIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_ServerSideConfirmation_Multiprocessor() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_SeverSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].tap()

        let declineText = app.staticTexts["Your card was declined."]
        XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        settings.mode = .setup
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation_ManualConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mc
        settings.confirmationMode = .paymentMethod
        settings.uiStyle = .flowController
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        settings.mode = .setup
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    /* Disable link test
     func testDeferferedIntentLinkSignup_ServerSideConfirmation() throws {
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
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     XCTAssertTrue(modal.waitForExistence(timeout: 10))
     
     let emailField = modal.textFields["Email"]
     XCTAssertTrue(emailField.waitForExistence(timeout: 10))
     emailField.tap()
     emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
     
     let phoneField = modal.textFields["Phone"]
     XCTAssert(phoneField.waitForExistence(timeout: 10))
     phoneField.tap()
     phoneField.typeText("3105551234")
     
     // The name field is only required for non-US countries. Only fill it out if it exists.
     let nameField = modal.textFields["Name"]
     if nameField.exists {
     nameField.tap()
     nameField.typeText("Jane Done")
     }
     
     modal.buttons["Join Link"].tap()
     
     // Because we are presenting view controllers with `modalPresentationStyle = .overFullScreen`,
     // there are currently 2 card forms on screen. Specifying a container helps the `fillCardData()`
     // method operate on the correct card form.
     try fillCardData(app, container: modal)
     
     // Pay!
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let successText = app.staticTexts["Success!"]
     XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation_ManualConfirmation() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mc
        settings.confirmationMode = .paymentMethod
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation_Multiprocessor() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ConfirmationToken_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.confirmationMode = .confirmationToken
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ConfirmationToken_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.integrationType = .deferred_ssc
        settings.confirmationMode = .confirmationToken
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testCheckoutSession_ApplePay() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .checkoutSession
        settings.apmsEnabled = .off
        settings.collectEmail = .always // CheckoutSession requires email
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testPaymentSheetFlowControllerSaveAndRemoveCard_DeferredIntent_ServerSideConfirmation() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        settings.apmsEnabled = .off
        // This test case is testing a feature not available when Link is on,
        // so we must manually turn off Link.
        settings.linkPassthroughMode = .passthrough
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController

        loadPlayground(app, settings)

        var paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        try! fillCardData(app)

        // toggle save this card on and off
        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()  // toggle back off
        XCTAssertFalse(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        var successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app)  // If the previous card was saved, we'll be on the 'saved pms' screen and this will fail

        // toggle save this card on
        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        // return to payment method selector
        paymentMethodButton = app.staticTexts["•••• 4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        app.buttons["CircularButton.Edit"].waitForExistenceAndTap()

        let removeButton = app.buttons["Remove"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 60.0))
        removeButton.tap()

        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 60.0))
        confirmRemoval.tap()

        // Should recognize no more pms available and switch to add screen
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 3))
    }
}
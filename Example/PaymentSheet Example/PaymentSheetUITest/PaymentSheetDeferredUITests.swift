//
//  PaymentSheetDeferredUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

class PaymentSheetDeferredUITests: PaymentSheetUITestCase {

    // MARK: Deferred tests (client-side)

    func testDeferredPaymentIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))

        XCTAssertEqual(
            // Ignore luxe_* analytics since there are a lot and I'm not sure if they're the same every time
            // filter out async passive captcha and attestation logs
            analyticsLog.map({ $0[string: "event"] }).filter({ $0 != "luxe_image_selector_icon_from_bundle" && $0 != "luxe_image_selector_icon_downloaded" && !($0?.starts(with: "elements.captcha.passive") ?? false) && !($0?.contains("attest") ?? false) }),
            ["mc_complete_init_applepay", "mc_load_started", "mc_load_succeeded", "mc_complete_sheet_newpm_show", "mc_initial_displayed_payment_methods", "mc_form_shown", "link.inline_signup.shown"]
        )
        let initialDisplayedPaymentMethodsEvent = analyticsLog.first(where: { $0[string: "event"] == "mc_initial_displayed_payment_methods" })
        // two wallet pms and 3 in the carousel
        XCTAssertEqual(
            (initialDisplayedPaymentMethodsEvent.map { $0["visible_payment_methods"] } as? [String])?.count,
            5
        )
        // the rest are hidden
        XCTAssertEqual(
            (initialDisplayedPaymentMethodsEvent.map { $0["hidden_payment_methods"] } as? [String])?.count,
            6
        )
        XCTAssertEqual(
            initialDisplayedPaymentMethodsEvent.map { $0[string: "payment_method_layout"] },
            "horizontal"
        )
        XCTAssertEqual(analyticsLog.filter({ !($0[string: "event"]?.starts(with: "elements.captcha.passive") ?? false || $0[string: "event"]?.contains("attest") ?? false || $0[string: "event"]?.starts(with: "link") ?? false) }).last?[string: "selected_lpm"], "card")

        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // filter out async attestation logs
        XCTAssertEqual(
            analyticsLog.map({ $0[string: "event"] }).filter({ !($0?.starts(with: "elements.captcha.passive") ?? false) && !($0?.contains("attest") ?? false) }).suffix(9),
            ["mc_form_interacted", "mc_card_number_completed", "mc_form_completed", "mc_confirm_button_tapped", "stripeios.confirmation_token_creation", "stripeios.paymenthandler.confirm.started", "stripeios.payment_intent_confirmation", "stripeios.paymenthandler.confirm.finished", "mc_complete_payment_newpm_success"]
        )

        XCTAssertEqual(
            analyticsLog.map({ $0[string: "event"] }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false }),
            ["elements.captcha.passive.init",
             "elements.captcha.passive.execute",
             "elements.captcha.passive.success",
             "elements.captcha.passive.attach", ]
        )

        XCTAssertEqual(
            analyticsLog.map({ $0[string: "event"] }).filter({ $0?.starts(with: "elements.attestation.confirmation") ?? false }),
            ["elements.attestation.confirmation.prepare",
             "elements.attestation.confirmation.prepare_failed",
             "elements.attestation.confirmation.request_token",
             "elements.attestation.confirmation.request_token_succeeded", ]
        )

        // Make sure they all have the same session id
        let sessionID = analyticsLog.first![string: "session_id"]
        XCTAssertTrue(!sessionID!.isEmpty)
        for analytic in analyticsLog {
            XCTAssertEqual(analytic[string: "session_id"], sessionID)
        }

    }

    func testDeferredPaymentIntent_ClientSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].tap()

        let declineText = app.staticTexts["Your card was declined."]
        XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.mode = .setup
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
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

    func testDeferredSetupIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
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
    /* Disable Link test
     func testDeferferedIntentLinkSignup_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
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
    func testDeferredPaymentIntent_ApplePay_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredIntent_ApplePayFlowControllerFlow_ClientSideConfirmation() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.uiStyle = .flowController
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .pm
        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
        paymentMethodButton.tap()

        let applePay = app.collectionViews.buttons["Apple Pay"]
        XCTAssertTrue(applePay.waitForExistence(timeout: 10.0))
        applePay.tap()

        app.buttons["Confirm"].tap()

        payWithApplePay()
    }
}

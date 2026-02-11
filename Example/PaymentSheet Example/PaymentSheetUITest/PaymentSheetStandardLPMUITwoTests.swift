//
//  PaymentSheetStandardLPMUITwoTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

class PaymentSheetStandardLPMUITwoTests: PaymentSheetStandardLPMUICase {
    func testUSBankAccountPaymentMethod() throws {
        app.launchEnvironment = app.launchEnvironment.merging([
            "FinancialConnectionsSDKAvailable": "true",
            "FinancialConnectionsStubbedResult": "true",
        ]) { (_, new) in new }
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select US Bank Account
        tapPaymentMethod("US bank account")

        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)

        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = app.textFields["Email"]
        email.tap()
        email.typeText("test@example.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 5))

        let selectedMandate =
        "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."
        let unselectedMandate = "By continuing, you agree to authorize payments pursuant to these terms."
        XCTAssertTrue(
            app.textViews[unselectedMandate].waitForExistence(timeout: 5)
        )

        let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
        saveThisAccountToggle.tap()
        XCTAssertTrue(
            app.textViews[selectedMandate].waitForExistence(timeout: 5)
        )

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testPaymentIntent_USBankAccount() {
        _testUSBankAccount(mode: .payment, integrationType: .normal)
    }

    func testSetupIntent_USBankAccount() {
        _testUSBankAccount(mode: .setup, integrationType: .normal)
    }

    // Disabled
    func _testPaymentIntent_instantDebits() {
        _testInstantDebits(mode: .payment)
    }

    // Disabled
    func _testSetupIntent_instantDebits() {
        _testInstantDebits(mode: .setup)
    }

    func testSavedSEPADebitPaymentMethod_FlowController_ShowsMandate() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        settings.mode = .setup
        settings.customerKeyType = .customerSession
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        // Save SEPA
        app.buttons["+ Add"].waitForExistenceAndTap()
        tapPaymentMethod("SEPA Debit")
        try! fillSepaData(app, iban: "AT611904300234573201", tapCheckboxWithText: "Save this account for future Example, Inc. payments")
        app.swipeUp()
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        // This time, expect SEPA to be pre-selected as the default
        XCTAssert(paymentMethodButton.label.hasPrefix("••••3201, sepa_debit"))

        // Tapping confirm without presenting flowcontroller should show the mandate
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.otherElements.matching(identifier: "mandatetextview").element.waitForExistence(timeout: 1))
        // Tapping out should cancel the payment
        app.buttons["UIButton.Close"].tap()
        XCTAssertTrue(app.staticTexts["Payment canceled."].waitForExistence(timeout: 10.0))
        // Tapping confirm again and hitting continue should confirm the payment
        app.buttons["Confirm"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        // If you present the flowcontroller and see the mandate...
        XCTAssert(paymentMethodButton.label.hasPrefix("••••3201, sepa_debit"))
        paymentMethodButton.waitForExistenceAndTap()

        XCTAssertTrue(app.otherElements.matching(identifier: "mandatetextview").element.exists)
        // ...you shouldn't see the mandate again when you confirm
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }
}
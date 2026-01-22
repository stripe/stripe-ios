//
//  PaymentSheetLPMUITest.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 7/17/24.
//

import XCTest

class PaymentSheetStandardLPMUIOneTests: PaymentSheetStandardLPMUICase {
    // UPI is a little custom and isn't well-tested by PaymentSheet_LPM_ConfirmFlowTests
    func testUPIPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .IN
        settings.currency = .inr
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay ₹50.99"].waitForExistence(timeout: 5))

        let payButton = app.buttons["Pay ₹50.99"]
        tapPaymentMethod("UPI")

        XCTAssertFalse(payButton.isEnabled)
        // Test invalid VPA
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success" + XCUIKeyboardKey.return.rawValue)
        XCTAssertFalse(payButton.isEnabled)

        // Test valid VPA
        upi_id.tap()
        upi_id.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "payment.success".count))
        upi_id.typeText("payment.success@stripeupi" + XCUIKeyboardKey.return.rawValue)
        payButton.tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // This Cash App test is a good way to test the cancellation/success behavior
    // of the refresh endpoint E2E.
    func testRefreshEndpointUsingCashAppPay() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay $50.99"]

        // Select Cash App
        guard let cashApp = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Cash App Pay")
        else {
            XCTFail()
            return
        }
        cashApp.waitForExistenceAndTap()

        // Attempt payment
        payButton.waitForExistenceAndTap()

        // Wait 2x 300ms for window to animate in
        Thread.sleep(forTimeInterval: 0.60)

        // Close the webview, to simulate cancel
        _ = app.otherElements["TopBrowserBar"].waitForExistence(timeout: 5.0)
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 15.0)

        // Tap to attempt a payment, but fail it
        payButton.waitForExistenceAndTap()
        let failPaymentText = app.firstDescendant(withLabel: "FAIL TEST PAYMENT")
        failPaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["The customer declined this payment."].waitForExistence(timeout: 5.0))

        // Tap to attempt a payment
        payButton.waitForExistenceAndTap()
        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }
}

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

class PaymentSheetStandardLPMUICBCTests: PaymentSheetStandardLPMUICase {
    // MARK: Card brand choice

    func testCardBrandChoice() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoice_setup() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .setup
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        _testCardBrandChoice(isSetup: true, settings: settings)
    }

    func testCardBrandChoice_deferred() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.integrationType = .deferred_csc
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoiceWithPreferredNetworks() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .on
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        let cardBrandTextField = app.textFields["Visa"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistence(timeout: 2))

        let numberField = app.textFields["Card number"]
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeDown()
        app.toolbars.buttons["Cancel"].tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 2))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].waitForExistence(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled and we should auto select Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Finish checkout
        app.buttons["Pay €50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCardBrandChoiceSavedCard() {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        let numberField = app.textFields["Card number"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistence(timeout: 5))

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Finish checkout
        app.buttons["Pay €50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))

        // Update this card
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.swipeUp()
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistence(timeout: 5))

        // Update this card again
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.textFields["Visa"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.swipeDown()
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Cartes Bancaires
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // Pay with this card
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        // Remove this card
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 60.0))
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.buttons["Remove"].waitForExistenceAndTap(timeout: 5))
        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 5))
        confirmRemoval.tap()

        // Card should be removed
        XCTAssertFalse(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
    }

    func testCardBrandChoiceUpdateAndRemove() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.customerMode = .returning
        settings.layout = .horizontal
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        app.buttons["Edit"].waitForExistenceAndTap()

        XCTAssertEqual(app.images.matching(identifier: "carousel_card_cartes_bancaires").count, 1)
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)

        XCTAssertEqual(app.buttons.matching(identifier: "CircularButton.Edit").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap()
        app.otherElements.matching(identifier: "Card Brand Dropdown").firstMatch.waitForExistenceAndTap()
        app.pickerWheels.firstMatch.selectNextOption()
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 3))
        app.buttons["Save"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").element(boundBy: 1).waitForExistenceAndTap()
        app.buttons["Remove"].waitForExistenceAndTap()
        app.alerts.buttons["Remove"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)
        app.buttons["Done"].waitForExistenceAndTap()
    }

    func testCustomPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.customPaymentMethods = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        tapPaymentMethod("BufoPay (test)")

        app.buttons["Pay $50.99"].tap()
        app.alerts.buttons["Confirm"].waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
}

// MARK: - Helpers
class PaymentSheetStandardLPMUICase: PaymentSheetUITestCase {

}

extension PaymentSheetStandardLPMUICase {
    var webviewAuthorizePaymentButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT") }
    var webviewAuthorizeSetupButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST SETUP") }
    func tapPaymentMethod(_ id: String) {
        guard let pm = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: id) else {
            XCTFail()
            return
        }
        pm.tap()
    }

    /// This waits for the ["PaymentSheetExample" Wants to Use "stripe.com" to Sign In] modal that
    /// `ASWebAuthenticationSession` shows and taps continue to allow the web view to open:
    func waitForASWebAuthSigninModalAndTapContinue() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let sbContinueButton = springboard.buttons["Continue"]
        XCTAssertTrue(sbContinueButton.waitForExistence(timeout: 10.0))
        sbContinueButton.tap()
    }
}

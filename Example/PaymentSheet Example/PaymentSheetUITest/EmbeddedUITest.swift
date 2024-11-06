//
//  EmbeddedUITest.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 10/23/24.
//

import XCTest

class EmbeddedUITests: PaymentSheetUITestCase {
    func testUpdate() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        // TODO: Test card form (see PaymentSheetVerticalUITests testUpdate)

        // Selecting Alipay w/ deferred PaymentIntent...
        app.buttons["Alipay"].waitForExistenceAndTap()
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Alipay")
        // ...and *updating* to a SetupIntent...
        app.buttons.matching(identifier: "Setup").element(boundBy: 1).tap()
        // ...(wait for it to finish updating)...
        _ = app.buttons["Reload"].waitForExistence(timeout: 10)
        // ...should cause Alipay to no longer be the selected payment method, since it is not valid for setup.
        XCTAssertFalse(app.staticTexts["Payment method"].exists)
    }

    func testSingleCardCBC_update_and_remove() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.customerKeyType = .legacy
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)

        // Complete payment
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))

        // Switch to embedded mode kicks off a reload
        app.buttons["embedded"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()

        // Ensure card preference is cartes bancaires
        XCTAssertTrue(app.buttons["•••• 1001"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_visa"].waitForExistence(timeout: 3))

        app.buttons["Edit"].waitForExistenceAndTap()
        app.otherElements["Card Brand Dropdown"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.swipeUp()
        app.buttons["Done"].waitForExistenceAndTap()
        app.buttons["Update"].waitForExistenceAndTap()
        XCTAssertFalse(app.staticTexts["Update card brand"].waitForExistence(timeout: 3))

        // Ensure card preference is switched to visa
        XCTAssertTrue(app.buttons["•••• 1001"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.images["stp_card_visa"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))

        // Now remove card
        app.buttons["Edit"].waitForExistenceAndTap()

        // Ensure Popup is presented
        XCTAssertTrue(app.staticTexts["Update card brand"].waitForExistence(timeout: 3.0))
        app.buttons["Remove card"].waitForExistenceAndTap()
        dismissAlertView(alertBody: "Visa •••• 1001", alertTitle: "Remove card?", buttonToTap: "Remove")

        // Ensure popup is implicitly dismissed
        XCTAssertFalse(app.staticTexts["Update card brand"].waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.images["stp_card_visa"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))
    }

    func testMulipleCardWith_updateCBCWithinViewMore() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.customerKeyType = .legacy
        settings.customerMode = .returning
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        ensureSPMSelection("•••• 1001", insteadOf: "•••• 4242")

        // Switch from 1001 to 4242
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Edit"].waitForExistenceAndTap()
        app.otherElements["Card Brand Dropdown"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.swipeUp()
        app.buttons["Done"].waitForExistenceAndTap()
        app.buttons["Update"].waitForExistenceAndTap()

        // Tap done on manage payment methods screen, then select 4242 card
        app.buttons["Done"].waitForExistenceAndTap()
        app.buttons["•••• 4242"].waitForExistenceAndTap()

        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.buttons["•••• 1001"].waitForExistence(timeout: 3.0))
    }

    func testMultipleCard_update_and_remove() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.customerKeyType = .legacy
        settings.customerMode = .returning
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        ensureSPMSelection("••••6789", insteadOf: "•••• 4242")

        // Switch from 6789 (Bank account) to 4242
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["•••• 4242"].waitForExistenceAndTap()

        XCTAssertFalse(app.buttons["••••6789"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 3.0))

        // Remove selected 4242 card
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        dismissAlertView(alertBody: "Visa •••• 4242", alertTitle: "Remove card?", buttonToTap: "Remove")
        app.buttons["Done"].waitForExistenceAndTap()

        // Since there is only one PM left, sheet dismisses automatically on tapping Done.
        XCTAssertTrue(app.buttons["••••6789"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.buttons["•••• 4242"].waitForExistence(timeout: 3.0))

        // Remove 6789 & verify
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        dismissAlertView(alertBody: "Bank account •••• 6789", alertTitle: "Remove bank account?", buttonToTap: "Remove")

        XCTAssertFalse(app.buttons["•••• 4242"].waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.buttons["••••6789"].waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].waitForExistence(timeout: 3.0))

    }
    
    func testSelection() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        // Open card and cancel, should not be selected
        app.buttons["Card"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertFalse(app.buttons["Checkout"].isEnabled)
        
        // Select Cash App Pay
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Cash App Pay"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Open card and cancel, should reset back to Cash App Pay
        app.buttons["Card"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Cash App Pay"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Try to fill a card
        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Tapping on card again should present the form filled out
        app.buttons["Card"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Add card"].waitForExistence(timeout: 5.0))
        let cardNumberField = app.textFields["Card number"]
        XCTAssertEqual(cardNumberField.value as? String, "4242424242424242", "Card number field should contain the entered card number.")
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)

        // Select and cancel out a form PM to ensure that 4242 card is still selected
        app.buttons["Klarna"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Select a no-form PM such as Cash App Pay
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Cash App Pay"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // FIll out US Bank Acct.
        app.buttons["US bank account"].waitForExistenceAndTap()
        // Fill out name and email fields
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Full name"].tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test-\(UUID().uuidString)@example.com" + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].tap()
        app.staticTexts["Test Institution"].forceTapElement()
        // "Success" institution is automatically selected because its the first
        app.buttons["connect_accounts_button"].waitForExistenceAndTap(timeout: 10)

        let notNowButton = app.buttons["Not now"]
        if notNowButton.waitForExistence(timeout: 10.0) {
            app.typeText(XCUIKeyboardKey.return.rawValue) // dismiss keyboard
            notNowButton.tap()
        }

        app.buttons["Continue"].waitForExistenceAndTap()
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["••••6789"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
    }

    func dismissAlertView(alertBody: String, alertTitle: String, buttonToTap: String) {
        let alertText = app.staticTexts[alertBody]
        XCTAssertTrue(alertText.waitForExistence(timeout: 5))

        let alert = app.alerts[alertTitle]
        alert.buttons[buttonToTap].tap()
    }

    // Returning customers have two payment methods in a non-deterministic order.
    // Ensure state of payment method of label1 is selected prior to starting tests.
    func ensureSPMSelection(_ label1: String, insteadOf label2: String) {
        if app.buttons[label1].waitForExistence(timeout: 3.0) {
            XCTAssertFalse(app.buttons[label2].waitForExistence(timeout: 3.0))
            return
        }
        guard app.buttons[label2].waitForExistence(timeout: 3.0) else {
            XCTFail("Unable to find either \(label1) or \(label2)")
            return
        }
        app.buttons["View more"].waitForExistenceAndTap(timeout: 3.0)
        app.buttons[label1].waitForExistenceAndTap(timeout: 3.0)
        XCTAssertTrue(app.buttons[label1].waitForExistence(timeout: 3.0))

    }
}

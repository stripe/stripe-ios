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

//
//  EmbeddedSelectionRevertUITests.swift
//  PaymentSheetUITest
//

import XCTest

/// Tests that EmbeddedPaymentElement selection and the locally persisted default stay consistent
/// when sheets it presents (forms, the manage screen) are cancelled, including after deletions.
class EmbeddedSelectionRevertUITests: PaymentSheetUITestCase {

    func testEmbedded_formCancel_revertAndPersistenceConsistent() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.customerMode = .returning
        settings.customerKeyType = .legacy
        settings.allowsDelayedPMs = .off
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()

        // The saved card should auto-select
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)

        // Commit Apple Pay by tapping its row
        app.buttons["Apple Pay"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Apple Pay"].isSelected)
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Apple Pay")

        // Open a form and cancel — selection should revert to Apple Pay
        app.buttons["New card"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Apple Pay")
        XCTAssertTrue(app.buttons["Apple Pay"].isSelected)

        // Reload: the persisted default should be Apple Pay, consistent with what's shown
        reload(app, settings: settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Apple Pay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Apple Pay"].isSelected, "Persisted default should match the last committed selection")
        XCTAssertFalse(app.buttons["•••• 4242"].isSelected)
    }

    func testEmbedded_manageScreen_deleteSelectedPM_thenDismiss_gracefulFallback() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.customerMode = .returning
        settings.customerKeyType = .legacy
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        ensureSPMSelection("•••• 4242", insteadOf: "••••6789")

        // Delete the selected card from the manage screen
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["chevron"].firstMatch.waitForExistenceAndTap()
        app.buttons["Remove"].waitForExistenceAndTap()
        dismissAlertView(alertBody: "Visa •••• 4242", alertTitle: "Remove card?", buttonToTap: "Remove")
        app.buttons["Done"].waitForExistenceAndTap()

        // With one PM left the manage screen auto-dismisses; the remaining PM takes over
        XCTAssertTrue(app.buttons["••••6789"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["••••6789"].isSelected)
        XCTAssertFalse(app.buttons["•••• 4242"].waitForExistence(timeout: 2))

        // Reload: the deleted card must not come back as the persisted default
        reload(app, settings: settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["••••6789"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["•••• 4242"].waitForExistence(timeout: 2), "Deleted card should be gone after reload")
    }

    func testEmbedded_manageScreen_deleteNonSelectedPM_thenDismiss_selectionUntouched() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.customerMode = .returning
        settings.customerKeyType = .legacy
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        ensureSPMSelection("•••• 4242", insteadOf: "••••6789")

        // Delete the non-selected bank account from the manage screen
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        let bankChevron = app.otherElements["••••6789"].buttons["chevron"]
        if bankChevron.waitForExistence(timeout: 2) {
            bankChevron.tap()
        } else {
            app.buttons["chevron"].firstMatch.waitForExistenceAndTap()
        }
        app.buttons["Remove"].waitForExistenceAndTap()
        dismissAlertView(alertBody: "Bank account •••• 6789", alertTitle: "Remove bank account?", buttonToTap: "Remove")
        sleep(1)
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        }
        sleep(1)

        // The original selection should be untouched
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")

        // Reload: still the saved card, bank account gone
        reload(app, settings: settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        if !app.buttons["•••• 4242"].waitForExistence(timeout: 10) {
            // The playground occasionally fails a load right after a detach; retry once
            reload(app, settings: settings)
            app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        }
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        XCTAssertFalse(app.buttons["••••6789"].waitForExistence(timeout: 2))
    }

    func testEmbedded_sameRowFormCancel_afterEdit_revertsToCommittedCard() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.customerMode = .new
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()

        // Commit card A via Continue
        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "4242424242424242", postalEnabled: true)
        app.stp_dismissKeyboard() // The keyboard covers the Continue button
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        XCTAssertTrue(app.buttons["Card"].isSelected)

        // Re-open the same row's form, edit it to card B, then cancel
        app.buttons["Card"].waitForExistenceAndTap()
        let cardNumberField = app.textFields["Card number"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 5))
        XCTAssertEqual(cardNumberField.value as? String, "4242424242424242")
        cardNumberField.tap()
        cardNumberField.clearText()
        app.typeText("5555555555554444")
        app.buttons["Close"].waitForExistenceAndTap()

        // The selection should revert to card A, not clear or become card B
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        XCTAssertTrue(app.buttons["Card"].isSelected)

        // Re-open: the form should be restored to card A
        app.buttons["Card"].waitForExistenceAndTap()
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 5))
        XCTAssertEqual(cardNumberField.value as? String, "4242424242424242", "Form should be restored to the committed card after cancel")
    }

    func testEmbedded_sameRowFormCancel_afterEditingExternalPMForm_revertsToCommitted() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.customerMode = .new
        settings.externalPaymentMethods = .paypal
        settings.collectName = .always // Forces a billing details form for the external PM
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()

        // Commit external PayPal (with a name) via Continue
        app.buttons["PayPal"].waitForExistenceAndTap()
        let nameField = app.textFields["Full name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        app.typeText("Jane Doe")
        XCTAssertTrue(app.buttons["Continue"].waitForExistenceAndTap()) // Visible above the keyboard
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "PayPal")
        XCTAssertTrue(app.buttons["PayPal"].isSelected)

        // Re-open the same row's form, change the name, then cancel
        app.buttons["PayPal"].waitForExistenceAndTap()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.clearText()
        app.typeText("John Smith")
        XCTAssertTrue(app.buttons["Close"].waitForExistenceAndTap()) // Visible above the keyboard

        // The selection should revert to the committed PayPal, not clear
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "PayPal")
        XCTAssertTrue(app.buttons["PayPal"].isSelected)

        // Re-open: the form should be restored to the committed name
        app.buttons["PayPal"].waitForExistenceAndTap()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Jane Doe", "Form should be restored to the committed input after cancel")
    }

    func testEmbedded_sameRowFormCancel_afterUpdate_stillRestoresCommittedCard() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()

        // Commit a card via Continue
        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)
        app.stp_dismissKeyboard()
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")

        // Switch to setup mode and back to payment — each triggers update(); the second one
        // restores the completed card form and keeps it selected
        app.buttons.matching(identifier: "Setup").element(boundBy: 1).waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        app.buttons["Card"].waitForExistenceAndTap()
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Payment").element(boundBy: 1).waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        XCTAssertTrue(app.buttons["Card"].isSelected)

        // Edit the restored form, then cancel — the committed card should be restored, not cleared
        app.buttons["Card"].waitForExistenceAndTap()
        let cardNumberField = app.textFields["Card number"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 5))
        cardNumberField.tap()
        cardNumberField.clearText()
        app.typeText("5555555555554444")
        app.buttons["Close"].waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10), "Selection should be restored after cancelling an edited form post-update")
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        XCTAssertTrue(app.buttons["Card"].isSelected)
    }

    // MARK: - Helpers (mirrored from EmbeddedUITests)

    /// Returning customers have two payment methods in a non-deterministic order.
    /// Ensure the payment method with `label1` is selected prior to starting the test.
    private func ensureSPMSelection(_ label1: String, insteadOf label2: String) {
        let timeout: TimeInterval = 10.0
        if !app.buttons[label1].waitForExistence(timeout: timeout) {
            guard app.buttons[label2].waitForExistence(timeout: timeout) else {
                XCTFail("Unable to find either \(label1) or \(label2)")
                return
            }
            XCTAssertTrue(app.buttons["View more"].waitForExistenceAndTap(timeout: timeout))
            XCTAssertTrue(app.buttons[label1].waitForExistenceAndTap(timeout: timeout))
            sleep(1) // Allow the manage screen to dismiss
        }
        XCTAssertTrue(app.buttons[label1].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[label1].isSelected, "\(label1) should be selected after ensuring selection")
        XCTAssertEqual(app.staticTexts["Payment method"].label, label1)
    }

    private func dismissAlertView(alertBody: String, alertTitle: String, buttonToTap: String) {
        let alertText = app.staticTexts[alertBody]
        XCTAssertTrue(alertText.waitForExistence(timeout: 5))

        let alert = app.alerts[alertTitle]
        alert.buttons[buttonToTap].tap()
    }
}

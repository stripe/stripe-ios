//
//  PaymentSheetVerticalUITest.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 6/25/24.
//

import XCTest

// MARK: Vertical mode tests
class PaymentSheetVerticalUITests: PaymentSheetUITestCase {
    func testFlowController_verticalMode() {
        // Sets the right paymentOption values
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .setup
        settings.customerMode = .new
        settings.currency = .eur
        settings.uiStyle = .flowController
        settings.layout = .vertical
        loadPlayground(app, settings)
        let paymentMethodButton = app.buttons["Payment method"].firstMatch
        XCTAssertEqual(paymentMethodButton.label, "None")
        paymentMethodButton.waitForExistenceAndTap()

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertFalse(continueButton.isEnabled)
        app.buttons["Apple Pay"].firstMatch.tap()
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "Apple Pay, apple_pay")

        // Reload - it should now default to "Apple Pay"
        reload(app, settings: settings)
        XCTAssertEqual(paymentMethodButton.label, "Apple Pay, apple_pay")
        paymentMethodButton.tap()
        XCTAssertTrue(app.buttons["Apple Pay"].firstMatch.isSelected)

        // Select Link - FC paymentOption should change to Link
        app.buttons["Link"].firstMatch.tap()
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "Link, link")

        // Go back in, select Card
        paymentMethodButton.tap()
        app.buttons["Card"].firstMatch.tap()
        XCTAssertFalse(continueButton.isEnabled)
        // Enter some incomplete details
        app.textFields["Card number"].firstMatch.tap()
        app.textFields["Card number"].firstMatch.typeText("1")
        XCTAssertFalse(continueButton.isEnabled)
        app.tapCoordinate(at: .init(x: 200, y: 100))
        // Tap out of FlowController and expect empty payment method
        app.tapCoordinate(at: .init(x: 200, y: 100))
        XCTAssertEqual(paymentMethodButton.label, "None")

        // Go back in
        paymentMethodButton.tap()
        XCTAssertFalse(continueButton.isEnabled)
        // Back out of card form
        app.buttons["Back"].firstMatch.tap()
        // Link shouldn't be selected anymore
        XCTAssertFalse(app.buttons["Link"].firstMatch.isSelected)
        XCTAssertFalse(continueButton.isEnabled)

        // Go back to card
        app.buttons["Card"].firstMatch.waitForExistenceAndTap()
        // Make sure the card form retained previously entered details
        XCTAssertEqual(app.textFields["Card number"].firstMatch.value as? String, "1, Your card number is invalid.")
        app.textFields["Card number"].firstMatch.clearText()
        // Finish the card payment
        try! fillCardData(app, cardNumber: "4242424242424242")
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "••••4242, card, 12345, US")
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistence(timeout: 10))

        // Reload
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10))
        XCTAssertEqual(paymentMethodButton.label, "••••4242, card, 12345, US")
        paymentMethodButton.tap()

        XCTAssertTrue(app.buttons["••••4242"].firstMatch.isSelected)
        XCTAssertTrue(continueButton.isEnabled)

        // Add a SEPA Debit PM
        app.buttons["SEPA Debit"].firstMatch.tap()
        try! fillSepaData(app)
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "SEPA Debit, sepa_debit, 123 Main, San Francisco, CA, 94016, US")
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistence(timeout: 10))

        // Reload
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10))
        XCTAssertEqual(paymentMethodButton.label, "••••3000, sepa_debit, John Doe, test@example.com, 123 Main, San Francisco, CA, 94016, US")
        paymentMethodButton.tap()

        // Switch to the saved card...
        app.buttons["View more"].firstMatch.waitForExistenceAndTap()
        app.buttons["••••4242"].firstMatch.waitForExistenceAndTap()
        app.buttons["Continue"].firstMatch.tap() // For some reason, waitForExistenceAndTap() does not tap this!
        // ...reload...
        reload(app, settings: settings)
        // ...and the saved card should be the default
        XCTAssertEqual(paymentMethodButton.label, "••••4242, card, 12345, US")
    }

    func testUSBankAccount_verticalmode() {
        _testUSBankAccount(mode: .payment, integrationType: .normal, vertical: true)
    }

    func testInstantDebits_verticalmode() {
        _testInstantDebits(mode: .payment, vertical: true)
    }

    func testPayingWithNoFormPMs_verticalmode() {
        // We choose Alipay as a representative PM that does not require form details
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        settings.layout = .vertical
        loadPlayground(app, settings)

        // Try Alipay
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        app.buttons["Alipay"].firstMatch.waitForExistenceAndTap()
        app.buttons["Pay $50.99"].firstMatch.tap()
        // Cancel
        XCTAssertTrue(app.webViews.staticTexts["Alipay test payment page"].waitForExistence(timeout: 10))
        app.otherElements["TopBrowserBar"].firstMatch.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.waitForExistence(timeout: 1))
        // Fail payment
        app.buttons["Pay $50.99"].firstMatch.tap()
        app.waitForButtonOrStaticText("FAIL TEST PAYMENT").tap()
        let errorMessage = app.staticTexts["We are unable to authenticate your payment method. Please choose a different payment method and try again."].firstMatch
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))

        // Try Cash App Pay
        app.buttons["Cash App Pay"].firstMatch.waitForExistenceAndTap()
        // Validate error disappears
        XCTAssertFalse(errorMessage.waitForExistence(timeout: 0.1))
        app.buttons["Pay $50.99"].firstMatch.tap()
        app.waitForButtonOrStaticText("AUTHORIZE TEST PAYMENT").tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistence(timeout: 10))
    }

    func testCanPayWithApplePayWallet_verticalMode() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        loadPlayground(app, settings)

        app.buttons["vertical"].firstMatch.waitForExistenceAndTap()
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["apple_pay_button"].firstMatch.waitForExistenceAndTap())
        payWithApplePay()
    }

    func testCanPayWithLinkWallet_verticalMode() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        loadPlayground(app, settings)

        XCTAssertTrue(app.buttons["vertical"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap())

        let expectation = XCTestExpectation(description: "Link sign in dialog")
        // Listen for the system login dialog
        addUIInterruptionMonitor(withDescription: "Link sign in system dialog") { alert in
            // Cancel the payment
            XCTAssertTrue(alert.buttons["Cancel"].waitForExistenceAndTap())
            expectation.fulfill()
            return true
        }

        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceAndTap())
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.app.tap() // required to trigger the UI interruption monitor
        }
        wait(for: [expectation], timeout: 5.0)
    }

    func testRemovalOfSavedPaymentMethods_verticalMode() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.currency = .eur
        settings.merchantCountryCode = .FR
        settings.mode = .setup
        loadPlayground(app, settings)

        // Save some test cards to the customer
        setupCards(cards: ["4000002500001001", "4242424242424242"], settings: settings)

        app.buttons["vertical"].firstMatch.waitForExistenceAndTap() // TODO(porter) Use the vertical mode to save cards when ready
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["View more"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Select card"].firstMatch.waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Edit"].firstMatch.waitForExistenceAndTap())

        // Remove one of the payment methods just added
        app.buttons["CircularButton.Remove"].firstMatch.firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        // Exit edit mode, remove button should be hidden
        XCTAssertTrue(app.buttons["Done"].firstMatch.waitForExistenceAndTap())
        XCTAssertFalse(app.buttons["CircularButton.Remove"].firstMatch.waitForExistence(timeout: 2.0))

        // Update the card brand on the last card
        XCTAssertTrue(app.buttons["Cartes Bancaires ending in 1 0 0 1"].firstMatch.waitForExistence(timeout: 1.0)) // Cartes Bancaires card should be selected now that 4242 card is removed
        XCTAssertTrue(app.buttons["Edit"].firstMatch.waitForExistenceAndTap())
        app.buttons["CircularButton.Edit"].firstMatch.firstMatch.waitForExistenceAndTap()

        // Should present the update card view controller
        XCTAssertTrue(app.staticTexts["Update card brand"].firstMatch.waitForExistence(timeout: 2.0))

        // Update card brand to Visa
        XCTAssertTrue(app.textFields["Cartes Bancaires"].firstMatch.waitForExistenceAndTap(timeout: 5))
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistence(timeout: 5))

        // Update the card
        app.buttons["Update"].firstMatch.waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.buttons["Visa ending in 1 0 0 1"].firstMatch.waitForExistence(timeout: 1.0))

        // Reselect edit icon and delete the card from the update view controller
        app.buttons["Edit"].firstMatch.firstMatch.waitForExistenceAndTap()
        app.buttons["Remove card"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        // Verify we are kicked out to the main screen after removing all saved payment methods
        XCTAssertTrue(app.buttons["Card"].firstMatch.waitForExistence(timeout: 5.0))
        // Verify there's no more Saved section
        XCTAssertFalse(app.staticTexts["Saved"].firstMatch.waitForExistence(timeout: 0.1))
        // Verify primary button isn't enabled b/c there is no selected PM
        XCTAssertFalse(app.buttons["Set up"].firstMatch.isEnabled)
    }

    private func setupCards(cards: [String], settings: PaymentSheetTestPlaygroundSettings) {
        for cardNumber in cards {
            reload(app, settings: settings)
            app.buttons["Present PaymentSheet"].firstMatch.tap()
            let addCardButton = app.buttons["+ Add"].firstMatch
            addCardButton.waitForExistenceAndTap()
            try! fillCardData(app, cardNumber: cardNumber)
            app.buttons["Set up"].firstMatch.tap()
            let successText = app.staticTexts["Success!"].firstMatch
            XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        }
    }

    func testCVCRecollection_verticalMode() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .vertical
        settings.uiStyle = .paymentSheet
        settings.customerMode = .new
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkEnabled = .off
        settings.requireCVCRecollection = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        app.buttons["Card"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app)
        app.switches["Save this card for future Example, Inc. payments"].firstMatch.waitForExistenceAndTap()
        app.buttons["Pay $50.99"].firstMatch.waitForExistenceAndTap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        app.buttons["Pay $50.99"].firstMatch.waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Confirm your CVC"].firstMatch.waitForExistence(timeout: 1))
        // CVC field should already be selected
        app.typeText("123")
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
}

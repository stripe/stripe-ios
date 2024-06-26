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
        settings.uiStyle = .flowController
        settings.layout = .vertical
        loadPlayground(app, settings)
        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertEqual(paymentMethodButton.label, "None")
        paymentMethodButton.waitForExistenceAndTap()

        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.buttons["Apple Pay"].tap()
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "Apple Pay, apple_pay")

        // Go back in, select Link
        paymentMethodButton.tap()
        app.buttons["Link"].tap()
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "Link, link")

        // Go back in, select Card
        paymentMethodButton.tap()
        app.buttons["Card"].tap()
        XCTAssertFalse(continueButton.isEnabled)
        // Enter some details
        app.textFields["Card number"].tap()
        app.textFields["Card number"].typeText("1")
        XCTAssertFalse(continueButton.isEnabled)
        app.tapCoordinate(at: .init(x: 200, y: 100))
        // Tap out of FlowController
        app.tapCoordinate(at: .init(x: 200, y: 100))
        XCTAssertEqual(paymentMethodButton.label, "None")

        // Go back in
        paymentMethodButton.tap()
        XCTAssertFalse(continueButton.isEnabled)
        // Back out of card form
        app.buttons["Back"].tap()
        // Link should be selected
        XCTAssertTrue(app.buttons["Link"].isSelected)
        XCTAssertTrue(continueButton.isEnabled)

        // Go back to card
        app.buttons["Card"].waitForExistenceAndTap()
        // Make sure the card form retained previously entered details
        XCTAssertEqual(app.textFields["Card number"].value as? String, "1, Your card number is invalid.")
        app.textFields["Card number"].clearText()
        // Finish the card payment
        try! fillCardData(app, cardNumber: "4242424242424242")
        continueButton.tap()
        XCTAssertEqual(paymentMethodButton.label, "••••4242, card, 12345, US")
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))

        // Reload
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10))
        XCTAssertEqual(paymentMethodButton.label, "••••4242, card, 12345, US")
        paymentMethodButton.tap()

        XCTAssertTrue(app.buttons["••••4242"].isSelected)
        XCTAssertTrue(continueButton.isEnabled)
    }

    func testUSBankAccount_verticalmode() {
        _testUSBankAccount(mode: .payment, integrationType: .normal, vertical: true)
    }

    func testPayingWithNoFormPMs_verticalmode() {
        // We choose Alipay as a representative PM that does not require form details
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        settings.layout = .vertical
        loadPlayground(app, settings)

        // Try Alipay
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["Alipay"].waitForExistenceAndTap()
        app.buttons["Pay $50.99"].tap()
        // Cancel
        XCTAssertTrue(app.webViews.staticTexts["Alipay test payment page"].waitForExistence(timeout: 10))
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 1))
        // Fail payment
        app.buttons["Pay $50.99"].tap()
        app.waitForButtonOrStaticText("FAIL TEST PAYMENT").tap()
        XCTAssertTrue(app.staticTexts["We are unable to authenticate your payment method. Please choose a different payment method and try again."].waitForExistence(timeout: 10))

        // Try Cash App Pay
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        app.buttons["Pay $50.99"].tap()
        app.waitForButtonOrStaticText("AUTHORIZE TEST PAYMENT").tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }

    func testCanPayWithApplePayWallet_verticalMode() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        loadPlayground(app, settings)

        app.buttons["vertical"].waitForExistenceAndTap()
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["apple_pay_button"].waitForExistenceAndTap())
        payWithApplePay()
    }

    func testCanPayWithLinkWallet_verticalMode() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .payment
        loadPlayground(app, settings)

        XCTAssertTrue(app.buttons["vertical"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["Present PaymentSheet"].waitForExistenceAndTap())

        let expectation = XCTestExpectation(description: "Link sign in dialog")
        // Listen for the system login dialog
        addUIInterruptionMonitor(withDescription: "Link sign in system dialog") { alert in
            // Cancel the payment
            XCTAssertTrue(alert.buttons["Cancel"].waitForExistenceAndTap())
            expectation.fulfill()
            return true
        }

        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistenceAndTap())
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

        app.buttons["vertical"].waitForExistenceAndTap() // TODO(porter) Use the vertical mode to save cards when ready
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["View more"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Select card"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.buttons["Edit"].waitForExistenceAndTap())

        // Remove both the payment methods just added
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        // Exit edit mode, remove button should be hidden
        XCTAssertTrue(app.buttons["Done"].waitForExistenceAndTap())
        XCTAssertFalse(app.buttons["CircularButton.Remove"].waitForExistence(timeout: 2.0))

        // Update the card brand on the last card
        XCTAssertTrue(app.buttons["Cartes Bancaires ending in 1 0 0 1"].waitForExistence(timeout: 1.0)) // Cartes Bancaires card should be selected now that 4242 card is removed
        XCTAssertTrue(app.buttons["Edit"].waitForExistenceAndTap())
        app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap()

        // Should present the update card view controller
        XCTAssertTrue(app.staticTexts["Update card brand"].waitForExistence(timeout: 2.0))

        // Update card brand to Visa
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistenceAndTap(timeout: 5))
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Update the card
        app.buttons["Update"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.buttons["Visa ending in 1 0 0 1"].waitForExistence(timeout: 1.0))

        // Reselect edit icon and delete the card from the update view controller
        app.buttons["Edit"].firstMatch.waitForExistenceAndTap()
        app.buttons["Remove card"].waitForExistenceAndTap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        // Verify we are kicked out to the main screen after removing all saved payment methods
        XCTAssertTrue(app.buttons["Card"].waitForExistence(timeout: 5.0))
        // Verify there's no more Saved section
        XCTAssertFalse(app.staticTexts["Saved"].waitForExistence(timeout: 0.1))
    }

    private func setupCards(cards: [String], settings: PaymentSheetTestPlaygroundSettings) {
        for cardNumber in cards {
            reload(app, settings: settings)
            app.buttons["Present PaymentSheet"].tap()
            let addCardButton = app.buttons["+ Add"]
            addCardButton.waitForExistenceAndTap()
            try! fillCardData(app, cardNumber: cardNumber)
            app.buttons["Set up"].tap()
            let successText = app.staticTexts["Success!"]
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

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.switches["Save this card for future Example, Inc. payments"].waitForExistenceAndTap()
        app.buttons["Pay $50.99"].waitForExistenceAndTap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["Pay $50.99"].waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Confirm your CVC"].waitForExistence(timeout: 1))
        // CVC field should already be selected
        app.typeText("123")
        app.buttons["Confirm"].tap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
}

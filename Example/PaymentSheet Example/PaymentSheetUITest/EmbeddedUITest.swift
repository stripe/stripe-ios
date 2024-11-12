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
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        // Entering a card w/ deferred PaymentIntent...
        app.buttons["Card"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Add card"].waitForExistence(timeout: 10))
        try! fillCardData(app, postalEnabled: true)
        app.toolbars.buttons["Done"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        
        // ...and *updating* to a SetupIntent...
        app.buttons.matching(identifier: "Setup").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        // ...should cause Card to no longer be the selected payment method.
        XCTAssertFalse(app.staticTexts["Payment method"].exists)
        
        // ....Tapping card should show the card form with details preserved
        app.buttons["Card"].waitForExistenceAndTap()
        // ...thus the Continue button should be enabled
        app.buttons["Continue"].waitForExistenceAndTap()
        // ...should cause the card ending in 4242 that was previously entered to be the selected payment method
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        // ...switching from setup to payment should preserve this card as the selected payment method
        app.buttons.matching(identifier: "Payment").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        // ...card entered for setup should be preserved after update
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        
        // ...selecting Alipay w/ deferred PaymentIntent...
        app.buttons["Alipay"].waitForExistenceAndTap()
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Alipay")
        // ...and *updating* to a SetupIntent...
        app.buttons.matching(identifier: "Setup").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        // ...should cause Alipay to no longer be the selected payment method, since it is not valid for setup.
        XCTAssertFalse(app.staticTexts["Payment method"].exists)
        
        // ...go back into deferred PaymentIntent mode
        app.buttons.matching(identifier: "Payment").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        //...selecting Cash App Pay w/ deferred PaymentIntent...
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Cash App Pay")
        // ...and *updating* to a SetupIntent...
        app.buttons.matching(identifier: "Setup").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        // ...should cause Cash App Pay to be the selected payment method, since it is valid for setup.
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Cash App Pay")
        
        // ...go back into deferred PaymentIntent mode
        app.buttons.matching(identifier: "Payment").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        //...selecting Klarna w/ deferred PaymentIntent...
        app.buttons["Klarna"].waitForExistenceAndTap()
        // ...fill out the form for Klarna
        let emailField = app.textFields["Email"]
        emailField.waitForExistenceAndTap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Klarna")
        // ...and *updating* to a SetupIntent...
        app.buttons.matching(identifier: "Setup").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        // ...should cause Klarna to no longer be the selected payment method.
        XCTAssertFalse(app.staticTexts["Payment method"].exists)
        // ...selecting Klarna should present a Klarna form with the previously entered email
        app.buttons["Klarna"].waitForExistenceAndTap()
        app.buttons["Continue"].waitForExistenceAndTap()
        // ...switching back to payment should keep Klarna selected
        app.buttons.matching(identifier: "Payment").element(boundBy: 1).waitForExistenceAndTap()
        // ...(wait for it to finish updating)...
        XCTAssertTrue(app.buttons["Reload"].waitForExistence(timeout: 10))
        // ... Klarna should still be selected
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Klarna")
        
        // Confirm the Klarna payment
        XCTAssertTrue(app.buttons["Checkout"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.buttons["Continue"].waitForExistenceAndTap()
        // Stop here; Klarna's test playground is out of scope
    }

    func testSingleCardCBC_update_and_remove_selectStateApplePay() {
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

        let card1001Button = app.buttons["•••• 1001"]

        // Ensure card preference is cartes bancaires
        XCTAssertTrue(card1001Button.waitForExistence(timeout: 3))
        XCTAssertTrue(card1001Button.isSelected)
        XCTAssertTrue(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_visa"].waitForExistence(timeout: 3))

        app.buttons["Edit"].waitForExistenceAndTap()
        app.otherElements["Card Brand Dropdown"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.swipeUp()
        app.buttons["Done"].waitForExistenceAndTap()
        app.buttons["Update"].waitForExistenceAndTap()
        XCTAssertFalse(app.staticTexts["Update card brand"].waitForExistence(timeout: 3))

        // Ensure card preference is switched to visa
        XCTAssertTrue(card1001Button.waitForExistence(timeout: 3))
        XCTAssertTrue(card1001Button.isSelected)
        XCTAssertTrue(app.images["stp_card_visa"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))

        // Ensure select state preserved on cancel (w/ saved card)
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["UIButton.Close"].waitForExistenceAndTap()
        XCTAssertTrue(card1001Button.waitForExistence(timeout: 3))
        XCTAssertTrue(card1001Button.isSelected)
        let applePayButton = app.buttons["Apple Pay"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 3))
        XCTAssertFalse(applePayButton.isSelected)

        // Ensure select state preserved on cancel (w/ Apple pay)
        applePayButton.tap()
        XCTAssertTrue(applePayButton.isSelected)
        XCTAssertFalse(card1001Button.isSelected)
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["UIButton.Close"].waitForExistenceAndTap()
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 3))
        XCTAssertTrue(applePayButton.isSelected)
        XCTAssertFalse(card1001Button.isSelected)

        // Remove last card while selected state is NOT on the card
        app.buttons["Edit"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Update card brand"].waitForExistence(timeout: 3.0))
        app.buttons["Remove card"].waitForExistenceAndTap()
        dismissAlertView(alertBody: "Visa •••• 1001", alertTitle: "Remove card?", buttonToTap: "Remove")

        // Apple pay should be continued to be selected
        XCTAssertFalse(app.staticTexts["Update card brand"].waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.images["stp_card_visa"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))
        XCTAssertTrue(applePayButton.isSelected)
        
        app.buttons["Checkout"].waitForExistenceAndTap()
        payWithApplePay()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }

    func testSingleCardCBC_onRemove_selectStateNone() {
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

        let card1001Button = app.buttons["•••• 1001"]

        // Ensure card preference is cartes bancaires
        XCTAssertTrue(card1001Button.waitForExistence(timeout: 3))
        XCTAssertTrue(card1001Button.isSelected)
        XCTAssertTrue(app.images["stp_card_cartes_bancaires"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["stp_card_visa"].waitForExistence(timeout: 3))

        // Remove last card while selected state is on the card
        app.buttons["Edit"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Update card brand"].waitForExistence(timeout: 3.0))
        app.buttons["Remove card"].waitForExistenceAndTap()
        dismissAlertView(alertBody: "Cartes Bancaires •••• 1001", alertTitle: "Remove card?", buttonToTap: "Remove")

        // Nothing should be selected
        let newCardButton = app.buttons["New card"]
        let applePayButton = app.buttons["Apple Pay"]
        XCTAssertTrue(newCardButton.waitForExistence(timeout: 3.0))
        XCTAssertFalse(newCardButton.isSelected)
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 3.0))
        XCTAssertFalse(applePayButton.isSelected)
    }

    func testMultipleCardWith_updateCBCWithinViewMore() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.integrationType = .deferred_csc
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
        
        // Finish confirming the payment
        app.buttons["Checkout"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }

    func testMultipleCard_remove_selectSavedCard() {
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

        let card4242Button = app.buttons["•••• 4242"]
        let bank6789Button = app.buttons["••••6789"]

        // Switch from 6789 (Bank account) to 4242
        app.buttons["View more"].waitForExistenceAndTap()
        card4242Button.waitForExistenceAndTap()

        XCTAssertFalse(bank6789Button.waitForExistence(timeout: 3.0))
        XCTAssertTrue(card4242Button.waitForExistence(timeout: 3.0))

        // Remove selected 4242 card
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        dismissAlertView(alertBody: "Visa •••• 4242", alertTitle: "Remove card?", buttonToTap: "Remove")
        app.buttons["Done"].waitForExistenceAndTap()

        // Since there is only one PM left, sheet dismisses automatically on tapping Done.
        XCTAssertTrue(bank6789Button.waitForExistence(timeout: 3.0))
        XCTAssertTrue(bank6789Button.isSelected)
        XCTAssertTrue(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].waitForExistence(timeout: 3.0))
        XCTAssertFalse(card4242Button.waitForExistence(timeout: 3.0))

        // Remove 6789 & verify
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        dismissAlertView(alertBody: "Bank account •••• 6789", alertTitle: "Remove bank account?", buttonToTap: "Remove")

        XCTAssertFalse(card4242Button.waitForExistence(timeout: 3.0))
        XCTAssertFalse(bank6789Button.waitForExistence(timeout: 3.0))
        XCTAssertFalse(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].waitForExistence(timeout: 3.0))
    }

    func testMultipleCard_remove_selectNonSavedCard() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .embedded
        settings.integrationType = .deferred_csc
        settings.customerKeyType = .legacy
        settings.customerMode = .returning
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        ensureSPMSelection("••••6789", insteadOf: "•••• 4242")

        let bank6789Button = app.buttons["••••6789"]
        let applePayButton = app.buttons["Apple Pay"]

        // Ensure card bankacct is selected, and apple pay is not.
        XCTAssertTrue(bank6789Button.waitForExistence(timeout: 3.0))
        XCTAssertTrue(bank6789Button.isSelected)
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 3.0))
        XCTAssertFalse(applePayButton.isSelected)

        // Ensure apple pay is still selected after tapping view more and dismissing
        app.buttons["Apple Pay"].tap()
        XCTAssertTrue(applePayButton.isSelected)
        XCTAssertFalse(bank6789Button.isSelected)
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["UIButton.Close"].waitForExistenceAndTap()

        // Ensure no state is changed
        XCTAssertTrue(applePayButton.isSelected)
        XCTAssertFalse(bank6789Button.isSelected)

        // Remove bankacct while it isn't selected
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        dismissAlertView(alertBody: "Bank account •••• 6789", alertTitle: "Remove bank account?", buttonToTap: "Remove")
        app.buttons["Done"].waitForExistenceAndTap()

        let card4242Button = app.buttons["•••• 4242"]
        XCTAssertFalse(bank6789Button.waitForExistence(timeout: 3.0))
        XCTAssertTrue(card4242Button.waitForExistence(timeout: 3.0))
        XCTAssertFalse(card4242Button.isSelected)
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 3.0))
        XCTAssertTrue(applePayButton.isSelected)

        // Remove 4242
        app.buttons["Edit"].waitForExistenceAndTap()
        app.buttons["CircularButton.Remove"].firstMatch.waitForExistenceAndTap()
        dismissAlertView(alertBody: "Visa •••• 4242", alertTitle: "Remove card?", buttonToTap: "Remove")

        XCTAssertFalse(card4242Button.waitForExistence(timeout: 3.0))
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 3.0))
        XCTAssertTrue(applePayButton.isSelected)
        
        app.buttons["Checkout"].waitForExistenceAndTap()
        payWithApplePay()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testSelection() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.customerKeyType = .legacy
        settings.formSheetAction = .continue
        settings.customerMode = .new
        loadPlayground(app, settings)
        
        // Start by saving a new card
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)

        // Complete payment
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
        
        // Switch to embedded mode kicks off a reload
        app.buttons["embedded"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Payment"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        // Should auto select a saved payment method
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        
        // Open card and cancel, should reset selection to saved card
        app.buttons["New card"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        
        // Select Cash App Pay
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Cash App Pay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Open card and cancel, should reset back to Cash App Pay
        app.buttons["New card"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Cash App Pay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Try to fill a card
        app.buttons["New card"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Add new card"].waitForExistence(timeout: 10))
        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.toolbars.buttons["Done"].waitForExistenceAndTap()
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4444")
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Tapping on card again should present the form filled out
        app.buttons["New card"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Add new card"].waitForExistence(timeout: 10))
        let cardNumberField = app.textFields["Card number"]
        XCTAssertEqual(cardNumberField.value as? String, "5555555555554444", "Card number field should contain the entered card number.")
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4444")
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)

        // Select and cancel out a form PM to ensure that the 4242 card is still selected
        app.buttons["Klarna"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4444")
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Select a no-form PM such as Cash App Pay
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Cash App Pay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Fill out US Bank Acct.
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
        app.buttons["Agree and continue"].waitForExistenceAndTap()
        app.staticTexts["Test Institution"].forceTapElement()
        // "Success" institution is automatically selected because its the first
        app.buttons["connect_accounts_button"].waitForExistenceAndTap(timeout: 10)

        let notNowButton = app.buttons["Not now"]
        if notNowButton.waitForExistence(timeout: 10) {
            app.typeText(XCUIKeyboardKey.return.rawValue) // dismiss keyboard
            notNowButton.tap()
        }

        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Add US bank account"].waitForExistence(timeout: 10))
        app.buttons["Continue"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "••••6789")
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        
        // Confirm with the saved card
        app.buttons["•••• 4242"].waitForExistenceAndTap()
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 20))
    }
    
    func testApplePay() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["Apple Pay"].waitForExistenceAndTap()
        app.buttons["Checkout"].waitForExistenceAndTap()
        payWithApplePay()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testLink() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["Link"].waitForExistenceAndTap()
        app.buttons["Checkout"].waitForExistenceAndTap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.buttons["Continue"].waitForExistenceAndTap()
        // Stop here; Links's test playground is out of scope
    }
    
    func testCVCRecollection() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .returning
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.requireCVCRecollection = .on
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        // Select the saved card
        app.buttons["View more"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Select payment method"].waitForExistence(timeout: 10))
        app.buttons["•••• 4242"].firstMatch.waitForExistenceAndTap()
        
        // Ensure the card is selected and start checking out
        XCTAssertEqual(app.staticTexts["Payment method"].label, "•••• 4242")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        // CVC field should already be selected
        app.typeText("123")
        app.buttons["Confirm"].waitForExistenceAndTap()
        
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testCashAppPay() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .returning
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        
        // Ensure Cash App Pay is selected and start checking out
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Cash App Pay")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testCashAppPayAndSetup() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .returning
        settings.mode = .paymentWithSetup
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        
        // Ensure Cash App Pay is selected and start checking out
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Cash App Pay")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testCashAppPaySetup() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .returning
        settings.mode = .setup
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        
        // Ensure Cash App Pay is selected and start checking out
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Cash App Pay")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        webviewAuthorizeSetupButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testCashAppPayBillingAddressCollection() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .returning
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.collectName = .always
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["Cash App Pay"].waitForExistenceAndTap()
        
        let fullNameField = app.textFields["Full name"]
        XCTAssertTrue(fullNameField.waitForExistence(timeout: 10))
        fullNameField.forceTapElement()
        fullNameField.typeText("Jane Doe")
        
        app.buttons["Continue"].tap()
        
        // Ensure Cash App Pay is selected and start checking out
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["Payment method"].label, "Cash App Pay")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testExternalPayPal() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.externalPaymentMethods = .paypal
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["PayPal"].waitForExistenceAndTap()
        
        // Ensure PayPal is selected and start checking out
        XCTAssertEqual(app.staticTexts["Payment method"].label, "PayPal")
        app.swipeUp() // scroll to see the checkout button
        XCTAssertTrue(app.buttons["Checkout"].isEnabled)
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        XCTAssertNotNil(app.staticTexts["Confirm external_paypal?"])
        app.buttons["Cancel"].waitForExistenceAndTap()
        
        app.buttons["Checkout"].waitForExistenceAndTap()
        let payButton = app.buttons["Confirm"]
        payButton.waitForExistenceAndTap()
        
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
    
    func testSEPA() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.currency = .eur
        settings.allowsDelayedPMs = .on
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .confirm
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        app.buttons["SEPA Debit"].waitForExistenceAndTap()
        
        app.textFields["Full name"].waitForExistenceAndTap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test@example.com" + XCUIKeyboardKey.return.rawValue)
        app.typeText("AT611904300234573201" + XCUIKeyboardKey.return.rawValue)
        app.textFields["Address line 1"].tap()
        app.typeText("510 Townsend St" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Floor 3" + XCUIKeyboardKey.return.rawValue)
        app.typeText("San Francisco" + XCUIKeyboardKey.return.rawValue)
        app.textFields["ZIP"].tap()
        app.typeText("94102" + XCUIKeyboardKey.return.rawValue)
        app.buttons["Pay €50.99"].tap()
        
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    
    func testUSBankAccount() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .returning
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .confirm
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        XCTAssertTrue(app.buttons["US bank account"].waitForExistenceAndTap())
        
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
        
        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()
        
        // Make sure bottom notice mandate is visible
        XCTAssertTrue(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].waitForExistence(timeout: 5))
        
        let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
        XCTAssertFalse(saveThisAccountToggle.isSelected)
        saveThisAccountToggle.tap()
        
        // Confirm
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }
    
    func test3DS2CardAlwaysAuthenticate() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.mode = .payment
        settings.integrationType = .deferred_csc
        settings.uiStyle = .embedded
        settings.formSheetAction = .continue
        settings.currency = .eur
        loadPlayground(app, settings)
        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        
        XCTAssertTrue(app.buttons["Card"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Add card"].waitForExistence(timeout: 10))
        
        // Card number from https://docs.stripe.com/testing#regulatory-cards
        try! fillCardData(app, cardNumber: "4000002760003184")
        app.toolbars.buttons["Done"].waitForExistenceAndTap()
        app.buttons["Continue"].waitForExistenceAndTap()
        app.swipeUp() // scroll to see the checkout button
        app.buttons["Checkout"].waitForExistenceAndTap()
        
        // Finish the 3DS2 payment
        let challengeCodeTextField = app.textFields["STDSTextField"]
        XCTAssertTrue(challengeCodeTextField.waitForExistenceAndTap(timeout: 10))
        challengeCodeTextField.typeText("424242" + XCUIKeyboardKey.return.rawValue)
        app.buttons["Submit"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
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

extension EmbeddedUITests {
    var webviewAuthorizePaymentButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT") }
    var webviewAuthorizeSetupButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST SETUP") }
}

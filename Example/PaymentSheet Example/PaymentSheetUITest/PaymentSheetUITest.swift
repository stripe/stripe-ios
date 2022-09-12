//
//  PaymentSheetUITest.swift
//  PaymentSheetUITest
//
//  Created by David Estes on 1/21/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheetUITest: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    func testPaymentSheetStandard() throws {
        app.staticTexts["PaymentSheet"].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()

        try! fillCardData(app)
        app.buttons["Pay €9.73"].tap()
        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testCardFormAmexCVV() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()
        
        let numberField = app.textFields["Card number"]
        numberField.tap()
        numberField.typeText("378282246310005")
        
        // Test that Amex card changes "CVC" -> "CVV" and allows 4 digits
        let cvvField = app.textFields["CVV"]
        XCTAssertTrue(cvvField.waitForExistence(timeout: 10.0))

        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        XCTAssertTrue((cvvField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvvField.typeText("1234"))
        
        app.toolbars.buttons["Done"].tap() // Country picker toolbar's "Done" button
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }

    func testPaymentSheetCustom() throws {
        app.staticTexts["PaymentSheet (Custom)"].tap()
        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"]

        let paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try! fillCardData(app)
        app.buttons["Continue"].tap()

        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testPaymentSheetCustomSaveAndRemoveCard() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "apple_pay": "off", // disable Apple Pay
            // This test case is testing a feature not available when Link is on,
            // so we must manually turn off Link.
            "automatic_payment_methods": "off",
            "link": "off"
        ])

        var paymentMethodButton = app.buttons["Select Payment Method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app)

        // toggle save this card on and off
        var saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        let expectDefaultSelectionOn = Locale.current.regionCode == "US"
        if expectDefaultSelectionOn {
            XCTAssertTrue(saveThisCardToggle.isSelected)
        } else {
            XCTAssertFalse(saveThisCardToggle.isSelected)
        }
        saveThisCardToggle.tap()
        if expectDefaultSelectionOn {
            XCTAssertFalse(saveThisCardToggle.isSelected)
        } else {
            XCTAssertTrue(saveThisCardToggle.isSelected)
            saveThisCardToggle.tap() // toggle back off

        }
        XCTAssertFalse(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Checkout (Custom)"].tap()
        var successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()

        // Reload w/ same customer
        reload(app)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app) // If the previous card was saved, we'll be on the 'saved pms' screen and this will fail
        // toggle save this card on
        saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        if !expectDefaultSelectionOn {
            saveThisCardToggle.tap()
        }
        XCTAssertTrue(saveThisCardToggle.isSelected)
        
        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Checkout (Custom)"].tap()
        successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()

        // Reload w/ same customer
        reload(app)

        // return to payment method selector
        paymentMethodButton = app.staticTexts["••••4242"] // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        let removeButton = app.buttons["Remove"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 60.0))
        removeButton.tap()

        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 60.0))
        confirmRemoval.tap()

        XCTAssertTrue(app.cells.count == 1)
    }

    func testPaymentSheetSwiftUI() throws {
        app.staticTexts["PaymentSheet (SwiftUI)"].tap()
        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        try! fillCardData(app)
        app.buttons["Pay €9.73"].tap()
        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Your order is confirmed!"))
    }

    func testPaymentSheetSwiftUICustom() throws {
        app.staticTexts["PaymentSheet (SwiftUI Custom)"].tap()
        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.forceTapElement()

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        try! fillCardData(app)
        app.buttons["Continue"].tap()

        // XCTest is too eager to tap the buy button: Wait until the sheet dismisses first.
        waitToDisappear(app.textFields["Card number"])

        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.forceTapElement()

        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Your order is confirmed!"))
    }
    
    func testIdealPaymentMethodHasTextFieldsAndDropdown() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "apple_pay": "off",
            "currency": "EUR"
        ])

        app.buttons["Checkout (Complete)"].tap()
        let payButton = app.buttons["Pay €50.99"]
        
        guard let iDEAL = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "iDEAL") else {
            XCTFail()
            return
        }
        iDEAL.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)
        
        let bank = app.textFields["iDEAL Bank"]
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "ASN Bank")
        app.toolbars.buttons["Done"].tap()

        payButton.tap()
        
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testEPSPaymentMethodHasTextFieldsAndDropdown() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "apple_pay": "off",
            "currency": "EUR"
        ])

        app.buttons["Checkout (Complete)"].tap()
        let payButton = app.buttons["Pay €50.99"]

        guard let eps = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "EPS") else {
            XCTFail()
            return
        }
        eps.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["EPS Bank"]
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "BKS Bank AG")
        app.toolbars.buttons["Done"].tap()

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testGiroPaymentMethodOnlyHasNameField() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "apple_pay": "off",
            "currency": "EUR"
        ])

        app.buttons["Checkout (Complete)"].tap()
        let payButton = app.buttons["Pay €50.99"]

        guard let giro = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "giropay") else {
            XCTFail()
            return
        }
        giro.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testP24PaymentMethodHasTextFieldsAndDropdown() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "apple_pay": "off",
            "currency": "EUR"
        ])

        app.buttons["Checkout (Complete)"].tap()

        let payButton = app.buttons["Pay €50.99"]
        guard let p24 = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Przelewy24") else {
            XCTFail()
            return
        }
        p24.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertFalse(payButton.isEnabled)
        let email = app.textFields["Email"]
        email.tap()
        email.typeText("test@test.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["Przelewy24 Bank"]
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "BNP Paribas")
        app.toolbars.buttons["Done"].tap()

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    // Klarna has a text field and country drop down
    func testKlarnaPaymentMethod() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new", // new customer
            "automatic_payment_methods": "off"
        ])

        app.buttons["Checkout (Complete)"].tap()
        let payButton = app.buttons["Pay $50.99"]
        
        // Select Klarna
        guard let klarna = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Klarna") else {
            XCTFail()
            return
        }
        klarna.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Email"]
        name.tap()
        name.typeText("foo@bar.com")
        name.typeText(XCUIKeyboardKey.return.rawValue)
        
        // Country should be pre-filled
        
        // Attempt payment
        payButton.tap()
        
        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testAffirmPaymentMethod() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new", // new customer
            "automatic_payment_methods": "off",
            "shipping_info": "provided" // enable shipping info
        ])

        app.buttons["Checkout (Complete)"].tap()
        let payButton = app.buttons["Pay $50.99"]

        
        // Select affirm
        guard let affirm = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Affirm") else {
            XCTFail()
            return
        }
        affirm.tap()

        XCTAssertTrue(payButton.isEnabled)
 
        // Attempt payment, should fail
        payButton.tap()
            
    }

    func testUSBankAccountPaymentMethod() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "automatic_payment_methods": "off",
            "allows_delayed_pms": "true"
        ])
        app.buttons["Checkout (Complete)"].tap()

        // Select US Bank Account
        guard let usBankAccount = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account") else {
            XCTFail()
            return
        }
        usBankAccount.tap()

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

        let expectDefaultSelectionOn = Locale.current.regionCode == "US"
        let selectedMandate = "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."
        let unselectedMandate = "By continuing, you agree to authorize payments pursuant to these terms."
        XCTAssertTrue(app.textViews[expectDefaultSelectionOn ? selectedMandate : unselectedMandate].waitForExistence(timeout: 5))



        let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
        saveThisAccountToggle.tap()
        XCTAssertTrue(app.textViews[expectDefaultSelectionOn ? unselectedMandate : selectedMandate].waitForExistence(timeout: 5))

        // no pay button tap because linked account is stubbed/fake in UI test
    }
}

// MARK: - Link

extension PaymentSheetUITest {

    // MARK: Inline signup

    /// Tests the Link inline signup flow.
    func testLinkInlineSignup() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "automatic_payment_methods": "off",
            "link": "on"
        ])

        app.buttons["Checkout (Complete)"].tap()

        try fillCardData(app)

        app.switches["Save my info for secure 1-click checkout"].tap()

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
        
        let phoneField = app.textFields["Phone"]
        // Phone field appears after the network call finishes. We want to wait for it to appear.
        XCTAssert(phoneField.waitForExistence(timeout: 10))
        phoneField.tap()
        phoneField.typeText("3105551234")

        // The name field is only required for non-US countries. Only fill it out if it exists.
        let nameField = app.textFields["Name"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Jane Done")
        }

        // Pay!
        app.buttons["Pay $50.99"].tap()

        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10))

        let okButton = app.alerts.buttons["OK"]
        okButton.tap()
    }

    func testLinkInlineSignIn() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "automatic_payment_methods": "off",
            "link": "on"
        ])

        app.buttons["Checkout (Complete)"].tap()

        try fillCardData(app)

        app.switches["Save my info for secure 1-click checkout"].tap()

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+a-consumer@stripe.com")

        // Pay!
        let payButton = app.buttons["Pay $50.99"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        app.buttons["Pay $50.99"].tap()

        // Wait for OTP prompt and enter the code
        let codeField = app.descendants(matching: .any)["Code field"]
        XCTAssert(codeField.waitForExistence(timeout: 10))
        codeField.tap()
        app.typeTextWithKeyboard("000000")

        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10))

        let okButton = app.alerts.buttons["OK"]
        okButton.tap()
    }

    // MARK: Modal

    func testLinkSignup() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "automatic_payment_methods": "off",
            "link": "on"
        ])

        app.buttons["Checkout (Complete)"].tap()

        let payWithLinkButton = app.buttons["Pay with Link"]
        XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
        payWithLinkButton.tap()

        let modal = app.otherElements["Stripe.Link.PayWithLinkViewController"]
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

        // Terms and privacy policy
        for linkText in ["Terms", "Privacy Policy"] {
            modal.links[linkText].tap()
            let closeTermsButton = app.otherElements["TopBrowserBar"].buttons["Close"]
            XCTAssert(closeTermsButton.waitForExistence(timeout: 10))
            closeTermsButton.tap()
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

        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10))

        let okButton = app.alerts.buttons["OK"]
        okButton.tap()

        // Reload to verify that the last signup email is remembered.
        reload(app)
        app.buttons["Checkout (Complete)"].tap()

        // Confirm that that verification prompt appears
        // and that we are able to verify the session.
        let codeField = app.descendants(matching: .any)["Code field"]
        XCTAssert(codeField.waitForExistence(timeout: 10))
        codeField.tap()
        app.typeTextWithKeyboard("000000")

        let modal2 = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        XCTAssertTrue(modal2.waitForExistence(timeout: 10))
    }

    func testLinkSignIn() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "automatic_payment_methods": "off",
            "link": "on"
        ])

        app.buttons["Checkout (Complete)"].tap()

        let payWithLinkButton = app.buttons["Pay with Link"]
        XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
        payWithLinkButton.tap()

        try loginAndPay()
    }

    // MARK: Custom Flow

    func testLinkCustomFlow() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "automatic_payment_methods": "off",
            "link": "on"
        ])

        let paymentMethodButton = app.buttons["Select Payment Method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
        paymentMethodButton.tap()

        let addCardButton = app.buttons["Link"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
        addCardButton.tap()

        app.buttons["Checkout (Custom)"].tap()

        try loginAndPay()
    }

    private func loginAndPay() throws {
        let modal = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        XCTAssertTrue(modal.waitForExistence(timeout: 10))

        let emailField = modal.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+a-consumer@stripe.com")

        // Wait for OTP screen and enter the code
        let codeField = app.descendants(matching: .any)["Code field"]
        XCTAssert(codeField.waitForExistence(timeout: 10))
        codeField.tap()
        app.typeTextWithKeyboard("000000")

        let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
        if paymentMethodPicker.waitForExistence(timeout: 10) {
            paymentMethodPicker.tap()
            paymentMethodPicker.buttons["Add a payment method"].tap()
        }

        try fillCardData(app, container: modal)

        // Pay!
        let payButton = modal.buttons["Pay $50.99"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        payButton.tap()

        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10))

        let okButton = app.alerts.buttons["OK"]
        okButton.tap()
    }
}

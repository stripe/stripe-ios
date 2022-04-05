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
        app /*@START_MENU_TOKEN@*/.staticTexts[
            "PaymentSheet"
        ] /*[[".buttons[\"PaymentSheet\"].staticTexts[\"PaymentSheet\"]",".staticTexts[\"PaymentSheet\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
            .tap()
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
    
    func testCardFieldAutoAdvance() throws {
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
        numberField.typeText("4242424242424242")
        
        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        let cvcField = app.textFields["CVC"]
        XCTAssertTrue((cvcField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvcField.typeText("123"))
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }
    
    func testCardFieldAutoAdvanceAutoTypeToPostalCode() throws {
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
        numberField.typeText("4242424242424242")
        
        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        let cvcField = app.textFields["CVC"]
        XCTAssertTrue((cvcField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvcField.typeText("1234"))
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String) ?? "" == "4")
    }
    
    func testCardFieldAutoAdvanceAmexCVV() throws {
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
        
        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        let cvvField = app.textFields["CVV"]
        XCTAssertTrue((cvvField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvvField.typeText("1234"))
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }

    func testPaymentSheetCustom() throws {
        app.staticTexts["PaymentSheet (Custom)"].tap()
        let paymentMethodButton = app.staticTexts["Apple Pay"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
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
            "automatic_payment_methods": "on" // enable automatic payment
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
        var successText = app.alerts.staticTexts["success!"]
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
        successText = app.alerts.staticTexts["success!"]
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
    
    // iDEAL has some text fields and a dropdown
    func testIdealPaymentMethod() throws {
        loadPlayground(app, settings: [
            "customer_mode": "new",
            "apple_pay": "off", // disable Apple Pay
            "currency": "EUR" // EUR currency
        ])

        app.buttons["Checkout (Complete)"].tap()
        let payButton = app.buttons["Pay €50.99"]
        
        // Select iDEAL
        guard let iDEAL = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "iDEAL") else {
            XCTFail()
            return
        }
        iDEAL.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)
        
        let bank = app.textFields["iDEAL Bank"]
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "ASN Bank")
        app.toolbars.buttons["Done"].tap()

        // Attempt payment
        payButton.tap()
        
        // Close the webview, no need to see the successful pay
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
}

// MARK: - Link

extension PaymentSheetUITest {

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

        let phoneField = app.otherElements["Mobile number"]
        // Phone field appears after the network call finishes. We want to wait for it to appear.
        XCTAssert(phoneField.waitForExistence(timeout: 10))
        phoneField.tap()

        // XCUIApplication cannot synthesize typing events to the phone field.
        // So we need to punch-in each digit via the keyboard.
        "3105551234".forEach { digit in
            app.keys[String(digit)].tap()
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
        let codeField = app.otherElements["Code field"]
        XCTAssert(codeField.waitForExistence(timeout: 10))
        codeField.tap()

        "000000".forEach { digit in
            app.keys[String(digit)].tap()
        }

        let successText = app.alerts.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10))

        let okButton = app.alerts.buttons["OK"]
        okButton.tap()
    }

}

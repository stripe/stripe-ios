//
//  PaymentSheetUITestCase.swift
//  PaymentSheetUITest
//
//  Created by David Estes on 1/21/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheetUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = [
            "UITesting": "true",
            // This makes the Financial Connections SDK trigger the (testmode) production flow instead of a stub. See FinancialConnectionsSDKAvailability.isUnitTestOrUITest.
            "USE_PRODUCTION_FINANCIAL_CONNECTIONS_SDK": "true",
        ]
    }
}

// XCTest runs classes in parallel, not individual tests. Split the tests into separate classes to keep build times at a reasonable level.
class PaymentSheetStandardUITests: PaymentSheetUITestCase {
    func testPaymentSheetStandard() throws {
        app.launch()
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
        XCTAssertTrue(numberField.waitForExistence(timeout: 60.0))
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

        app.toolbars.buttons["Done"].tap()  // Country picker toolbar's "Done" button

        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }

    func testPaymentSheetCustom() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController"].tap()
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

    func testPaymentSheetCustomDeferred_update() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController (Deferred)"].tap()

        // Update product quantities and enable subscription
        let subscribeSwitch = app.switches["subscribe_switch"]

        let subscribeSwitchEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: subscribeSwitch
        )
        wait(for: [subscribeSwitchEnabledExpectation], timeout: 60, enforceOrder: true)

        app.switches["subscribe_switch"].tap()
        app.steppers["hotdog_stepper"].tap()
        app.steppers["hotdog_stepper"].tap()
        app.steppers["salad_stepper"].tap()

        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"]

        var paymentMethodButtonEnabledExpectation = expectation(
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

        // Update quantity of an item to force an update
        let saladStepper = app.steppers["salad_stepper"]
        XCTAssertTrue(saladStepper.waitForExistence(timeout: 4.0))
        saladStepper.tap()

        paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        // Continue should be enabled since card details were preserved when closing payment sheet
        XCTAssertTrue(app.buttons["Continue"].waitForExistenceAndTap(timeout: 4.0))

        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testPaymentSheetCustomSaveAndRemoveCard() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        // This test case is testing a feature not available when Link is on,
        // so we must manually turn off Link.
        settings.apmsEnabled = .off
        settings.linkEnabled = .off
        loadPlayground(
            app,
            settings
        )

        var paymentMethodButton = app.buttons["Payment method"]
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
            saveThisCardToggle.tap()  // toggle back off

        }
        XCTAssertFalse(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        var successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app)  // If the previous card was saved, we'll be on the 'saved pms' screen and this will fail
        // toggle save this card on
        saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        if !expectDefaultSelectionOn {
            saveThisCardToggle.tap()
        }
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        // return to payment method selector
        paymentMethodButton = app.staticTexts["••••4242"]  // The card should be saved now
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
        app.launch()

        app.staticTexts["PaymentSheet (SwiftUI)"].tap()
        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        try! fillCardData(app)
        app.buttons["Pay €9.73"].tap()
        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Success!"))
    }

    func testPaymentSheetSwiftUICustom() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController (SwiftUI)"].tap()
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
        XCTAssertNotNil(successText.label.range(of: "Success!"))
    }

    func testIdealPaymentMethodHasTextFieldsAndDropdown() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
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
}

class PaymentSheetStandardLPMUITests: PaymentSheetUITestCase {
    func testEPSPaymentMethodHasTextFieldsAndDropdown() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
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
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
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
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()

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
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
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
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )
        app.buttons["Present PaymentSheet"].tap()
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

    func testZipPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .aud
        settings.merchantCountryCode = .AU
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay A$50.99"]

        // Select Cash App
        guard let zip = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Zip")
        else {
            XCTFail()
            return
        }
        zip.tap()

        // Attempt payment
        payButton.tap()

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testCashAppPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .on
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay $50.99"]

        // Select Cash App
        guard let cashApp = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Cash App Pay")
        else {
            XCTFail()
            return
        }
        cashApp.tap()

        // Attempt payment
        payButton.tap()

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testUSBankAccountPaymentMethod() throws {
        app.launchEnvironment = app.launchEnvironment.merging(["USE_PRODUCTION_FINANCIAL_CONNECTIONS_SDK": "false"]) { (_, new) in new }
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(
            app,
            settings
        )
        app.buttons["Present PaymentSheet"].tap()

        // Select US Bank Account
        guard
            let usBankAccount = scroll(
                collectionView: app.collectionViews.firstMatch,
                toFindCellWithId: "US Bank Account"
            )
        else {
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
        let selectedMandate =
        "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."
        let unselectedMandate = "By continuing, you agree to authorize payments pursuant to these terms."
        XCTAssertTrue(
            app.textViews[expectDefaultSelectionOn ? selectedMandate : unselectedMandate].waitForExistence(timeout: 5)
        )

        let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
        saveThisAccountToggle.tap()
        XCTAssertTrue(
            app.textViews[expectDefaultSelectionOn ? unselectedMandate : selectedMandate].waitForExistence(timeout: 5)
        )

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testPaymentIntent_USBankAccount() {
        _testUSBankAccount(mode: .payment, integrationType: .normal)
    }

    func testSetupIntent_USBankAccount() {
        _testUSBankAccount(mode: .setup, integrationType: .normal)
    }

    func testUPIPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .IN
        settings.currency = .inr
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()
    }

    func testUPIPaymentMethod_invalidVPA() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .IN
        settings.currency = .inr
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertFalse(payButton.isEnabled)
    }

    // This only tests the PaymentSheet + PaymentIntent flow.
    // Other confirmation flows are tested in PaymentSheet+LPMTests.swift
    func testSEPADebitPaymentMethod_PaymentSheet() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.currency = .eur
        settings.allowsDelayedPMs = .on
        loadPlayground(
            app,
            settings
        )
        app.buttons["Present PaymentSheet"].tap()

        guard let sepa = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "SEPA Debit") else { XCTFail("Couldn't find SEPA"); return; }
        sepa.tap()

        app.textFields["Full name"].tap()
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
}

class PaymentSheetDeferredUITests: PaymentSheetUITestCase {

    // MARK: Deferred tests (client-side)

    func testDeferredPaymentIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_ClientSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].tap()

        let declineText = app.staticTexts["Your card was declined."]
        XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        settings.uiStyle = .flowController
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        settings.uiStyle = .flowController
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    /* Disable Link test
     func testDeferferedIntentLinkSignup_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
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
     
     let successText = app.staticTexts["Success!"]
     XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredIntent_ApplePayCustomFlow_ClientSideConfirmation() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.uiStyle = .flowController
        settings.apmsEnabled = .off
        settings.linkEnabled = .on
        loadPlayground(
            app,
            settings
        )

        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
        paymentMethodButton.tap()

        let applePay = app.collectionViews.buttons["Apple Pay"]
        XCTAssertTrue(applePay.waitForExistence(timeout: 10.0))
        applePay.tap()

        app.buttons["Confirm"].tap()

        payWithApplePay()
    }
}

class PaymentSheetDeferredUIBankAccountTests: PaymentSheetUITestCase {
    func testDeferredIntentPaymentIntent_USBankAccount_ClientSideConfirmation() {
        _testUSBankAccount(mode: .payment, integrationType: .deferred_csc)
    }

    func testDeferredIntentPaymentIntent_USBankAccount_ServerSideConfirmation() {
        _testUSBankAccount(mode: .payment, integrationType: .deferred_ssc)
    }

    func testDeferredIntentSetupIntent_USBankAccount_ClientSideConfirmation() {
        _testUSBankAccount(mode: .setup, integrationType: .deferred_csc)
    }

    func testDeferredIntentSetupIntent_USBankAccount_ServerSideConfirmation() {
        _testUSBankAccount(mode: .setup, integrationType: .deferred_ssc)
    }

    /* Disable Link test
     func testDeferredIntentLinkSignIn_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try loginAndPay()
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkSignIn_ClientSideConfirmation_LostCardDecline() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistence(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let failedText = modal.staticTexts["The payment failed."]
     XCTAssertTrue(failedText.waitForExistence(timeout: 10))
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkCustomFlow_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     let paymentMethodButton = app.buttons["Select Payment Method"]
     XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"]
     XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].tap()
     
     try loginAndPay()
     }
     */
}

class PaymentSheetDeferredServerSideUITests: PaymentSheetUITestCase {
    // MARK: Deferred tests (server-side)

    func testDeferredPaymentIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_ServerSideConfirmation_Multiprocessor() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_SeverSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].tap()

        let declineText = app.staticTexts["Your card was declined."]
        XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation_ManualConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_mc
        settings.uiStyle = .flowController
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    /* Disable link test
     func testDeferferedIntentLinkSignup_ServerSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
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
     
     let successText = app.staticTexts["Success!"]
     XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation_ManualConfirmation() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_mc
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation_Multiprocessor() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testPaymentSheetCustomSaveAndRemoveCard_DeferredIntent_ServerSideConfirmation() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        settings.apmsEnabled = .off
        // This test case is testing a feature not available when Link is on,
        // so we must manually turn off Link.
        settings.linkEnabled = .off
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController

        loadPlayground(
            app,
            settings
        )

        var paymentMethodButton = app.buttons["Payment method"]
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
            saveThisCardToggle.tap()  // toggle back off
        }
        XCTAssertFalse(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        var successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app)  // If the previous card was saved, we'll be on the 'saved pms' screen and this will fail
        // toggle save this card on
        saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        if !expectDefaultSelectionOn {
            saveThisCardToggle.tap()
        }
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        // return to payment method selector
        paymentMethodButton = app.staticTexts["••••4242"]  // The card should be saved now
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
    /* Disable Link test
     func testDeferredIntentLinkSignIn_SeverSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try loginAndPay()
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkSignIn_ServerSideConfirmation_LostCardDecline() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistence(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let declineText = app.staticTexts["Your card was declined."]
     XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkCustomFlow_SeverSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     let paymentMethodButton = app.buttons["Select Payment Method"]
     XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"]
     XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].tap()
     
     try loginAndPay()
     }
     */
}

// MARK: - Link
/* Disable link tests
 extension PaymentSheetUITest {
 // MARK: Inline signup
 /// Tests the Link inline signup flow.
 func testLinkInlineSignup() throws {
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 ]
 )
 
 app.buttons["Present PaymentSheet"].tap()
 
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
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 ]
 )
 
 app.buttons["Present PaymentSheet"].tap()
 
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
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 ]
 )
 
 app.buttons["Present PaymentSheet"].tap()
 
 let payWithLinkButton = app.buttons["Pay with Link"]
 XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
 payWithLinkButton.tap()
 
 let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
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
 app.buttons["Present PaymentSheet"].tap()
 
 // Confirm that that verification prompt appears
 // and that we are able to verify the session.
 let codeField = app.descendants(matching: .any)["Code field"]
 XCTAssert(codeField.waitForExistence(timeout: 10))
 codeField.tap()
 app.typeTextWithKeyboard("000000")
 
 let modal2 = app.otherElements["Stripe.Link.PayWithLinkWebController"]
 XCTAssertTrue(modal2.waitForExistence(timeout: 10))
 }
 
 func testLinkSignIn() throws {
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 ]
 )
 
 app.buttons["Present PaymentSheet"].tap()
 
 let payWithLinkButton = app.buttons["Pay with Link"]
 XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
 payWithLinkButton.tap()
 
 try loginAndPay()
 }
 
 // MARK: Custom Flow
 
 func testLinkCustomFlow() throws {
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 ]
 )
 
 let paymentMethodButton = app.buttons["Select Payment Method"]
 XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
 paymentMethodButton.tap()
 
 let addCardButton = app.buttons["Link"]
 XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
 addCardButton.tap()
 
 app.buttons["Confirm"].tap()
 
 try loginAndPay()
 }
 
 func testLinkAddCard_CollectingBillingDetails() throws {
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 "collect_name": "always",
 "collect_email": "always",
 "collect_phone": "always",
 "collect_address": "full",
 ]
 )
 
 let paymentMethodButton = app.buttons["Select Payment Method"]
 XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
 paymentMethodButton.tap()
 
 let addCardButton = app.buttons["Link"]
 XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
 addCardButton.tap()
 
 app.buttons["Confirm"].tap()
 
 try linkLogin()
 
 let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
 let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
 if paymentMethodPicker.waitForExistence(timeout: 10) {
 paymentMethodPicker.tap()
 paymentMethodPicker.buttons["Add a payment method"].tap()
 }
 
 XCTAssertTrue(modal.staticTexts["Card information"].waitForExistence(timeout: 10.0))
 XCTAssertTrue(modal.staticTexts["Contact information"].exists)
 XCTAssertTrue(modal.textFields["Email"].exists)
 // Phone cannot be collected by Link.
 XCTAssertFalse(modal.textFields["Phone"].exists)
 XCTAssertTrue(modal.textFields["Name on card"].exists)
 XCTAssertTrue(modal.staticTexts["Billing address"].exists)
 XCTAssertTrue(modal.textFields["Country or region"].exists)
 XCTAssertTrue(modal.textFields["Address line 1"].exists)
 XCTAssertTrue(modal.textFields["Address line 2"].exists)
 XCTAssertTrue(modal.textFields["City"].exists)
 XCTAssertTrue(modal.textFields["State"].exists)
 XCTAssertTrue(modal.textFields["ZIP"].exists)
 
 modal.textFields["Email"].forceTapWhenHittableInTestCase(self)
 modal.typeText("foo@bar.com")
 modal.textFields["Name on card"].tap()
 modal.typeText("Jane Doe")
 modal.textFields["Card number"].tap()
 modal.typeText("4242424242424242")
 modal.typeText("1228") // Expiry
 modal.typeText("123") // CVC
 modal.textFields["Address line 1"].tap()
 modal.typeText("510 Townsend St.")
 modal.textFields["City"].tap()
 modal.typeText("San Francisco")
 modal.textFields["State"].tap()
 app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
 app.toolbars.buttons["Done"].tap()
 modal.textFields["ZIP"].tap()
 modal.typeText("94102")
 app.toolbars.buttons["Done"].tap()
 
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
 
 func testLinkEditCard_CollectingBillingDetails() throws {
 loadPlayground(
 app,
 settings: [
 "customer_mode": "new",
 "automatic_payment_methods": "off",
 "link": "on",
 "collect_name": "always",
 "collect_email": "always",
 "collect_phone": "always",
 "collect_address": "full",
 ]
 )
 
 let paymentMethodButton = app.buttons["Select Payment Method"]
 XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
 paymentMethodButton.tap()
 
 let addCardButton = app.buttons["Link"]
 XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
 addCardButton.tap()
 
 app.buttons["Confirm"].tap()
 
 try linkLogin()
 
 let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
 let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
 paymentMethodPicker.waitForExistenceAndTap(timeout: 10.0)
 paymentMethodPicker.otherElements["Stripe.Link.PaymentMethodPickerCell"].firstMatch.press(forDuration: 2.0)
 app.buttons["Update card"].tap()
 
 XCTAssertTrue(modal.staticTexts["Card information"].waitForExistence(timeout: 10.0))
 XCTAssertTrue(modal.staticTexts["Contact information"].exists)
 XCTAssertTrue(modal.textFields["Email"].exists)
 // Phone cannot be collected by Link.
 XCTAssertFalse(modal.textFields["Phone"].exists)
 XCTAssertTrue(modal.textFields["Name on card"].exists)
 XCTAssertTrue(modal.staticTexts["Billing Address"].exists)
 XCTAssertTrue(modal.textFields["Country or region"].exists)
 XCTAssertTrue(modal.textFields["Address line 1"].exists)
 XCTAssertTrue(modal.textFields["Address line 2"].exists)
 XCTAssertTrue(modal.textFields["City"].exists)
 XCTAssertTrue(modal.textFields["State"].exists)
 XCTAssertTrue(modal.textFields["ZIP"].exists)
 
 modal.textFields["Email"].forceTapWhenHittableInTestCase(self)
 modal.typeText("foo@bar.com")
 modal.textFields["Name on card"].tap()
 modal.typeText("Jane Doe")
 modal.textFields["CVC"].tap()
 modal.typeText("123") // CVC
 modal.textFields["Address line 1"].tap()
 modal.typeText("510 Townsend St.")
 modal.textFields["City"].tap()
 modal.typeText("San Francisco")
 modal.textFields["State"].tap()
 app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
 app.toolbars.buttons["Done"].tap()
 modal.textFields["ZIP"].tap()
 modal.typeText("94102")
 app.toolbars.buttons["Done"].tap()
 
 // Save.
 let saveButton = modal.buttons["Update card"]
 expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: saveButton, handler: nil)
 waitForExpectations(timeout: 10, handler: nil)
 saveButton.tap()
 
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
 
 private func linkLogin() throws {
 let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
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
 }
 
 private func loginAndPay() throws {
 try linkLogin()
 
 let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
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
 */

// MARK: Helpers
extension PaymentSheetUITestCase {
    func _testUSBankAccount(mode: PaymentSheetTestPlaygroundSettings.Mode, integrationType: PaymentSheetTestPlaygroundSettings.IntegrationType) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        settings.mode = mode
        settings.integrationType = integrationType

        loadPlayground(
            app,
            settings
        )
        app.buttons["Present PaymentSheet"].tap()

        // Select US Bank Account
        guard let usBankAccount = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account") else {
            XCTFail()
            return
        }
        usBankAccount.tap()

        // Fill out name and email fields
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Full name"].tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test@example.com" + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].tap()
        app.staticTexts["Test Institution"].forceTapElement()
        app.staticTexts["Success"].waitForExistenceAndTap(timeout: 10)
        app.buttons["Link account"].tap()
        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        // Confirm
        let confirmButtonText = mode == .payment ? "Pay $50.99" : "Set up"
        app.buttons[confirmButtonText].waitForExistenceAndTap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload and pay with the now-saved us bank account
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].tap()
        XCTAssertTrue(app.buttons["••••6789"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons[confirmButtonText].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }

    func payWithApplePay() {
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)

        let predicate = NSPredicate(format: "label CONTAINS 'Simulated Card - AmEx, ‪•••• 1234‬'")

        let cardButton = applePay.buttons.containing(predicate).firstMatch
        XCTAssertTrue(cardButton.waitForExistence(timeout: 10.0))
        cardButton.forceTapElement()

        addApplePayBillingIfNeeded(applePay)

        let cardSelectionButton = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].firstMatch
        XCTAssertTrue(cardSelectionButton.waitForExistence(timeout: 10.0))
        cardSelectionButton.forceTapElement()

        let payButton = applePay.buttons["Pay with Passcode"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 10.0))
        payButton.forceTapElement()

        let successText = app.staticTexts["Success!"]
        //      This actually takes upwards of 20 seconds sometimes, especially in the deferred flow :/
        XCTAssertTrue(successText.waitForExistence(timeout: 30.0))
    }

    func addApplePayBillingIfNeeded(_ applePay: XCUIApplication) {
        // Fill out billing details if required
        let addBillingDetailsButton = applePay.buttons["Add Billing Address"]
        if addBillingDetailsButton.waitForExistence(timeout: 4.0) {
            addBillingDetailsButton.tap()

            let firstNameCell = applePay.textFields["First Name"]
            firstNameCell.tap()
            firstNameCell.typeText("Jane")

            let lastNameCell = applePay.textFields["Last Name"]
            lastNameCell.tap()
            lastNameCell.typeText("Doe")

            let streetCell = applePay.textFields["Street"]
            streetCell.tap()
            streetCell.typeText("One Apple Park Way")

            let cityCell = applePay.textFields["City"]
            cityCell.tap()
            cityCell.typeText("Cupertino")

            let stateCell = applePay.textFields["State"]
            stateCell.tap()
            stateCell.typeText("CA")

            let zipCell = applePay.textFields["ZIP"]
            zipCell.tap()
            zipCell.typeText("95014")

            applePay.buttons["Done"].tap()
        }
    }
}

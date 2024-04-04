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

    /// This element's `label` contains all the analytic events sent by the SDK since the the playground was loaded, as a base-64 encoded string.
    /// - Note: Only exists in test playground.
    lazy var analyticsLogElement: XCUIElement = { app.staticTexts["_testAnalyticsLog"].firstMatch }()
    /// Convenience var to grab all the events sent since the playground was loaded.
    var analyticsLog: [[String: Any]] {
        let logRawString = analyticsLogElement.label
        guard
            let data = Data(base64Encoded: logRawString),
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        return json
    }

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
        app.staticTexts["PaymentSheet"].firstMatch.tap()
        let buyButton = app.staticTexts["Buy"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 60.0))
        buyButton.tap()

        try! fillCardData(app)
        app.buttons["Pay €9.73"].firstMatch.tap()
        let successText = app.alerts.staticTexts["Your order is confirmed!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"].firstMatch
        okButton.tap()
    }

    func testCardFormAmexCVV() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 60.0))
        buyButton.tap()

        let numberField = app.textFields["Card number"].firstMatch
        XCTAssertTrue(numberField.waitForExistenceIfNeeded(timeout: 60.0))
        numberField.tap()
        numberField.typeText("378282246310005")

        // Test that Amex card changes "CVC" -> "CVV" and allows 4 digits
        let cvvField = app.textFields["CVV"].firstMatch
        XCTAssertTrue(cvvField.waitForExistenceIfNeeded(timeout: 10.0))

        let expField = app.textFields["expiration date"].firstMatch
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))

        XCTAssertTrue((cvvField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvvField.typeText("1234"))

        app.toolbars.buttons["Done"].firstMatch.tap()  // Country picker toolbar's "Done" button

        let postalField = app.textFields["ZIP"].firstMatch
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }

    func testPaymentSheetCustom() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController"].firstMatch.tap()
        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"].firstMatch

        let paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()

        try! fillCardData(app)
        app.buttons["Continue"].firstMatch.tap()

        let buyButton = app.staticTexts["Buy"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"].firstMatch
        okButton.tap()
    }

    func testPaymentSheetCustomDeferred_update() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController (Deferred)"].firstMatch.tap()

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

        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"].firstMatch

        var paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()

        try! fillCardData(app)

        app.buttons["Continue"].firstMatch.tap()

        // Update quantity of an item to force an update
        let saladStepper = app.steppers["salad_stepper"]
        XCTAssertTrue(saladStepper.waitForExistenceIfNeeded(timeout: 4.0))
        saladStepper.tap()

        paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        // Continue should be enabled since card details were preserved when closing payment sheet
        XCTAssertTrue(app.buttons["Continue"].firstMatch.waitForExistenceAndTap(timeout: 4.0))

        let buyButton = app.staticTexts["Buy"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"].firstMatch
        okButton.tap()
    }

    func testPaymentSheetCustomSaveAndRemoveCard() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        loadPlayground(
            app,
            settings
        )

        app.buttons["Apple Pay, apple_pay"].firstMatch.waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        XCTAssertEqual(
            analyticsLog.map({ $0[string: "event"] }),
            ["mc_load_started", "link.account_lookup.complete", "mc_load_succeeded", "mc_custom_init_customer_applepay", "mc_custom_sheet_savedpm_show"]
        )
        // `mc_load_succeeded` event `selected_lpm` should be "apple_pay", the default payment method.
        XCTAssertEqual(analyticsLog[2][string: "selected_lpm"], "apple_pay")
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        // Should fire the `mc_form_shown` event w/ `selected_lpm` = card
        XCTAssertEqual(analyticsLog.last?[string: "event"], "mc_form_shown")
        XCTAssertEqual(analyticsLog.last?[string: "selected_lpm"], "card")

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
        app.buttons["Continue"].firstMatch.tap()

        // Check analytics
        XCTAssertEqual(
            analyticsLog.suffix(3).map({ $0[string: "event"] }),
            ["mc_form_interacted", "mc_card_number_completed", "mc_confirm_button_tapped"]
        )

        app.buttons["Confirm"].firstMatch.tap()
        var successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        XCTAssertEqual(analyticsLog.last?[string: "event"], "mc_custom_payment_newpm_success")
        XCTAssertEqual(analyticsLog.last?[string: "selected_lpm"], "card")
        // Make sure they all have the same session id
        let sessionID = analyticsLog.first![string: "session_id"]
        XCTAssertTrue(!sessionID!.isEmpty)
        for analytic in analyticsLog {
            if analytic[string: "event"] == "stripeios.payment_intent_confirmation" {
                continue
            }
            XCTAssertEqual(analytic[string: "session_id"], sessionID)
        }
        // Make sure the appropriate events have "selected_lpm" = "card"
        for analytic in analyticsLog {
            if ["mc_form_shown", "mc_form_interacted", "mc_confirm_button_tapped", "mc_custom_payment_newpm_success"].contains(analytic[string: "event"]) {
               XCTAssertEqual(analytic[string: "selected_lpm"], "card")
            }
        }

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Apple Pay, apple_pay"].firstMatch.waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        XCTAssertNotEqual(analyticsLog.first?[string: "session_id"], sessionID) // Sanity check this has a different session ID than before
        XCTAssertEqual(app.cells.count, 3) // Should be "Add" and "Apple Pay" and "Link"
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)
        // toggle save this card on
        saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        if !expectDefaultSelectionOn {
            saveThisCardToggle.tap()
        }
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        // return to payment method selector
        app.staticTexts["••••4242"].firstMatch.waitForExistenceAndTap(timeout: 30)  // The card should be saved now and selected as default instead of Apple Pay
        XCTAssertEqual(app.cells.count, 4) // Should be "Add", "Apple Pay", "Link", and saved card

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: 60.0))
        editButton.tap()

        let removeButton = app.buttons["Remove"].firstMatch
        XCTAssertTrue(removeButton.waitForExistenceIfNeeded(timeout: 60.0))
        removeButton.tap()

        let confirmRemoval = app.alerts.buttons["Remove"].firstMatch
        XCTAssertTrue(confirmRemoval.waitForExistenceIfNeeded(timeout: 60.0))
        confirmRemoval.tap()

        XCTAssertEqual(app.cells.count, 3) // Should be "Add", "Apple Pay", "Link"
    }

    func testPaymentSheetSwiftUI() throws {
        app.launch()

        app.staticTexts["PaymentSheet (SwiftUI)"].firstMatch.tap()
        let buyButton = app.buttons["Buy button"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 60.0))
        buyButton.forceTapElement()

        try! fillCardData(app)
        app.buttons["Pay €9.73"].firstMatch.tap()
        let successText = app.staticTexts["Payment status view"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Success!"))
    }

    func testPaymentSheetSwiftUICustom() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController (SwiftUI)"].firstMatch.tap()
        let paymentMethodButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 60.0))
        paymentMethodButton.forceTapElement()

        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()
        try! fillCardData(app)
        app.buttons["Continue"].firstMatch.tap()

        // XCTest is too eager to tap the buy button: Wait until the sheet dismisses first.
        waitToDisappear(app.textFields["Card number"].firstMatch)

        let buyButton = app.buttons["Buy button"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 4.0))
        buyButton.forceTapElement()

        let successText = app.staticTexts["Payment status view"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay €50.99"].firstMatch

        guard let iDEAL = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "iDEAL") else {
            XCTFail()
            return
        }
        iDEAL.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"].firstMatch
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["iDEAL Bank"].firstMatch
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "ASN Bank")
        app.toolbars.buttons["Done"].firstMatch.tap()

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testUPIPaymentMethodPolling() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
                settings.merchantCountryCode = .IN
        settings.currency = .inr
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        let payButton = app.buttons["Pay ₹50.99"].firstMatch
        XCTAssertTrue(payButton.waitForExistenceIfNeeded(timeout: 10))
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"].firstMatch
        upi_id.tap()
        upi_id.typeText("payment.pending@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()

        let approvePaymentText = app.staticTexts["Approve payment"].firstMatch
        XCTAssertTrue(approvePaymentText.waitForExistenceIfNeeded(timeout: 10.0))

        // UPI Specific CTA
        let predicate = NSPredicate(format: "label BEGINSWITH 'Open your UPI app to approve your payment within'")
        let upiCTAText = XCUIApplication().staticTexts.element(matching: predicate)
        XCTAssertTrue(upiCTAText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testBLIKPaymentMethodPolling() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
                settings.merchantCountryCode = .FR
        settings.currency = .pln
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        let payButton = app.buttons["Pay PLN 50.99"].firstMatch
        guard let blik = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "BLIK") else {
            XCTFail()
            return
        }
        blik.tap()

        XCTAssertFalse(payButton.isEnabled)
        let blik_code = app.textFields["BLIK code"].firstMatch
        blik_code.tap()
        blik_code.typeText("123456")
        blik_code.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()

        let approvePaymentText = app.staticTexts["Approve payment"].firstMatch
        XCTAssertTrue(approvePaymentText.waitForExistenceIfNeeded(timeout: 15.0))

        // BLIK Specific CTA
        let predicate = NSPredicate(format: "label BEGINSWITH 'Confirm the payment in your bank\\'s app within'")
        let blikCTAText = XCUIApplication().staticTexts.element(matching: predicate)
        XCTAssertTrue(blikCTAText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func test3DS2Card_alwaysAuthenticate() throws {
        app.launch()
        app.staticTexts["PaymentSheet"].firstMatch.tap()
        let buyButton = app.staticTexts["Buy"].firstMatch
        XCTAssertTrue(buyButton.waitForExistenceIfNeeded(timeout: 60.0))
        buyButton.tap()

        // Card number from https://docs.stripe.com/testing#regulatory-cards
        try! fillCardData(app, cardNumber: "4000002760003184")
        app.buttons["Pay €9.73"].firstMatch.tap()
        let challengeCodeTextField = app.textFields["STDSTextField"].firstMatch
        XCTAssertTrue(challengeCodeTextField.waitForExistenceAndTap())
        challengeCodeTextField.typeText("424242")
        app.buttons["Submit"].firstMatch.tap()
        let successText = app.alerts.staticTexts["Your order is confirmed!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"].firstMatch
        okButton.tap()
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay €50.99"].firstMatch

        guard let eps = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "EPS") else {
            XCTFail()
            return
        }
        eps.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"].firstMatch
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["EPS Bank"].firstMatch
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "BKS Bank AG")
        app.toolbars.buttons["Done"].firstMatch.tap()

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay €50.99"].firstMatch

        guard let giro = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "giropay") else {
            XCTFail()
            return
        }
        giro.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"].firstMatch
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        let payButton = app.buttons["Pay €50.99"].firstMatch
        guard let p24 = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Przelewy24") else {
            XCTFail()
            return
        }
        p24.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"].firstMatch
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertFalse(payButton.isEnabled)
        let email = app.textFields["Email"].firstMatch
        email.tap()
        email.typeText("test@test.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["Przelewy24 Bank"].firstMatch
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "BNP Paribas")
        app.toolbars.buttons["Done"].firstMatch.tap()

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay $50.99"].firstMatch

        // Select Klarna
        guard let klarna = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Klarna") else {
            XCTFail()
            return
        }
        klarna.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Email"].firstMatch
        name.tap()
        name.typeText("foo@bar.com")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        // Country should be pre-filled

        // Attempt payment
        payButton.tap()

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
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
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay $50.99"].firstMatch

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

    func testAmazonPayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay $50.99"].firstMatch

        // Select Amazon Pay
        guard let amazonPay = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Amazon Pay") else {
            XCTFail()
            return
        }
        amazonPay.tap()

        XCTAssertTrue(payButton.isEnabled)

        // Attempt payment, should succeed
        payButton.tap()
    }

    func testAlmaPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.currency = .eur
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay €50.99"].firstMatch

        // Select Alma
        guard let alma = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Alma") else {
            XCTFail()
            return
        }
        alma.tap()

        XCTAssertTrue(payButton.isEnabled)

        // Attempt payment, should succeed
        payButton.tap()
    }

    func testZipPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .off
        settings.currency = .aud
        settings.merchantCountryCode = .AU
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay A$50.99"].firstMatch

        // Select Zip
        guard let zip = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Zip")
        else {
            XCTFail()
            return
        }
        zip.tap()

        // Attempt payment
        payButton.tap()

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay $50.99"].firstMatch

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
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
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
        app.buttons["Present PaymentSheet"].firstMatch.tap()

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

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertFalse(continueButton.isEnabled)

        let name = app.textFields["Full name"].firstMatch
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = app.textFields["Email"].firstMatch
        email.tap()
        email.typeText("test@example.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        let payButton = app.buttons["Pay $50.99"].firstMatch
        XCTAssertTrue(payButton.waitForExistenceIfNeeded(timeout: 5))

        let expectDefaultSelectionOn = Locale.current.regionCode == "US"
        let selectedMandate =
        "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."
        let unselectedMandate = "By continuing, you agree to authorize payments pursuant to these terms."
        XCTAssertTrue(
            app.textViews[expectDefaultSelectionOn ? selectedMandate : unselectedMandate].waitForExistenceIfNeeded(timeout: 5)
        )

        let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
        saveThisAccountToggle.tap()
        XCTAssertTrue(
            app.textViews[expectDefaultSelectionOn ? unselectedMandate : selectedMandate].waitForExistenceIfNeeded(timeout: 5)
        )

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testGrabPayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .sgd
        settings.merchantCountryCode = .SG
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay SGD 50.99"].firstMatch

        // Select GrabPay
        guard let grabPay = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "GrabPay")
        else {
            XCTFail()
            return
        }
        grabPay.tap()

        // Attempt payment
        payButton.tap()

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
        webviewCloseButton.tap()
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

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay ₹50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        let payButton = app.buttons["Pay ₹50.99"].firstMatch
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"].firstMatch
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

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay ₹50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        let payButton = app.buttons["Pay ₹50.99"].firstMatch
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"].firstMatch
        upi_id.tap()
        upi_id.typeText("payment.success")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        XCTAssertFalse(payButton.isEnabled)
    }

    // MARK: Card brand choice
    func testCardBrandChoice() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        loadPlayground(
            app,
            settings
        )

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoice_setup() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .setup
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        loadPlayground(
            app,
            settings
        )

        _testCardBrandChoice(isSetup: true, settings: settings)
    }

    func testCardBrandChoice_deferred() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.integrationType = .deferred_csc
        loadPlayground(
            app,
            settings
        )

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoiceWithPreferredNetworks() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .on
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        let cardBrandTextField = app.textFields["Visa"].firstMatch
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistenceIfNeeded(timeout: 2))

        let numberField = app.textFields["Card number"].firstMatch
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: 5))
        cardBrandChoiceDropdown.swipeDown()
        app.toolbars.buttons["Cancel"].firstMatch.tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceIfNeeded(timeout: 2))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceIfNeeded(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].firstMatch.waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].firstMatch.tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled and we should auto select Visa
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        // Finish checkout
        app.buttons["Pay €50.99"].firstMatch.tap()
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testCardBrandChoiceSavedCard() {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap(timeout: 5)
        let numberField = app.textFields["Card number"].firstMatch
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].firstMatch.waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].firstMatch.tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: 5))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].firstMatch.tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(app.textFields["Cartes Bancaires"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        // Finish checkout
        app.buttons["Pay €50.99"].firstMatch.tap()
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["••••1001"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistenceIfNeeded(timeout: 5))

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: 60.0))
        editButton.tap()

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: 5))

        // Update this card
        XCTAssertTrue(app.textFields["Cartes Bancaires"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistenceIfNeeded(timeout: 5))
        app.pickerWheels.firstMatch.swipeUp()
        app.toolbars.buttons["Done"].firstMatch.tap()
        app.buttons["Update card"].firstMatch.waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistenceIfNeeded(timeout: 5))

        // Update this card again
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistenceIfNeeded(timeout: 5))
        app.pickerWheels.firstMatch.swipeDown()
        app.toolbars.buttons["Done"].firstMatch.tap()
        app.buttons["Update card"].firstMatch.waitForExistenceAndTap(timeout: 5)

        // We should have updated to Cartes Bancaires
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistenceIfNeeded(timeout: 5))
        app.buttons["Done"].firstMatch.tap()

        // Pay with this card
        app.buttons["Pay €50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["••••1001"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistenceIfNeeded(timeout: 5))

        // Remove this card
        XCTAssertTrue(app.staticTexts["Edit"].firstMatch.waitForExistenceAndTap(timeout: 60.0))
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.buttons["Remove card"].firstMatch.waitForExistenceAndTap(timeout: 5))
        let confirmRemoval = app.alerts.buttons["Remove"].firstMatch
        XCTAssertTrue(confirmRemoval.waitForExistenceIfNeeded(timeout: 5))
        confirmRemoval.tap()

        // Card should be removed
        XCTAssertFalse(app.staticTexts["••••1001"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
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
        app.buttons["Present PaymentSheet"].firstMatch.tap()

        guard let sepa = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "SEPA Debit") else { XCTFail("Couldn't find SEPA"); return; }
        sepa.tap()

        app.textFields["Full name"].firstMatch.tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test@example.com" + XCUIKeyboardKey.return.rawValue)
        app.typeText("AT611904300234573201" + XCUIKeyboardKey.return.rawValue)
        app.textFields["Address line 1"].firstMatch.tap()
        app.typeText("510 Townsend St" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Floor 3" + XCUIKeyboardKey.return.rawValue)
        app.typeText("San Francisco" + XCUIKeyboardKey.return.rawValue)
        app.textFields["ZIP"].firstMatch.tap()
        app.typeText("94102" + XCUIKeyboardKey.return.rawValue)
        app.buttons["Pay €50.99"].firstMatch.tap()
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testAlipayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.apmsEnabled = .on
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        let payButton = app.buttons["Pay $50.99"].firstMatch
        guard let alipay = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Alipay") else {
            XCTFail()
            return
        }
        alipay.tap()

        XCTAssertTrue(payButton.isEnabled)
        payButton.tap()

        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 15.0))
    }

    func testOXXOPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .MX
        settings.currency = .mxn
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        guard let oxxo = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "OXXO") else {
            XCTFail()
            return
        }
        oxxo.tap()

        let name = app.textFields["Full name"].firstMatch
        name.tap()
        name.typeText("Jane Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = app.textFields["Email"].firstMatch
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        let payButton = app.buttons["Pay MX$50.99"].firstMatch
        XCTAssertTrue(payButton.isEnabled)
        payButton.tap()

        // Just check that a web view exists after tapping buy.
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
        webviewCloseButton.tap()

        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 15.0))
    }

    func testBoletoPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .BR
        settings.currency = .brl
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        guard let boleto = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Boleto") else {
            XCTFail()
            return
        }
        boleto.tap()

        let name = app.textFields["Full name"].firstMatch
        name.tap()
        app.typeText("Jane Doe")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("foo@bar.com")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("00000000000")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("123 fake st")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("City")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("AC")  // Valid brazilian state code.
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("11111111")
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let payButton = app.buttons["Pay R$50.99"].firstMatch
        XCTAssertTrue(payButton.isEnabled)
        payButton.tap()

        // Just check that a web view exists after tapping buy.
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
        webviewCloseButton.tap()

        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 15.0))
    }

    func testPayNowPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .sgd
        settings.merchantCountryCode = .SG
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let payButton = app.buttons["Pay SGD 50.99"].firstMatch

        // Select PayNow
        guard let payNow = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "PayNow")
        else {
            XCTFail()
            return
        }
        payNow.tap()

        // Attempt payment
        payButton.tap()

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testPromptPayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .thb
        settings.merchantCountryCode = .TH
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        // Select PromptPay
        guard let promptPay = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "PromptPay")
        else {
            XCTFail()
            return
        }
        promptPay.tap()

        // Fill in email
        let email = app.textFields["Email"].firstMatch
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        // Attempt payment
        XCTAssertTrue(app.buttons["Pay THB 50.99"].firstMatch.waitForExistenceAndTap(timeout: 5.0))

        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"].firstMatch
        XCTAssertTrue(webviewCloseButton.waitForExistenceIfNeeded(timeout: 10.0))
        webviewCloseButton.tap()
    }

    func testSwishPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .off
        settings.currency = .sek
        settings.merchantCountryCode = .FR
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()

        // Select Swish
        guard let swish = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Swish")
        else {
            XCTFail()
            return
        }
        swish.tap()

        // Attempt payment
        XCTAssertTrue(app.buttons["Pay SEK 50.99"].firstMatch.waitForExistenceAndTap(timeout: 5.0))

        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 15.0))
    }

    func testSavedSEPADebitPaymentMethod_FlowController_ShowsMandate() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        settings.mode = .setup
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 60.0))
        paymentMethodButton.tap()

        // Save SEPA
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        guard let sepa = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "SEPA Debit") else {
            XCTFail("Couldn't find SEPA")
            return
        }
        sepa.tap()

        app.textFields["Full name"].firstMatch.tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test@example.com" + XCUIKeyboardKey.return.rawValue)
        app.typeText("AT611904300234573201" + XCUIKeyboardKey.return.rawValue)
        app.textFields["Address line 1"].firstMatch.tap()
        app.typeText("510 Townsend St" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Floor 3" + XCUIKeyboardKey.return.rawValue)
        app.typeText("San Francisco" + XCUIKeyboardKey.return.rawValue)
        app.textFields["ZIP"].firstMatch.tap()
        app.typeText("94102" + XCUIKeyboardKey.return.rawValue)
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        // This time, expect SEPA to be pre-selected as the default
        XCTAssert(paymentMethodButton.label.hasPrefix("••••3201, sepa_debit"))

        // Tapping confirm without presenting flowcontroller should show the mandate
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.otherElements.matching(identifier: "mandatetextview").element.waitForExistenceIfNeeded(timeout: 1))
        // Tapping out should cancel the payment
        app.tap()
        XCTAssertTrue(app.staticTexts["Payment canceled."].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
        // Tapping confirm again and hitting continue should confirm the payment
        app.buttons["Confirm"].firstMatch.tap()
        app.buttons["Continue"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        // If you present the flowcontroller and see the mandate...
        XCTAssert(paymentMethodButton.label.hasPrefix("••••3201, sepa_debit"))
        paymentMethodButton.waitForExistenceAndTap()

        XCTAssertTrue(app.otherElements.matching(identifier: "mandatetextview").element.exists)
        // ...you shouldn't see the mandate again when you confirm
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
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

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        app.buttons["Pay $50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 10)

        XCTAssertEqual(
            // Ignore luxe_* analytics since there are a lot and I'm not sure if they're the same every time
            analyticsLog.map({ $0[string: "event"] }).filter({ $0 != "luxe_image_selector_icon_from_bundle" && $0 != "luxe_image_selector_icon_downloaded" }),
            ["mc_complete_init_applepay", "mc_load_started", "mc_load_succeeded", "mc_complete_sheet_newpm_show", "mc_form_shown"]
        )
        XCTAssertEqual(analyticsLog.last?[string: "selected_lpm"], "card")

        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].firstMatch.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        XCTAssertEqual(
            analyticsLog.suffix(6).map({ $0[string: "event"] }),
            ["mc_form_interacted", "mc_card_number_completed", "mc_confirm_button_tapped", "stripeios.payment_method_creation", "stripeios.payment_intent_confirmation", "mc_complete_payment_newpm_success"]
        )

        // Make sure they all have the same session id
        let sessionID = analyticsLog.first![string: "session_id"]
        XCTAssertTrue(!sessionID!.isEmpty)
        for analytic in analyticsLog {
            if (analytic["event"] as! String).starts(with: "stripeios") {
                continue
            }
            XCTAssertEqual(analytic[string: "session_id"], sessionID)
        }

    }

    func testDeferredPaymentIntent_ClientSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].firstMatch.tap()

        let declineText = app.staticTexts["Your card was declined."].firstMatch
        XCTAssertTrue(declineText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testDeferredSetupIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].firstMatch.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        settings.uiStyle = .flowController
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"].firstMatch
        XCTAssertTrue(selectText.waitForExistenceIfNeeded(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
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

        let selectButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"].firstMatch
        XCTAssertTrue(selectText.waitForExistenceIfNeeded(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
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
     
     app.buttons["Present PaymentSheet"].firstMatch.tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"].firstMatch
     XCTAssertTrue(payWithLinkButton.waitForExistenceIfNeeded(timeout: 10))
     payWithLinkButton.tap()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     XCTAssertTrue(modal.waitForExistenceIfNeeded(timeout: 10))
     
     let emailField = modal.textFields["Email"].firstMatch
     XCTAssertTrue(emailField.waitForExistenceIfNeeded(timeout: 10))
     emailField.tap()
     emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
     
     let phoneField = modal.textFields["Phone"].firstMatch
     XCTAssert(phoneField.waitForExistenceIfNeeded(timeout: 10))
     phoneField.tap()
     phoneField.typeText("3105551234")
     
     // The name field is only required for non-US countries. Only fill it out if it exists.
     let nameField = modal.textFields["Name"].firstMatch
     if nameField.exists {
     nameField.tap()
     nameField.typeText("Jane Done")
     }
     
     modal.buttons["Join Link"].firstMatch.tap()
     
     // Because we are presenting view controllers with `modalPresentationStyle = .overFullScreen`,
     // there are currently 2 card forms on screen. Specifying a container helps the `fillCardData()`
     // method operate on the correct card form.
     try fillCardData(app, container: modal)
     
     // Pay!
     let payButton = modal.buttons["Pay $50.99"].firstMatch
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let successText = app.staticTexts["Success!"].firstMatch
     XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_csc
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let applePayButton = app.buttons["apple_pay_button"].firstMatch
        XCTAssertTrue(applePayButton.waitForExistenceIfNeeded(timeout: 4.0))
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

        let paymentMethodButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 10.0))
        paymentMethodButton.tap()

        let applePay = app.collectionViews.buttons["Apple Pay"].firstMatch
        XCTAssertTrue(applePay.waitForExistenceIfNeeded(timeout: 10.0))
        applePay.tap()

        app.buttons["Confirm"].firstMatch.tap()

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
     
     app.buttons["Present PaymentSheet"].firstMatch.tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"].firstMatch
     XCTAssertTrue(payWithLinkButton.waitForExistenceIfNeeded(timeout: 10))
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
     
     app.buttons["Present PaymentSheet"].firstMatch.tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"].firstMatch
     XCTAssertTrue(payWithLinkButton.waitForExistenceIfNeeded(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistenceIfNeeded(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].firstMatch.tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"].firstMatch
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let failedText = modal.staticTexts["The payment failed."].firstMatch
     XCTAssertTrue(failedText.waitForExistenceIfNeeded(timeout: 10))
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
     
     let paymentMethodButton = app.buttons["Select Payment Method"].firstMatch
     XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"].firstMatch
     XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].firstMatch.tap()
     
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
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        try? fillCardData(app, container: nil)
        
        app.buttons["Pay $50.99"].firstMatch.tap()
        
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }
    
    func testDeferredPaymentIntent_ServerSideConfirmation_Multiprocessor() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(
            app,
            settings
        )
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        try? fillCardData(app, container: nil)
        
        app.buttons["Pay $50.99"].firstMatch.tap()
        
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }
    
    func testDeferredPaymentIntent_SeverSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        loadPlayground(
            app,
            settings
        )
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")
        
        app.buttons["Pay $50.99"].firstMatch.tap()
        
        let declineText = app.staticTexts["Your card was declined."].firstMatch
        XCTAssertTrue(declineText.waitForExistenceIfNeeded(timeout: 10.0))
    }
    
    func testDeferredSetupIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        try? fillCardData(app, container: nil)
        
        app.buttons["Set up"].firstMatch.tap()
        
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }
    
    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        loadPlayground(
            app,
            settings
        )
        
        let selectButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"].firstMatch
        XCTAssertTrue(selectText.waitForExistenceIfNeeded(timeout: 10.0))
        
        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()
        
        try? fillCardData(app, container: nil)
        
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
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
        
        let selectButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"].firstMatch
        XCTAssertTrue(selectText.waitForExistenceIfNeeded(timeout: 10.0))
        
        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()
        
        try? fillCardData(app, container: nil)
        
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
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
        
        let selectButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"].firstMatch
        XCTAssertTrue(selectText.waitForExistenceIfNeeded(timeout: 10.0))
        
        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()
        
        try? fillCardData(app, container: nil)
        
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
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
     
     app.buttons["Present PaymentSheet"].firstMatch.tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"].firstMatch
     XCTAssertTrue(payWithLinkButton.waitForExistenceIfNeeded(timeout: 10))
     payWithLinkButton.tap()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     XCTAssertTrue(modal.waitForExistenceIfNeeded(timeout: 10))
     
     let emailField = modal.textFields["Email"].firstMatch
     XCTAssertTrue(emailField.waitForExistenceIfNeeded(timeout: 10))
     emailField.tap()
     emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
     
     let phoneField = modal.textFields["Phone"].firstMatch
     XCTAssert(phoneField.waitForExistenceIfNeeded(timeout: 10))
     phoneField.tap()
     phoneField.typeText("3105551234")
     
     // The name field is only required for non-US countries. Only fill it out if it exists.
     let nameField = modal.textFields["Name"].firstMatch
     if nameField.exists {
     nameField.tap()
     nameField.typeText("Jane Done")
     }
     
     modal.buttons["Join Link"].firstMatch.tap()
     
     // Because we are presenting view controllers with `modalPresentationStyle = .overFullScreen`,
     // there are currently 2 card forms on screen. Specifying a container helps the `fillCardData()`
     // method operate on the correct card form.
     try fillCardData(app, container: modal)
     
     // Pay!
     let payButton = modal.buttons["Pay $50.99"].firstMatch
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let successText = app.staticTexts["Success!"].firstMatch
     XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation() {
        
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.integrationType = .deferred_ssc
        loadPlayground(
            app,
            settings
        )
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let applePayButton = app.buttons["apple_pay_button"].firstMatch
        XCTAssertTrue(applePayButton.waitForExistenceIfNeeded(timeout: 4.0))
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
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let applePayButton = app.buttons["apple_pay_button"].firstMatch
        XCTAssertTrue(applePayButton.waitForExistenceIfNeeded(timeout: 4.0))
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
        
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        let applePayButton = app.buttons["apple_pay_button"].firstMatch
        XCTAssertTrue(applePayButton.waitForExistenceIfNeeded(timeout: 4.0))
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
        
        var paymentMethodButton = app.buttons["Payment method"].firstMatch
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 60.0))
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
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        var successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        
        // Reload w/ same customer
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app)  // If the previous card was saved, we'll be on the 'saved pms' screen and this will fail
        
        // toggle save this card on
        saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        if !expectDefaultSelectionOn {
            saveThisCardToggle.tap()
        }
        XCTAssertTrue(saveThisCardToggle.isSelected)
        
        // Complete payment
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
        
        // Reload w/ same customer
        reload(app, settings: settings)
        
        // return to payment method selector
        paymentMethodButton = app.staticTexts["••••4242"].firstMatch  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 60.0))
        paymentMethodButton.tap()
        
        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: 60.0))
        editButton.tap()
        
        let removeButton = app.buttons["Remove"].firstMatch
        XCTAssertTrue(removeButton.waitForExistenceIfNeeded(timeout: 60.0))
        removeButton.tap()
        
        let confirmRemoval = app.alerts.buttons["Remove"].firstMatch
        XCTAssertTrue(confirmRemoval.waitForExistenceIfNeeded(timeout: 60.0))
        confirmRemoval.tap()
        
        // Should still show "+ Add" and Link
        XCTAssertEqual(app.cells.count, 2)
    }
}

class PaymentSheetMiscellaneousUITests: PaymentSheetUITestCase {
    // MARK: - External PayPal 
    func testExternalPaypalPaymentSheet() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.externalPayPalEnabled = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        let payButton = app.buttons["Pay $50.99"].firstMatch
        guard let paypal = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "PayPal") else {
            XCTFail()
            return
        }
        paypal.tap()
        payButton.tap()
        XCTAssertNotNil(app.staticTexts["Confirm external_paypal?"].firstMatch)
        app.buttons["Cancel"].firstMatch.tap()

        payButton.tap()
        app.buttons["Fail"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Something went wrong!"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))

        payButton.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
    }

    func testExternalPaypalPaymentSheetFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.externalPayPalEnabled = .on
        settings.uiStyle = .flowController

        loadPlayground(app, settings)

        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "PayPal")?.waitForExistenceAndTap()

        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()

        XCTAssertNotNil(app.staticTexts["Confirm external_paypal?"].firstMatch)
        app.buttons["Cancel"].firstMatch.tap()
        XCTAssertNotNil(app.staticTexts["Payment canceled."].firstMatch)

        let payButton = app.buttons["Confirm"].firstMatch
        payButton.tap()
        app.buttons["Fail"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Payment failed: Error Domain= Code=0 \"Something went wrong!\" UserInfo={NSLocalizedDescription=Something went wrong!}"].waitForExistenceIfNeeded(timeout: 5.0))

        payButton.tap()
        app.alerts.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
    }
    // MARK: - Customer Session
    func testDedupedPaymentMethods_paymentSheet() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerKeyType = .legacy
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkEnabled = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        // Complete payment
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.isEnabled)
        // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1))

        // Add another PM
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.isEnabled)

        // Assert there are two payment methods using legacy customer ephemeral key
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 2)

        // Close sheet
        app.buttons["Close"].firstMatch.waitForExistenceAndTap()

        // Change to CustomerSessions
        app.buttons["customer_session"].firstMatch.waitForExistenceAndTap()
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
        // Assert there is only a single payment method using CustomerSession
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 1)
        app.buttons["Close"].firstMatch.waitForExistenceAndTap()
    }

    func testDedupedPaymentMethods_FlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerKeyType = .legacy
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkEnabled = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Apple Pay, apple_pay"].firstMatch.waitForExistenceAndTap(timeout: 30) // Should default to None
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        // Complete payment
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.staticTexts["••••4242"].firstMatch.waitForExistenceAndTap()  // The card should be saved now and selected as default instead of Apple Pay
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        // Add another PM
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Should be able to edit two saved PMs
        reload(app, settings: settings)
        app.staticTexts["••••4242"].firstMatch.waitForExistenceAndTap()

        // Wait for the sheet to appear
        XCTAssertTrue(app.buttons["+ Add"].firstMatch.waitForExistenceIfNeeded(timeout: 3))

        // Scroll all the way over
        XCTAssertNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove"))

        // Assert there are two payment methods using legacy customer ephemeral key
        // value == 2, 1 value on playground + 2 payment method
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 3)

        // Close sheet
        app.buttons["Close"].firstMatch.waitForExistenceAndTap()

        // Change to CustomerSessions
        app.buttons["customer_session"].firstMatch.waitForExistenceAndTap()
        reload(app, settings: settings)

        // TODO: Use default payment method from elements/sessions payload
        app.buttons["Apple Pay, apple_pay"].firstMatch.waitForExistenceAndTap(timeout: 10)
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 3))

        // Assert there is only a single payment method using CustomerSession
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 1)
        app.buttons["Close"].firstMatch.waitForExistenceAndTap()
    }
    // MARK: - Remove last saved PM

    func testRemoveLastSavedPaymentMethodPaymentSheet() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkEnabled = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        // Complete payment
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.isEnabled)
        // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1))

        // Add another PM
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].firstMatch.isEnabled)
        // Should be able to edit two saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.alerts.buttons["Remove"].firstMatch.waitForExistenceAndTap())

        // Wait for page to refresh
        wait(timeout: 1.0)

        // Should be kicked out of edit mode now that we have one saved PM
        XCTAssertFalse(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Done" button is gone - we are not in edit mode
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Edit" button is gone - we can't edit
        XCTAssertTrue(app.buttons["Close"].firstMatch.waitForExistenceIfNeeded(timeout: 1))
    }

    func testRemoveLastSavedPaymentMethodFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkEnabled = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )

        app.buttons["Apple Pay, apple_pay"].firstMatch.waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        // Complete payment
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.staticTexts["••••4242"].firstMatch.waitForExistenceAndTap()  // The card should be saved now and selected as default instead of Apple Pay

        // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1))

        // Ensure we can tap another payment method, which will dismiss Flow Controller
        app.buttons["Apple Pay"].firstMatch.waitForExistenceAndTap()

        // Re-present the sheet
        app.staticTexts["apple_pay"].firstMatch.waitForExistenceAndTap()  // The Apple Pay is now the default because we tapped it

        // Add another PM
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // Should be able to edit two saved PMs
        reload(app, settings: settings)
        app.staticTexts["••••4242"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Edit"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.alerts.buttons["Remove"].firstMatch.waitForExistenceAndTap())

        // Wait for page to refresh
        wait(timeout: 1.0)
        
        // Should be kicked out of edit mode now that we have one saved PM
        XCTAssertFalse(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Done" button is gone - we are not in edit mode
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Edit" button is gone - we can't edit
        XCTAssertTrue(app.buttons["Close"].firstMatch.waitForExistenceIfNeeded(timeout: 1))
    }

    func testPreservesSelectionAfterDismissPaymentSheetFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new

        loadPlayground(app, settings)

        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try fillCardData(app)

        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        reload(app, settings: settings)

        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        // Tap to dismiss PaymentSheet
        app.tapCoordinate(at: CGPoint(x: 100, y: 100))
        // Give time for the dismiss animation and the payment option to update
        sleep(2)

        XCTAssertTrue(app.staticTexts["••••4242"].firstMatch.waitForExistenceAndTap(timeout: 10))
    }

    func testCVCRecollectionFlowController_deferredCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkEnabled = .off
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"].firstMatch

        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        // CVC field should already be selected
        app.typeText("123")

        let confirmButtons: XCUIElementQuery = app.buttons.matching(identifier: "Confirm")
        for index in 0..<confirmButtons.count {
            if confirmButtons.element(boundBy: index).isHittable {
                confirmButtons.element(boundBy: index).tap()
            }
        }
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testCVCRecollectionComplete_deferredCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkEnabled = .off
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        let payButton = app.buttons["Pay $50.99"].firstMatch
        XCTAssert(payButton.isEnabled)
        payButton.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        let cvcField = app.textFields["CVC"].firstMatch
        cvcField.forceTapWhenHittableInTestCase(self)
        app.typeText("123")
        app.buttons["Pay $50.99"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }

    func testCVCRecollectionFlowController_intentFirstCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.integrationType = .normal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkEnabled = .off
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"].firstMatch

        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        // CVC field should already be selected
        app.typeText("123")

        let confirmButtons: XCUIElementQuery = app.buttons.matching(identifier: "Confirm")
        for index in 0..<confirmButtons.count {
            if confirmButtons.element(boundBy: index).isHittable {
                confirmButtons.element(boundBy: index).tap()
            }
        }
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }
    func testCVCRecollectionComplete_intentFirstCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .paymentSheet
        settings.integrationType = .normal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkEnabled = .off
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        try! fillCardData(app)

        let payButton = app.buttons["Pay $50.99"].firstMatch
        XCTAssert(payButton.isEnabled)
        payButton.tap()

        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        let cvcField = app.textFields["CVC"].firstMatch
        cvcField.forceTapWhenHittableInTestCase(self)
        app.typeText("123")
        app.buttons["Pay $50.99"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }
    func testLinkOnlyFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.linkEnabled = .on

        loadPlayground(app, settings)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
        app.buttons["pay_with_link_button"].firstMatch.waitForExistenceAndTap()

        let expectation = XCTestExpectation(description: "Link sign in dialog")
        // Listen for the system login dialog
        addUIInterruptionMonitor(withDescription: "Link sign in system dialog") { alert in
            // Cancel the payment
            alert.buttons["Cancel"].firstMatch.waitForExistenceAndTap()
            expectation.fulfill()
            return true
        }

        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        app.tap() // required to trigger the UI interruption monitor
        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(app.staticTexts["Payment canceled."].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        // Re-tapping the payment method button should present the saved payment view
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Card information"].firstMatch.waitForExistenceIfNeeded(timeout: 5))
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
     
     app.buttons["Present PaymentSheet"].firstMatch.tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"].firstMatch
     XCTAssertTrue(payWithLinkButton.waitForExistenceIfNeeded(timeout: 10))
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
     
     app.buttons["Present PaymentSheet"].firstMatch.tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"].firstMatch
     XCTAssertTrue(payWithLinkButton.waitForExistenceIfNeeded(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistenceIfNeeded(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].firstMatch.tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"].firstMatch
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let declineText = app.staticTexts["Your card was declined."].firstMatch
     XCTAssertTrue(declineText.waitForExistenceIfNeeded(timeout: 10.0))
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
     
     let paymentMethodButton = app.buttons["Select Payment Method"].firstMatch
     XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"].firstMatch
     XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].firstMatch.tap()
     
     try loginAndPay()
     }
     */
}

// MARK: - Link
class PaymentSheetLinkUITests: PaymentSheetUITestCase {
    // MARK: PaymentSheet Link inline signup

    // Tests the #1 flow in PaymentSheet where the merchant disable saved payment methods and first time Link user
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheet_disabledSPM_firstTimeLinkUser() {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.customerMode = .guest
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//
//        loadPlayground(app, settings)
//        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
//        fillLinkAndPay(mode: .checkbox)
//    }

    // Tests the #2 flow in PaymentSheet where the merchant disable saved payment methods and returning Link user
    func testLinkPaymentSheet_disabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
    }

    // Tests the #3 flow in PaymentSheet where the merchant enables saved payment methods, buyer has no SPMs and first time Link user
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheet_enabledSPM_noSPMs_firstTimeLinkUser() throws {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.customerMode = .new
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//
//        loadPlayground(app, settings)
//        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
//        fillLinkAndPay(mode: .fieldConsent)
//    }

    // Tests the #4 flow in PaymentSheet where the merchant enables saved payment methods, buyer has no SPMs and returning Link user
    func testLinkPaymentSheet_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
    }

    // Tests the #5 flow in PaymentSheet where the merchant enables saved payment methods, buyer has SPMs and first time Link user
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser() {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.customerMode = .new
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//
//        loadPlayground(app, settings)
//        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
//
//        // Begin by saving a card for this new user who is not signed up for Link
//        try! fillCardData(app)
//        app.buttons["Pay $50.99"].firstMatch.tap()
//        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
//
//        // reload w/ same customer
//        reload(app, settings: settings)
//        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
//        // Ensure Link wallet button is shown in SPM view
//        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
//        let addCardButton = app.buttons["+ Add"].firstMatch
//        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
//        addCardButton.tap()
//        fillLinkAndPay(mode: .fieldConsent, cardNumber: "5555555555554444")
//
//        // reload w/ same customer
//        reload(app, settings: settings)
//        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
//        // Ensure both PMs exist
//        XCTAssertTrue(app.staticTexts["••••4242"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
//        XCTAssertTrue(app.staticTexts["••••4444"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
//    }

    // Tests the #6 flow in PaymentSheet where the merchant enables saved payment methods, buyer has SPMs and returning Link user
    func testLinkPaymentSheet_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        // Setup a saved card to simulate having saved payment methods
        try! fillCardData(app, postalEnabled: false) // postal pre-filled by default billing address
        app.buttons["Pay $50.99"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"].firstMatch
        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
        addCardButton.tap()
        assertLinkInlineSignupNotShown()
    }

    // MARK: PaymentSheet.FlowController Link inline signup

    // Tests the #7 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and saved payment methods and first time Link user
    // Seealso: testLinkOnlyFlowController for testing wallet button behavior in this flow
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheetFlow_disabledApplePay_disabledSPM_firstTimeLinkUser() {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.uiStyle = .flowController
//        settings.customerMode = .guest
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//        settings.applePayEnabled = .off
//
//        loadPlayground(app, settings)
//        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
//        fillLinkAndPay(mode: .checkbox, uiStyle: .flowController)
//    }

    // Tests the #8 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_disabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()

        // Ensure Link wallet button is shown
        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
    }

    // Tests the #9 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and first time Link user
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_firstTimeLinkUser() {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.uiStyle = .flowController
//        settings.customerMode = .new
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//        settings.applePayEnabled = .off
//
//        loadPlayground(app, settings)
//        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
//        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController)
//    }

    // Tests the #10 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()

        // Ensure Link wallet button is shown
        XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
    }

    // Tests the #11 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and first time Link user
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_hasSPMs_firstTimeLinkUser() {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.uiStyle = .flowController
//        settings.customerMode = .new
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//        settings.applePayEnabled = .off
//
//        loadPlayground(app, settings)
//        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
//        // Begin by saving a card for this new user who is not signed up for Link
//        try! fillCardData(app)
//        app.buttons["Continue"].firstMatch.tap()
//        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
//        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
//
//        // reload w/ same customer
//        reload(app, settings: settings)
//        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
//        // Ensure Link wallet button is NOT shown in SPM view
//        XCTAssertFalse(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
//        let addCardButton = app.buttons["+ Add"].firstMatch
//        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
//        addCardButton.tap()
//        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController, showLinkWalletButton: false)
//    }

    // Tests the #11.1 flow in PaymentSheet.FlowController where the merchant enables Apple Pay and enables saved payment methods and first time Link user
    // TODO: Disabled for ir-perturb-silences
//    func testLinkPaymentSheetFlow_enabledApplePay_enabledSPM_hasSPMs_firstTimeLinkUser() {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.uiStyle = .flowController
//        settings.customerMode = .new
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//        settings.applePayEnabled = .on
//
//        loadPlayground(app, settings)
//        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
//        XCTAssertTrue(app.buttons["+ Add"].firstMatch.waitForExistenceAndTap())
//        // Begin by saving a card for this new user who is not signed up for Link
//        XCTAssertTrue(app.buttons["Continue"].firstMatch.waitForExistenceIfNeeded(timeout: 5))
//        try! fillCardData(app)
//        app.buttons["Continue"].firstMatch.tap()
//        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
//        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
//
//        // reload w/ same customer
//        reload(app, settings: settings)
//        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
//        // Ensure Link wallet button is NOT shown in SPM view
//        XCTAssertFalse(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
//        let addCardButton = app.buttons["+ Add"].firstMatch
//        XCTAssertTrue(addCardButton.waitForExistenceIfNeeded(timeout: 4.0))
//        addCardButton.tap()
//        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController, showLinkWalletButton: false)
//    }

    // Tests the #12 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()

        // Setup a saved card to simulate having saved payment methods
        try! fillCardData(app, postalEnabled: false) // postal pre-filled by default billing address
        app.buttons["Continue"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()

        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        assertLinkInlineSignupNotShown() // Link should not be shown in this flow
    }

    // Tests the #12.1 flow in PaymentSheet.FlowController where the merchant enables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_enablesApplePay_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkEnabled = .on
        settings.applePayEnabled = .on
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].firstMatch.waitForExistenceIfNeeded(timeout: 5.0))
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        assertLinkInlineSignupNotShown() // Link should not be shown in this flow
    }

    // TODO: Disabled for ir-perturb-silences
//    func testLinkInlineSignup_gb() throws {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.customerMode = .guest
//        settings.apmsEnabled = .on
//        settings.linkEnabled = .on
//        settings.userOverrideCountry = .GB
//
//        loadPlayground(app, settings)
//
//        app.buttons["Present PaymentSheet"].firstMatch.waitForExistenceAndTap()
//
//        try fillCardData(app)
//
//        app.switches["Save your info for secure 1-click checkout with Link"].tap()
//
//        let emailField = app.textFields["Email"].firstMatch
//        emailField.tap()
//        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
//
//        let phoneField = app.textFields["Phone number"].firstMatch
//        // Phone field appears after the network call finishes. We want to wait for it to appear.
//        XCTAssert(phoneField.waitForExistenceIfNeeded(timeout: 10))
//        phoneField.tap()
//        phoneField.typeText("3105551234")
//
//        // The name field is required for non-US countries
//        let nameField = app.textFields["Full name"].firstMatch
//        XCTAssert(nameField.waitForExistenceIfNeeded(timeout: 10))
//        nameField.tap()
//        nameField.typeText("Jane Doe")
//
//        // Pay!
//        app.buttons["Pay $50.99"].firstMatch.tap()
//
//        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
//    }

    // MARK: Link test helpers

    private enum LinkMode {
        case checkbox
        case fieldConsent
    }

    private func fillLinkAndPay(mode: LinkMode,
                                uiStyle: PaymentSheetTestPlaygroundSettings.UIStyle = .paymentSheet,
                                showLinkWalletButton: Bool = true,
                                cardNumber: String? = nil) {

        try! fillCardData(app, cardNumber: cardNumber)

        if showLinkWalletButton {
            // Confirm Link wallet button is visible
            XCTAssertTrue(app.buttons["pay_with_link_button"].firstMatch.exists)
        }

        if mode == .checkbox {
            app.switches["Save your info for secure 1-click checkout with Link"].tap()
        }

        let emailField = app.textFields["Email"].firstMatch
        XCTAssertTrue(emailField.waitForExistenceIfNeeded(timeout: 10))
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")

        let phoneField = app.textFields["Phone number"].firstMatch
        XCTAssert(phoneField.waitForExistenceIfNeeded(timeout: 10))
        phoneField.tap()
        phoneField.typeText("3105551234")

        // The name field is only required for non-US countries. Only fill it out if it exists.
        let nameField = app.textFields["Name"].firstMatch
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Jane Done")
        }

        // Pay!
        switch uiStyle {
        case .paymentSheet:
            app.buttons["Pay $50.99"].firstMatch.tap()
        case .flowController:
            app.buttons["Continue"].firstMatch.tap()
            app.buttons["Confirm"].firstMatch.waitForExistenceAndTap()
        }
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
    }

    private func assertLinkInlineSignupNotShown() {
        // Ensure checkbox is not shown for checkbox mode
        XCTAssertFalse(app.switches["Save your info for secure 1-click checkout with Link"].waitForExistenceIfNeeded(timeout: 2))
        // Ensure email is not shown for field consent mode
        XCTAssertFalse(app.textFields["Email"].firstMatch.waitForExistenceIfNeeded(timeout: 3))
    }

//    TODO: This is disabled until the Link team adds some hooks for testing.
//    func testLinkWebFlow() throws {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.customerMode = .guest
//        settings.linkEnabled = .on
//
//        loadPlayground(app, settings)
//
//        app.buttons["Present PaymentSheet"].firstMatch.tap()
//
//        app.buttons["Pay with Link"].firstMatch.forceTapWhenHittableInTestCase(self)
//
//        // Allow link.com to sign in
//        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
//        springboard.buttons["Continue"].firstMatch.forceTapWhenHittableInTestCase(self)
//        
//        let emailField = app.webViews.textFields.firstMatch
//        emailField.forceTapWhenHittableInTestCase(self)
//        emailField.typeText("test@example.com")
//
//        let verificationCodeField = app.webViews.staticTexts["•"].firstMatch
//        verificationCodeField.forceTapWhenHittableInTestCase(self)
//        verificationCodeField.typeText("000000")
//
//        // Pay!
//        app.webViews.buttons["Pay $50.99"].firstMatch.tap()
//
//        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10.0))
//    }
}

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
        app.buttons["Present PaymentSheet"].firstMatch.tap()

        // Select US Bank Account
        guard let usBankAccount = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US Bank Account") else {
            XCTFail()
            return
        }
        usBankAccount.tap()

        // Fill out name and email fields
        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Full name"].firstMatch.tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test-\(UUID().uuidString)@example.com" + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].firstMatch.tap()
        app.staticTexts["Test Institution"].firstMatch.forceTapElement()
        app.staticTexts["Success"].firstMatch.waitForExistenceAndTap(timeout: 10)
        app.buttons["account_picker_link_accounts_button"].firstMatch.tap()

        let notNowButton = app.buttons["Not now"].firstMatch
        if notNowButton.waitForExistenceIfNeeded(timeout: 10.0) {
            notNowButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Success"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        // Confirm
        let confirmButtonText = mode == .payment ? "Pay $50.99" : "Set up"
        app.buttons[confirmButtonText].waitForExistenceAndTap()
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))

        // Reload and pay with the now-saved us bank account
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].firstMatch.tap()
        XCTAssertTrue(app.buttons["••••1113"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.buttons[confirmButtonText].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Success!"].firstMatch.waitForExistenceIfNeeded(timeout: 10))
    }

    func payWithApplePay() {
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)

        let predicate = NSPredicate(format: "label BEGINSWITH 'Simulated Card'")

        let cardButton = applePay.buttons.containing(predicate).firstMatch
        XCTAssertTrue(cardButton.waitForExistenceIfNeeded(timeout: 10.0))
        // Wait a second for the Apple Pay sheet animation to settle down
        wait(timeout: 1.0)
        cardButton.forceTapElement()

        addApplePayBillingIfNeeded(applePay)

        let cardSelectionButton = applePay.cells.containing(predicate).firstMatch
        XCTAssertTrue(cardSelectionButton.waitForExistenceIfNeeded(timeout: 10.0))
        cardSelectionButton.forceTapElement()

        let payButton = applePay.buttons["Pay with Passcode"].firstMatch
        XCTAssertTrue(payButton.waitForExistenceIfNeeded(timeout: 10.0))
        wait(timeout: 1.0)
        payButton.forceTapElement()

        let successText = app.staticTexts["Success!"].firstMatch
        //      This actually takes upwards of 20 seconds sometimes, especially in the deferred flow :/
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 30.0))
    }

    func addApplePayBillingIfNeeded(_ applePay: XCUIApplication) {
        // Fill out billing details if required
        let addBillingDetailsButton = applePay.buttons["Add Billing Address"].firstMatch
        if addBillingDetailsButton.waitForExistenceIfNeeded(timeout: 4.0) {
            addBillingDetailsButton.tap()
            
            let zipCell = applePay.textFields["ZIP"].firstMatch
            zipCell.tap()
            zipCell.typeText("95014")
            
            let cityCell = applePay.textFields["City"].firstMatch
            cityCell.tap()
            cityCell.typeText("Cupertino")
            
            let streetCell = applePay.textFields["Street"].firstMatch
            streetCell.tap()
            streetCell.typeText("One Apple Park Way")
            
            let firstNameCell = applePay.textFields["First Name"].firstMatch
            firstNameCell.tap()
            firstNameCell.typeText("Jane")

            let lastNameCell = applePay.textFields["Last Name"].firstMatch
            lastNameCell.tap()
            lastNameCell.typeText("Doe")

            applePay.buttons["Done"].firstMatch.tap()
        }
    }

    func _testCardBrandChoice(isSetup: Bool = false, settings: PaymentSheetTestPlaygroundSettings) {
        app.buttons["Present PaymentSheet"].firstMatch.tap()

        let cardBrandTextField = app.textFields["Select card brand (optional)"].firstMatch
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistenceIfNeeded(timeout: 2))

        let numberField = app.textFields["Card number"].firstMatch
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: 5))
        cardBrandChoiceDropdown.swipeUp()
        app.toolbars.buttons["Cancel"].firstMatch.tap()

        // We should still have no selected card brand
        XCTAssertTrue(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceIfNeeded(timeout: 2))

        // Select Visa from the CBC dropdown
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: 5))
        cardBrandChoiceDropdown.swipeUp()
        app.toolbars.buttons["Done"].firstMatch.tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceIfNeeded(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].firstMatch.waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].firstMatch.tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: 5))
        cardBrandChoiceDropdown.swipeUp() // Swipe to select Visa
        app.toolbars.buttons["Done"].firstMatch.tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceIfNeeded(timeout: 5))

        // Finish checkout
        let confirmButtonText = isSetup ? "Set up" : "Pay €50.99"
        app.buttons[confirmButtonText].tap()
        let successText = app.staticTexts["Success!"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: 10.0))
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else {
            return
        }

        // offset tap location a bit so cursor is at end of string
        let offsetTapLocation = coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6))
        offsetTapLocation.tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}

extension XCUIElement {
    /// Scrolls a picker wheel up by one option.
    func selectNextOption() {
        let startCoord = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoord = startCoord.withOffset(CGVector(dx: 0.0, dy: 30.0)) // 30pts = height of picker item
        endCoord.tap()
    }
}

extension XCUIApplication {
    func tapCoordinate(at point: CGPoint) {
        let normalized = coordinate(withNormalizedOffset: .zero)
        let offset = CGVector(dx: point.x, dy: point.y)
        let coordinate = normalized.withOffset(offset)
        coordinate.tap()
    }
}

extension Dictionary {
    subscript(string key: Key) -> String? {
        return self[key] as? String
    }
}

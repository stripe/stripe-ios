//
//  PaymentSheetLPMUITest.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 7/17/24.
//

import XCTest

class PaymentSheetStandardLPMUIOneTests: PaymentSheetStandardLPMUICase {
    func testEPS() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()
        tapPaymentMethod("EPS")

        let payButton = app.buttons["Pay €50.99"]
        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)
        payButton.tap()

        // Pay
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testP24() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let payButton = app.buttons["Pay €50.99"]
        tapPaymentMethod("Przelewy24")

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

        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    // Klarna has a text field and country drop down
    func testKlarnaPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay $50.99"]

        // Select Klarna
        tapPaymentMethod("Klarna")

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Email"]
        name.tap()
        name.typeText("foo@bar.com")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        // Country should be pre-filled

        // Attempt payment
        payButton.tap()

        // Klarna uses ASWebAuthenticationSession, tap continue to allow the web view to open:
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let sbContinueButton = springboard.buttons["Continue"]
        XCTAssertTrue(sbContinueButton.waitForExistence(timeout: 10.0))
        sbContinueButton.tap()
        // Stop here; Klarna's test playground is out of scope
    }

    func testAffirmPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .off
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select affirm
        tapPaymentMethod("Affirm")

        // Pay
        app.buttons["Pay $50.99"].waitForExistenceAndTap()

        // Close the webview, Affirm's test playground is out of scope
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 10)
    }

    func testAmazonPayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .off
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select Amazon Pay
        tapPaymentMethod("Amazon Pay")

        // Pay
        app.buttons["Pay $50.99"].waitForExistenceAndTap()

        // Close the webview, Amazon Pay test playground is out of scope
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 10)
    }

    func testAlmaPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.currency = .eur
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.apmsEnabled = .off
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select Alma
        tapPaymentMethod("Alma")

        // Pay
        app.buttons["Pay €50.99"].waitForExistenceAndTap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

        func testSunbitPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.currency = .usd
        settings.amount = ._10000
        settings.merchantCountryCode = .US
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select Sunbit
        tapPaymentMethod("Sunbit")

        // Pay
        app.buttons["Pay $100.00"].waitForExistenceAndTap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testBilliePaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.currency = .eur
        settings.merchantCountryCode = .DE
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select Billie
        tapPaymentMethod("Billie")

        // Pay
        app.buttons["Pay €50.99"].waitForExistenceAndTap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testSatispayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.currency = .eur
        settings.merchantCountryCode = .IT
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select Satispay
        tapPaymentMethod("Satispay")

        // Pay
        app.buttons["Pay €50.99"].waitForExistenceAndTap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testZipPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .off
        settings.currency = .aud
        settings.merchantCountryCode = .AU
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select Zip
        tapPaymentMethod("Zip")

        // Pay
        app.buttons["Pay A$50.99"].waitForExistenceAndTap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testCashAppPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        loadPlayground(app, settings)

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

        // Close the webview, to simulate cancel
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 15)

        // Tap to attempt a payment, but fail it
        payButton.waitForExistenceAndTap()
        let failPaymentText = app.firstDescendant(withLabel: "FAIL TEST PAYMENT")
        failPaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["The customer declined this payment."].waitForExistence(timeout: 5.0))

        // Tap to attempt a payment
        payButton.waitForExistenceAndTap()
        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testCashAppPaymentMethod_setup() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let setupButton = app.buttons["Set up"]

        // Select Cash App
        tapPaymentMethod("Cash App Pay")

        // Attempt set up
        setupButton.tap()

        // Close the webview, to simulate cancel
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 15)

        // Tap to attempt a set up, but fail it
        setupButton.waitForExistenceAndTap()
        let failSetupText = app.firstDescendant(withLabel: "FAIL TEST SETUP")
        failSetupText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["The customer declined this payment."].waitForExistence(timeout: 5.0))

        // Tap to attempt a set up, make it succeed
        setupButton.waitForExistenceAndTap()
        let approveSetupText = app.firstDescendant(withLabel: "AUTHORIZE TEST SETUP")
        approveSetupText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testCashAppPaymentMethod_setupFutureUsage() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.mode = .paymentWithSetup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay $50.99"]

        // Select Cash App
        tapPaymentMethod("Cash App Pay")

        // Attempt to pay
        payButton.tap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }
}

class PaymentSheetStandardLPMUITwoTests: PaymentSheetStandardLPMUICase {
    func testAmazonPayPaymentMethod_setup() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()

        // Select Amazon Pay
        tapPaymentMethod("Amazon Pay")

        // Attempt set up
        app.buttons["Set up"].tap()

        // Close the webview, Amazon Pay test playground is out of scope
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 10)
    }

    func testPayPalPaymentMethod_setup() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()

        // Select PayPal
        tapPaymentMethod("PayPal")
        app.buttons["Set up"].tap()
        waitForASWebAuthSigninModalAndTapContinue()
        webviewAuthorizeSetupButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testRevolutPayPaymentMethod_setup() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.merchantCountryCode = .GB
        settings.currency = .gbp
        settings.mode = .setup
        loadPlayground(
            app,
            settings
        )

        app.buttons["Present PaymentSheet"].tap()

        // Select Revolut Pay
        tapPaymentMethod("Revolut Pay")

        // Attempt set up
        app.buttons["Set up"].tap()

        // Close the webview, Revolut Pay test playground is out of scope
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 10)
    }

    func testUSBankAccountPaymentMethod() throws {
        app.launchEnvironment = app.launchEnvironment.merging([
            "FinancialConnectionsSDKAvailable": "true",
            "FinancialConnectionsStubbedResult": "true",
        ]) { (_, new) in new }
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select US Bank Account
        tapPaymentMethod("US bank account")

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

        let selectedMandate =
        "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."
        let unselectedMandate = "By continuing, you agree to authorize payments pursuant to these terms."
        XCTAssertTrue(
            app.textViews[unselectedMandate].waitForExistence(timeout: 5)
        )

        let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
        saveThisAccountToggle.tap()
        XCTAssertTrue(
            app.textViews[selectedMandate].waitForExistence(timeout: 5)
        )

        // no pay button tap because linked account is stubbed/fake in UI test
    }

    func testGrabPayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .sgd
        settings.merchantCountryCode = .SG
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select GrabPay
        tapPaymentMethod("GrabPay")

        // Pay
        app.buttons["Pay SGD 50.99"].tap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testPaymentIntent_USBankAccount() {
        _testUSBankAccount(mode: .payment, integrationType: .normal)
    }

    func testSetupIntent_USBankAccount() {
        _testUSBankAccount(mode: .setup, integrationType: .normal)
    }

    func testPaymentIntent_instantDebits() {
        _testInstantDebits(mode: .payment)
    }

    func testSetupIntent_instantDebits() {
        _testInstantDebits(mode: .setup)
    }

    func testUPIPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .IN
        settings.currency = .inr
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay ₹50.99"].waitForExistence(timeout: 5))

        let payButton = app.buttons["Pay ₹50.99"]
        tapPaymentMethod("UPI")

        XCTAssertFalse(payButton.isEnabled)
        // Test invalid VPA
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success" + XCUIKeyboardKey.return.rawValue)
        XCTAssertFalse(payButton.isEnabled)

        // Test valid VPA
        upi_id.tap()
        upi_id.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "payment.success".count))
        upi_id.typeText("payment.success@stripeupi" + XCUIKeyboardKey.return.rawValue)
        payButton.tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // This only tests the PaymentSheet + PaymentIntent flow.
    // Other confirmation flows are tested in PaymentSheet+LPMTests.swift
    func testSEPADebitPaymentMethod_PaymentSheet() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.currency = .eur
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        tapPaymentMethod("SEPA Debit")

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

    func testSavedSEPADebitPaymentMethod_FlowController_ShowsMandate() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        settings.mode = .setup
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        // Save SEPA
        app.buttons["+ Add"].waitForExistenceAndTap()
        tapPaymentMethod("SEPA Debit")

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
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        // This time, expect SEPA to be pre-selected as the default
        XCTAssert(paymentMethodButton.label.hasPrefix("••••3201, sepa_debit"))

        // Tapping confirm without presenting flowcontroller should show the mandate
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.otherElements.matching(identifier: "mandatetextview").element.waitForExistence(timeout: 1))
        // Tapping out should cancel the payment
        app.tap()
        XCTAssertTrue(app.staticTexts["Payment canceled."].waitForExistence(timeout: 10.0))
        // Tapping confirm again and hitting continue should confirm the payment
        app.buttons["Confirm"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        // If you present the flowcontroller and see the mandate...
        XCTAssert(paymentMethodButton.label.hasPrefix("••••3201, sepa_debit"))
        paymentMethodButton.waitForExistenceAndTap()

        XCTAssertTrue(app.otherElements.matching(identifier: "mandatetextview").element.exists)
        // ...you shouldn't see the mandate again when you confirm
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    func testAlipayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.apmsEnabled = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let payButton = app.buttons["Pay $50.99"]
        tapPaymentMethod("Alipay")

        payButton.tap()

        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testPayNowPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .sgd
        settings.merchantCountryCode = .SG
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select PayNow
        tapPaymentMethod("PayNow")

        // Attempt payment
        app.buttons["Pay SGD 50.99"].tap()
        app.webViews.webViews.webViews.buttons["Simulate scan"].waitForExistenceAndTap(timeout: 15)
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 25.0))
    }
}

class PaymentSheetStandardLPMUIThreeTests: PaymentSheetStandardLPMUICase {
    func testPromptPayPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .on
        settings.currency = .thb
        settings.merchantCountryCode = .TH
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select PromptPay
        tapPaymentMethod("PromptPay")

        // Fill in email
        let email = app.textFields["Email"]
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        // Attempt payment
        XCTAssertTrue(app.buttons["Pay THB 50.99"].waitForExistenceAndTap(timeout: 5.0))
        app.webViews.webViews.webViews.buttons["Simulate scan"].waitForExistenceAndTap(timeout: 15)
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 10)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 25.0))
    }

    func testSwishPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new // new customer
        settings.apmsEnabled = .off
        settings.currency = .sek
        settings.merchantCountryCode = .FR
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select Swish
        tapPaymentMethod("Swish")

        // Attempt payment
        XCTAssertTrue(app.buttons["Pay SEK 50.99"].waitForExistenceAndTap(timeout: 5.0))
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 15)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testBlikPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.apmsEnabled = .on
        settings.currency = .pln
        settings.merchantCountryCode = .FR
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select Blik and pay
        tapPaymentMethod("BLIK")
        app.textFields["BLIK code"].waitForExistenceAndTap()
        app.typeText("123456")
        XCTAssertTrue(app.buttons["Pay PLN 50.99"].waitForExistenceAndTap(timeout: 1.0))

        // Cancel
        XCTAssertTrue(app.buttons["Cancel and pay another way"].waitForExistenceAndTap(timeout: 1.0))

        // Pay
        XCTAssertTrue(app.buttons["Pay PLN 50.99"].waitForExistenceAndTap(timeout: 5.0))
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 20.0))
    }

    func testBacsDebit() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.apmsEnabled = .on
        settings.currency = .gbp
        settings.merchantCountryCode = .GB
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // Select Blik and pay
        tapPaymentMethod("Bacs Direct Debit")
        app.textFields["Full name"].tap()
        app.typeText("Jane Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("foo@bar.com" + XCUIKeyboardKey.return.rawValue)
        app.typeText("108800")
        app.typeText("00012345")
        app.typeText("123 Main St" + XCUIKeyboardKey.return.rawValue + XCUIKeyboardKey.return.rawValue)
        app.typeText("San Francisco" + XCUIKeyboardKey.return.rawValue)
        app.toolbars.buttons["Done"].tap() // State picker toolbar's "Done" button
        app.typeText("94010" + XCUIKeyboardKey.return.rawValue)
        let payButton = app.buttons["Pay £50.99"]
        XCTAssertFalse(payButton.isEnabled)
        let checkbox = app.switches.firstMatch
        XCTAssertEqual(checkbox.label, "I understand that Stripe will be collecting Direct Debits on behalf of Example, Inc. and confirm that I am the account holder and the only person required to authorise debits from this account.")
        checkbox.tap()
        payButton.tap()
        app.buttons["Modify Details"].waitForExistenceAndTap()
        payButton.waitForExistenceAndTap()
        app.buttons["Confirm"].waitForExistenceAndTap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 20.0))
    }

    // MARK: - Voucher based LPMs
    /// https://docs.stripe.com/payments/vouchers
    func testMultibancoPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.currency = .eur
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        tapPaymentMethod("Multibanco")

        let email = app.textFields["Email"]
        email.tap()
        app.typeText("foo@bar.com")
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let payButton = app.buttons["Pay €50.99"]
        XCTAssertTrue(payButton.isEnabled)
        payButton.tap()

        // Multibanco is a voucher-based LPM, so once you close the browser the payment is considered completed
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        webviewCloseButton.waitForExistenceAndTap(timeout: 15)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testOXXOPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .MX
        settings.currency = .mxn
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        tapPaymentMethod("OXXO")

        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("Jane Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let email = app.textFields["Email"]
        email.tap()
        email.typeText("foo@bar.com")
        email.typeText(XCUIKeyboardKey.return.rawValue)

        let payButton = app.buttons["Pay MX$50.99"]
        XCTAssertTrue(payButton.isEnabled)
        payButton.tap()

        // OXXO is a voucher-based LPM, so once you close the browser the payment is considered completed
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        webviewCloseButton.waitForExistenceAndTap(timeout: 15)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }

    func testBoletoPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .BR
        settings.currency = .brl
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        tapPaymentMethod("Boleto")

        let name = app.textFields["Full name"]
        name.tap()
        app.typeText("Jane Doe")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("foo@bar.com")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("00000000000")
        app.toolbars.buttons["Done"].tap() // Tap "Done", don't hit return - that's not possible using the system numpad keyboard
        app.textFields["Address line 1"].tap()
        app.typeText("123 fake st")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("City")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("AC")  // Valid brazilian state code.
        app.typeText(XCUIKeyboardKey.return.rawValue)
        app.typeText("11111111")
        app.typeText(XCUIKeyboardKey.return.rawValue)

        app.buttons["Pay R$50.99"].tap()

        // Boleto is a voucher-based LPM, so once you close the browser the payment is considered completed
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        webviewCloseButton.waitForExistenceAndTap(timeout: 15)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }
}
class PaymentSheetStandardLPMUICBCTests: PaymentSheetStandardLPMUICase {
    // MARK: Card brand choice

    func testCardBrandChoice() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        loadPlayground(app, settings)

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoice_setup() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .setup
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        loadPlayground(app, settings)

        _testCardBrandChoice(isSetup: true, settings: settings)
    }

    func testCardBrandChoice_deferred() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoiceWithPreferredNetworks() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        let cardBrandTextField = app.textFields["Visa"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistence(timeout: 2))

        let numberField = app.textFields["Card number"]
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeDown()
        app.toolbars.buttons["Cancel"].tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 2))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].waitForExistence(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled and we should auto select Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Finish checkout
        app.buttons["Pay €50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCardBrandChoiceSavedCard() {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        let numberField = app.textFields["Card number"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistence(timeout: 5))

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Finish checkout
        app.buttons["Pay €50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))

        // Update this card
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.swipeUp()
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistence(timeout: 5))

        // Update this card again
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.textFields["Visa"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.swipeDown()
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Cartes Bancaires
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // Pay with this card
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        // Remove this card
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 60.0))
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.buttons["Remove"].waitForExistenceAndTap(timeout: 5))
        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 5))
        confirmRemoval.tap()

        // Card should be removed
        XCTAssertFalse(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
    }

    func testCardBrandChoiceUpdateAndRemove() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.customerMode = .returning
        settings.layout = .horizontal

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        app.buttons["Edit"].waitForExistenceAndTap()

        XCTAssertEqual(app.images.matching(identifier: "carousel_card_cartes_bancaires").count, 1)
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)

        XCTAssertEqual(app.buttons.matching(identifier: "CircularButton.Edit").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap()
        app.otherElements.matching(identifier: "Card Brand Dropdown").firstMatch.waitForExistenceAndTap()
        app.pickerWheels.firstMatch.selectNextOption()
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 3))
        app.buttons["Save"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").element(boundBy: 1).waitForExistenceAndTap()
        app.buttons["Remove"].waitForExistenceAndTap()
        app.alerts.buttons["Remove"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)
        app.buttons["Done"].waitForExistenceAndTap()
    }
}

// MARK: - Helpers
class PaymentSheetStandardLPMUICase: PaymentSheetUITestCase {

}
extension PaymentSheetStandardLPMUICase {
    var webviewAuthorizePaymentButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT") }
    var webviewAuthorizeSetupButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST SETUP") }
    func tapPaymentMethod(_ id: String) {
        guard let pm = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: id) else {
            XCTFail()
            return
        }
        pm.tap()
    }

    /// This waits for the ["PaymentSheetExample" Wants to Use "stripe.com" to Sign In] modal that
    /// `ASWebAuthenticationSession` shows and taps continue to allow the web view to open:
    func waitForASWebAuthSigninModalAndTapContinue() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let sbContinueButton = springboard.buttons["Continue"]
        XCTAssertTrue(sbContinueButton.waitForExistence(timeout: 10.0))
        sbContinueButton.tap()
    }
}

//
//  IntegrationTesterUITests.swift
//  IntegrationTesterUITests
//
//  Created by David Estes on 2/8/21.
//

// If these tests are failing, you may have the iOS Hardware Keyboard enabled.
// You can automate disabling this with:
// killall "Simulator"
// defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false

import IntegrationTesterCommon
import Stripe
import XCTest

enum ConfirmationBehavior {
    // No confirmation needed
    case none
    // authorize a 3DS1 transaction
    case threeDS1
    // authorize a 3DS2 transaction
    case threeDS2
}

class IntegrationTesterUICardEntryTests: IntegrationTesterUITests {
    func testNoAuthenticationCustomCard() throws {
        let cardNumbers = [
            // Main test cards
            "4242424242424242", // visa
            "4000056655665556", // visa (debit)
            "5555555555554444", // mastercard
            "2223003122003222", // mastercard (2-series)
            "5200828282828210", // mastercard (debit)
            "5105105105105100", // mastercard (prepaid)
            "378282246310005",  // amex
            "371449635398431",  // amex
            "6011111111111117", // discover
            "6011000990139424", // discover
            "3056930009020004", // diners club
            "36227206271667",   // diners club (14 digit)
            "3566002020360505", // jcb
            "6200000000000005", // cup

            // Non-US
            "4000000760000002", // br
            "4000001240000000", // ca
            "4000004840008001", // mx
        ]
        for card in cardNumbers {
            testAuthentication(cardNumber: card)
        }
    }
}

class IntegrationTesterUICardTests: IntegrationTesterUITests {

    func testStandardCustomCard3DS2() throws {
        testOOBAuthentication(cardNumber: "4000000000003220")
    }

    let alwaysOobCard = "4000582600000094"
    func testOOB3DS2() throws {
        testOOBAuthentication(cardNumber: alwaysOobCard)
    }

    func testDeclinedCard() throws {
        testAuthentication(cardNumber: "4000000000000002", expectedResult: "declined")
    }

    let alwaysOtpCard = "4000582600000045"
    func testOtp3DS2() throws {
        testOtpAuthentication(cardNumber: alwaysOtpCard)
    }

    let alwaysSingleSelectCard = "4000582600000102"
    func testSingleSelect3DS2() throws {
        testSingleSelectAuthentication(cardNumber: alwaysSingleSelectCard)
    }

    let alwaysMultiSelectCard = "4000582600000110"
    func testMultiSelect3DS2() throws {
        testMultiSelectAuthentication(cardNumber: alwaysMultiSelectCard)
    }

    let hsbcCard = "4000582600000292"
    // TODO(RUN_MOBILESDK-4224): Investigate flakyness
    func disabled_testHSBCHTMLIssue() throws {
        testHSBCWebViewLinksTrigger(cardNumber: hsbcCard)
    }

    let browserFallbackCard = "4000582600000060"
    func testBrowserFallback() throws {
        testBrowserFallbackAuthentication(cardNumber: browserFallbackCard)
    }
}

class IntegrationTesterUIPMTests: IntegrationTesterUITests {

    func testSetupIntents() throws {
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card (SetupIntents)"]
        cardExampleElement.tap()
        try! fillCardData(app, number: "4242424242424242")

        let buyButton = app.buttons["Setup"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "complete!"))
    }

    func testApplePay() throws {
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let applePayElement = tablesQuery.cells.buttons["Apple Pay"]
        applePayElement.tap()
        let applePayButton = app.buttons["Buy with Apple Pay"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 10.0))
        applePayButton.tap()

        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)

        let amexButton = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"]
        XCTAssertTrue(amexButton.waitForExistence(timeout: 10.0))
        amexButton.forceTapElement()

        let mastercardButton = applePay.buttons["Simulated Card - MasterCard, ‪•••• 1234‬"].firstMatch
        XCTAssertTrue(mastercardButton.waitForExistence(timeout: 10.0))
        mastercardButton.forceTapElement()

        let payButton = applePay.buttons["Pay with Passcode"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 10.0))
        payButton.forceTapElement()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 20.0))
        XCTAssertNotNil(statusView.label.range(of: "complete!"))
    }

    // Exercise the ASWebAuthenticationSession flow
    func testASWebAuthUsingPaypal() throws {
        testNoInputIntegrationMethod(.paypal, shouldConfirm: true)
    }

    // Exercise the app to app redirect flow, including Safari
    func testAppToAppRedirectUsingAlipay() throws {
        testAppToAppRedirect(.alipay)
    }

    // Test a standard payment method using SFSafariViewController
    func testSFSafariViewControllerUsingBancontact() throws {
        testNoInputIntegrationMethod(.bancontact, shouldConfirm: true)
    }

    func testAUBECSDebit() {
        return
        // TODO: AU BECS Debit is broken in testmode.
        // The test BSB 000-000 doesn't work. https://stripe.com/docs/payments/au-becs-debit/accept-a-payment#web-test-integration
        //    self.popToMainMenu()
        //
        //    let tablesQuery = app.collectionViews
        //    let rowForPaymentMethod = tablesQuery.cells.buttons["AU BECS Debit"]
        //    rowForPaymentMethod.tap()
        //
        //    XCUIApplication().collectionViews/*@START_MENU_TOKEN@*/.buttons["AU BECS Debit"]/*[[".cells[\"AU BECS Debit\"].buttons[\"AU BECS Debit\"]",".buttons[\"AU BECS Debit\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        //
        //    let nameField = app.textFields["Full name"]
        //    XCTAssertTrue(nameField.waitForExistence(timeout: 10.0))
        //    nameField.tap()
        //    nameField.typeText("Name Nameson")
        //    let emailField = app.textFields["Email"]
        //    emailField.tap()
        //    emailField.typeText("name@example.com")
        //    let bsbField = app.textFields["BSB"]
        //    bsbField.tap()
        //    bsbField.typeText("000000")
        //    let accountNumberField = app.textFields["Account number"]
        //    accountNumberField.tap()
        //    accountNumberField.typeText("000123456")
        //    let buyButton = app.buttons["Buy"]
        //    XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        //    buyButton.forceTapElement()
        //
        //    let webViewsQuery = app.webViews
        //    let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        //    XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        //    completeAuth.forceTapElement()
        //
        //    let statusView = app.staticTexts["Payment status view"]
        //    XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        //    XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }

    func testOxxo() {
        self.popToMainMenu()

        let tablesQuery = app.collectionViews
        let rowForPaymentMethod = tablesQuery.cells.buttons["OXXO"]
        rowForPaymentMethod.scrollToAndTap(in: app)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        let webView = app.webViews.firstMatch
        XCTAssert(webView.waitForExistence(timeout: 10))
        let closeButton = app.buttons["Close"]
        XCTAssert(closeButton.waitForExistence(timeout: 10))
        closeButton.forceTapElement()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }

    func testKlarna() {
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let rowForPaymentMethod = tablesQuery.cells.buttons[IntegrationMethod.klarna.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        // Klarna uses ASWebAuthenticationSession, tap continue to allow the web view to open:
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.buttons["Continue"].waitForExistenceAndTap(timeout: 3)

        // This is where we'd fill out Klarna's forms, but we'll just cancel for now
        app.buttons["Cancel"].waitForExistenceAndTap(timeout: 3)

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment canceled"))
    }

}

class IntegrationTesterUITests: XCTestCase {
    var app: XCUIApplication!
    var appLaunched = false

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        if !appLaunched {
            app.launch()
            appLaunched = true
        }
        popToMainMenu()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNull() throws {
        // Null test to appease XCTestCase
    }

    func popToMainMenu() {
        let menuButton = app.buttons["Integrations"]
        if menuButton.exists {
            menuButton.tap()
        }
    }

    func fillCardData(_ app: XCUIApplication, number: String = "4242424242424242") throws {
        let numberField = app.textFields["card number"]
        XCTAssertTrue(numberField.waitForExistence(timeout: 10.0))
        numberField.tap()
        numberField.typeText(number)
        let expField = app.textFields["expiration date"]
        _ = expField.waitForExistence(timeout: 10)
        expField.typeText("1228")
        let cvcField = app.textFields["CVC"]
        if STPCardValidator.brand(forNumber: number) == .amex {
            cvcField.typeText("1234")
        } else {
            cvcField.typeText("123")
        }
        let postalField = app.textFields["ZIP"]
        postalField.typeText("12345")
    }

    func testAuthentication(cardNumber: String, expectedResult: String = "Payment complete!", confirmationBehavior: ConfirmationBehavior = .none) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        switch confirmationBehavior {
        case .none: break
        case .threeDS1:
            let webViewsQuery = app.webViews
            let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
            XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
            completeAuth.forceTapElement()
        case .threeDS2:
            let completeAuth = app.scrollViews.otherElements.staticTexts["Complete Authentication"]
            XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
            completeAuth.tap()
        }

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: expectedResult))
    }

    func testHSBCWebViewLinksTrigger(cardNumber: String) {
        print("Testing \(cardNumber)")

        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        let oobChallengeScreenPredicate = NSPredicate(format: "label ==[c] 'OTP'")
        let challengeText = app.staticTexts.matching(oobChallengeScreenPredicate).element
        XCTAssertTrue(challengeText.waitForExistence(timeout: 10))
        challengeText.forceTapElement()

        let submitButton = app.buttons["Submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 10.0))
        submitButton.forceTapElement()

        let enterCodePredicate = NSPredicate(format: "placeholderValue CONTAINS[c] 'Enter OTP here'")
        let enterCodeText = app.textFields.matching(enterCodePredicate).element
        XCTAssertTrue(enterCodeText.waitForExistence(timeout: 10))
        enterCodeText.tap()
        enterCodeText.typeText("555555")

        app.handleiOSKeyboardTipIfNeeded()

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 10.0))
        doneButton.forceTapElement()

        let submitCodeButton = app.buttons["Submit"]
        XCTAssertTrue(submitCodeButton.waitForExistence(timeout: 10.0))
        submitCodeButton.forceTapElement()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete!"))
    }

    func testOOBAuthentication(cardNumber: String) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        let oobChallengeScreenPredicate = NSPredicate(format: "label CONTAINS[c] 'This is a test 3D Secure 2 authentication for a transaction, showing an out-of-band (OOB) flow. In live mode, customers may be asked to open their banking app installed on their phone to complete authentication.'")
        let challengeText = app.staticTexts.matching(oobChallengeScreenPredicate).element
        XCTAssertTrue(challengeText.waitForExistence(timeout: 10))

        let completeAuth = app.scrollViews.otherElements.staticTexts["Complete Authentication"]
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.tap()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete!"))
    }

    func testOtpAuthentication(cardNumber: String) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        let challengeScreenPredicate = NSPredicate(format: "label CONTAINS[c] 'This is a test 3D Secure 2 authentication, showing a sample one-time-password (OTP) flow. In live mode, customers may be asked to verify their identify by entering a code sent by their bank to their mobile phone. For this test, enter 424242 to complete authentication, or any other value to fail authentication'")
        let challengeText = app.staticTexts.matching(challengeScreenPredicate).element
        XCTAssertTrue(challengeText.waitForExistence(timeout: 10))

        let verificationOTPTextView = app.scrollViews.otherElements.textFields["Enter your code below:"]
        XCTAssertTrue(verificationOTPTextView.waitForExistence(timeout: 10.0))
        verificationOTPTextView.tap()
        verificationOTPTextView.typeText("424242")

        let completeAuth = app.scrollViews.otherElements.staticTexts["Submit"]
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.tap()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete!"))
    }

    func testSingleSelectAuthentication(cardNumber: String) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        let challengeScreenPredicate = NSPredicate(format: "label CONTAINS[c] 'This is a test 3D Secure 2 authentication for a transaction, showing a sample single-select flow. In live mode, customers may be asked to select a phone number to receive a one-time password.'")
        let challengeText = app.staticTexts.matching(challengeScreenPredicate).element
        XCTAssertTrue(challengeText.waitForExistence(timeout: 10))

        let completeAuth = app.scrollViews.otherElements.staticTexts["Submit"]
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.tap()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete!"))
    }

    func testMultiSelectAuthentication(cardNumber: String) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        let challengeScreenPredicate = NSPredicate(format: "label CONTAINS[c] 'This is a test 3D Secure 2 authentication for a transaction, showing a sample multi-select flow. In live mode, customers may be asked to answer a security question.'")
        let challengeText = app.staticTexts.matching(challengeScreenPredicate).element
        XCTAssertTrue(challengeText.waitForExistence(timeout: 10))

        for button in app.buttons.matching(identifier: "Complete Authentication").allElementsBoundByIndex {
            button.tap()
        }

        let completeAuth = app.scrollViews.otherElements.staticTexts["Submit"]
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.tap()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete!"))
    }

    func testBrowserFallbackAuthentication(cardNumber: String) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let cardExampleElement = tablesQuery.cells.buttons["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 30.0))
        buyButton.forceTapElement()

        let completeButton = app.buttons["COMPLETE"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 30.0))
        completeButton.forceTapElement()

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete!"))
    }

    func testNoInputIntegrationMethod(_ integrationMethod: IntegrationMethod, shouldConfirm: Bool) {
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let rowForPaymentMethod = tablesQuery.cells.buttons[integrationMethod.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        if integrationMethod == .paypal {
            // PayPal uses ASWebAuthenticationSession, tap continue:
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let continueButton = springboard.buttons["Continue"]
            XCTAssertTrue(continueButton.waitForExistence(timeout: 10.0))
            springboard.buttons["Continue"].tap()
        }

        if shouldConfirm {
            let webViewsQuery = app.webViews
            // Sometimes this is a Button, sometimes it's a StaticText. ¯\_(ツ)_/¯
            let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
            XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
            completeAuth.forceTapElement()
        }

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }

    func testAppToAppRedirect(_ integrationMethod: IntegrationMethod) {
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let rowForPaymentMethod = tablesQuery.cells.buttons[integrationMethod.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 15)) // wait for Safari to open
        let webViewsQuery = safari.webViews
        // Sometimes this is a Button, sometimes it's a StaticText. ¯\_(ツ)_/¯
        let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.forceTapElement()

        let safariOpenButton = safari.buttons["Open"]
        XCTAssertTrue(safariOpenButton.waitForExistence(timeout: 30.0))
        if safariOpenButton.exists {
            safariOpenButton.tap()
        }

        _ = app.wait(for: .runningForeground, timeout: 10) // wait to switch back to IntegrationTester

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }

    func testAppToAppRedirectWithoutReturnURL(_ integrationMethod: IntegrationMethod) {
        self.popToMainMenu()
        let tablesQuery = app.collectionViews

        let rowForPaymentMethod = tablesQuery.cells.buttons[integrationMethod.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10)) // wait for Safari to open
        let webViewsQuery = safari.webViews
        // Sometimes this is a Button, sometimes it's a StaticText. ¯\_(ツ)_/¯
        let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.forceTapElement()

        let successful = webViewsQuery.descendants(matching: .any)["Payment successful"].firstMatch
        XCTAssertTrue(successful.waitForExistence(timeout: 60.0))

        sleep(2) // Allow some time for the PaymentIntent state to update on the backend (RUN_MOBILESDK-288)

        app.activate()
        _ = app.wait(for: .runningForeground, timeout: 10) // wait to switch back to IntegrationTester

        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
}

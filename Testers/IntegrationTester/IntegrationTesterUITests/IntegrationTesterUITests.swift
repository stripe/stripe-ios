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
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 30)) // wait for Safari to open, may take a while the first time
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

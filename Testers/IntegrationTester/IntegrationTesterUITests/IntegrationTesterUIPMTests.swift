//
//  IntegrationTesterUIPMTests.swift
//  IntegrationTester
//
//  Created by David Estes on 2/11/26.
//


import IntegrationTesterCommon
import Stripe
import XCTest

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
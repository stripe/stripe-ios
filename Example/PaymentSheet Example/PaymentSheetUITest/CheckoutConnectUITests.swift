//
//  CheckoutConnectUITests.swift
//  PaymentSheet Example
//

import XCTest

/// Pays for pre-created Connect Checkout Sessions through Checkout Elements.
///
/// Sessions are read from `/tmp/connect-validation/cases.json`. Each case provides a client secret and,
/// for direct charges, the connected account that owns the Session.
final class CheckoutConnectUITests: PaymentSheetUITestCase {
    private struct Cases: Decodable {
        struct Case: Decodable {
            let client_secret: String
            let account: String?
        }
        let publishable_key: String
        let cases: [String: Case]
    }

    // MARK: - §1 Direct charges

    func testDirectCard() throws { try pay("direct_card", with: .card("4242424242424242")) }
    func testDirectFee3DS() throws { try pay("direct_fee_3ds", with: .threeDS) }
    func testDirect3DSCancelThenRetry() throws { try pay("direct_3ds_cancel_retry", with: .threeDSCancelThenRetry) }
    func testDirectSavedCard() throws { try pay("direct_saved", with: .saved) }
    func testDirectApplePay() throws { try pay("direct_applepay", with: .applePay) }

    // MARK: - §2 Destination charges

    func testDestinationFeeCard() throws { try pay("dest_fee_card", with: .card("4242424242424242")) }
    func testDestinationTransferAmount3DS() throws { try pay("dest_amount_3ds", with: .threeDS) }
    func testDestinationPercentageFeeSavedCard() throws { try pay("dest_pct_saved", with: .saved) }
    func testDestinationApplePay() throws { try pay("dest_applepay", with: .applePay) }

    // MARK: - §3 Separate charges and transfers

    func testSCTCard() throws { try pay("sct_card", with: .card("4242424242424242")) }
    func testSCT3DS() throws { try pay("sct_3ds", with: .threeDS) }

    // MARK: - Link

    func testDirectLinkWallet() throws { try pay("direct_link_wallet", with: .linkWallet) }
    func testDirectLinkInlineSignup() throws { try pay("direct_link_inline", with: .linkInlineSignup) }

    func testDestinationLinkWallet3DSCancelThenRetry() throws { try pay("dest_link_wallet_3ds", with: .linkWallet3DSCancelThenRetry) }
    func testSCTLinkWallet() throws { try pay("sct_link_wallet", with: .linkWallet) }
    func testDestinationLinkInlineSignup() throws { try pay("dest_link_inline", with: .linkInlineSignup) }

    // MARK: - Helpers

    private enum Flow {
        case card(String)
        case threeDS
        case threeDSCancelThenRetry
        case saved
        case applePay
        case linkWallet
        case linkWallet3DSCancelThenRetry
        case linkInlineSignup
    }

    private func pay(_ name: String, with flow: Flow) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/tmp/connect-validation/cases.json"))
        let cases = try JSONDecoder().decode(Cases.self, from: data)
        let testCase = try XCTUnwrap(cases.cases[name], "Missing case \(name)")

        // Given a pre-created Connect Checkout Session
        var settings = CheckoutPlayground.Settings()
        settings.shippingAddressCollection = false
        settings.automaticTax = false
        switch flow {
        case .applePay, .linkWallet, .linkWallet3DSCancelThenRetry:
            settings.integrationType = .eceOnly
        default:
            break
        }
        settings.linkMode = .native
        app.launchEnvironment["STP_CHECKOUT_CLIENT_SECRET"] = testCase.client_secret
        app.launchEnvironment["STP_CHECKOUT_PUBLISHABLE_KEY"] = cases.publishable_key
        if let account = testCase.account {
            app.launchEnvironment["STP_CHECKOUT_STRIPE_ACCOUNT"] = account
        }
        loadCheckoutPlayground(app, settings)
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))

        // When the customer pays
        let buyButton = app.buttons["checkout_buy_button"]
        switch flow {
        case .card(let number):
            try selectNewCard(number)
            buyButton.scrollToAndTap(in: app)
        case .threeDS:
            try selectNewCard("4000002760003184")
            buyButton.scrollToAndTap(in: app)
            completeChallenge()
        case .threeDSCancelThenRetry:
            try selectNewCard("4000002760003184")
            buyButton.scrollToAndTap(in: app)
            XCTAssertTrue(app.textFields["STDSTextField"].waitForExistence(timeout: 15))
            app.buttons["Cancel"].firstMatch.waitForExistenceAndTap()
            let canceled = app.alerts["Canceled"]
            XCTAssertTrue(canceled.waitForExistence(timeout: 15))
            canceled.buttons["OK"].tap()
            buyButton.scrollToAndTap(in: app)
            completeChallenge()
        case .saved:
            let paymentMethodButton = app.buttons["Select payment method"]
            paymentMethodButton.scrollToAndTap(in: app)
            let savedCard = app.buttons["•••• 4242"].firstMatch
            XCTAssertTrue(savedCard.waitForExistence(timeout: 10))
            savedCard.tap()
            XCTAssertTrue(paymentMethodButton.staticTexts["•••• 4242"].waitForExistence(timeout: 10))
            buyButton.scrollToAndTap(in: app)
        case .applePay:
            let applePayButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Buy with Apple")).firstMatch
            XCTAssertTrue(applePayButton.waitForExistence(timeout: 10))
            applePayButton.tap()
            payWithApplePay(successElement: app.alerts["Success"])
        case .linkWallet:
            let wallet = try startLinkWallet(cardNumber: "4242424242424242")
            XCTAssertTrue(wallet.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pay $")).firstMatch.waitForExistenceAndTap(timeout: 10))
        case .linkWallet3DSCancelThenRetry:
            let wallet = try startLinkWallet(cardNumber: "4000002760003184")
            let payButton = wallet.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pay $")).firstMatch
            XCTAssertTrue(payButton.waitForExistenceAndTap(timeout: 10))
            let challengeCode = app.textFields["STDSTextField"]
            XCTAssertTrue(challengeCode.waitForExistence(timeout: 20))
            XCTAssertTrue(app.buttons["UIButton.Back"].waitForExistenceAndTap())
            XCTAssertTrue(challengeCode.waitForNonExistence(timeout: 10))
            let backButton = app.buttons["UIButton.Back"]
            XCTAssertTrue(backButton.waitForExistence(timeout: 10))
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton)
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: backButton)
            waitForExpectations(timeout: 10)
            payButton.tap()
            completeChallenge()
        case .linkInlineSignup:
            app.buttons["Select payment method"].scrollToAndTap(in: app)
            if !app.textFields["Card number"].waitForExistence(timeout: 2) {
                app.buttons["Add new payment method"].forceTapWhenHittableInTestCase(self)
            }
            try fillCardData(app, cardNumber: "4242424242424242")
            app.stp_dismissKeyboard()
            let linkSignup = app.switches["Save my info for faster checkout with Link"]
            XCTAssertTrue(linkSignup.waitForExistence(timeout: 5))
            if !(linkSignup.isSelected || (linkSignup.value as? String) == "1") {
                linkSignup.tap()
            }
            let phoneField = app.textFields["Phone number"]
            XCTAssertTrue(phoneField.waitForExistenceAndTap(timeout: 5))
            phoneField.typeText("3432353214")
            app.stp_dismissKeyboard()
            app.buttons["Continue"].forceTapWhenHittableInTestCase(self)
            XCTAssertTrue(app.buttons["Select payment method"].staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "4242")).firstMatch.waitForExistence(timeout: 10))
            buyButton.scrollToAndTap(in: app)
        }

        // Then Checkout completes
        let success = app.alerts["Success"]
        if !success.waitForExistence(timeout: 30) {
            let failure = app.alerts.firstMatch
            XCTFail("Expected success for \(name), got alert: \(failure.exists ? failure.label + " " + failure.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ") : "none")")
            return
        }
        XCTAssertTrue(success.staticTexts["Payment status: .paid"].exists, name)
    }

    private func selectNewCard(_ number: String) throws {
        app.buttons["Select payment method"].scrollToAndTap(in: app)
        if !app.textFields["Card number"].waitForExistence(timeout: 2) {
            app.buttons["Add new payment method"].forceTapWhenHittableInTestCase(self)
        }
        if !app.textFields["Card number"].waitForExistence(timeout: 2) {
            app.buttons["+ Add"].forceTapWhenHittableInTestCase(self)
        }
        try fillCardData(app, cardNumber: number)
        app.stp_dismissKeyboard()
        // The platform has Link enabled, and inline signup is preselected and needs a phone number.
        let linkSignup = app.switches["Save my info for faster checkout with Link"]
        if linkSignup.waitForExistence(timeout: 2), linkSignup.isSelected || (linkSignup.value as? String) == "1" {
            linkSignup.tap()
        }
        app.buttons["Continue"].forceTapWhenHittableInTestCase(self)
        if !app.staticTexts["•••• \(number.suffix(4))"].waitForExistence(timeout: 10) {
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.lifetime = .keepAlways
            add(screenshot)
            XCTFail("Card was not selected")
        }
    }

    private func startLinkWallet(cardNumber: String) throws -> XCUIElement {
        let linkButton = app.buttons["Pay with Link"]
        XCTAssertTrue(linkButton.waitForExistence(timeout: 10))
        linkButton.tap()
        fillOutLinkSignup(app, email: "link_checkout+\(UUID().uuidString)@link.com")
        app.otherElements["Stripe.Link.PaymentMethodPicker"].waitForExistenceAndTap(timeout: 10)
        app.buttons["Add a payment method"].waitForExistenceAndTap()
        app.buttons["Debit or credit card"].waitForExistenceAndTap()
        fillOutLinkCardData(app, cardNumber: cardNumber, cvc: "123", includingBillingDetails: false)
        return app.otherElements["Stripe.Link.PayWithLinkViewController"]
    }

    private func completeChallenge() {
        let challengeCodeTextField = app.textFields["STDSTextField"]
        XCTAssertTrue(challengeCodeTextField.waitForExistenceAndTap(timeout: 15))
        challengeCodeTextField.typeText("424242" + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(app.buttons["Submit"].waitForExistenceAndTap())
    }
}

import XCTest

final class CheckoutGuideUITests: PaymentSheetUITestCase {
    func testSwiftUISheet() throws { try completeCardCheckout(scenario: "sheet") }
    func testUIKitSheet() throws { try completeCardCheckout(scenario: "uikit-sheet") }
    func testSwiftUIEmbedded() throws { try completeCardCheckout(scenario: "embedded") }
    func testUIKitEmbedded() throws { try completeCardCheckout(scenario: "uikit-embedded") }

    func testEditableEmail() throws {
        launchGuide("email")
        try supplyShippingAndCard(embedded: false)
        // The guide says email is required, but its Pay predicate does not check it.
        XCTAssertTrue(app.buttons["guide_pay"].isEnabled)
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        let alert = app.alerts["Guide result"]
        XCTAssertTrue(alert.waitForExistence(timeout: 30))
        XCTAssertFalse(alert.staticTexts["Payment status: .paid"].exists)
        print("GUIDE_MISSING_EMAIL: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        app.alerts.buttons["OK"].tap()
        enterValidEmail()
        // A failed confirmation or a subsequent update may require reselection;
        // inspect and follow the rendered control instead of tapping disabled Pay.
        if app.buttons["guide_payment"].label == "Select payment method" {
            app.buttons["guide_payment"].scrollToAndTap(in: app)
            let number = app.textFields["Card number"]
            if !number.waitForExistence(timeout: 2) { app.buttons["Card"].scrollToAndTap(in: app) }
            attachScreen("Card form after email update")
            if !(number.value as? String ?? "").contains("4242") {
                try fillCardData(app, cardNumber: "4242424242424242", disableDefaultOptInIfNeeded: true)
            }
            let save = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "Save my info")).firstMatch
            if save.exists && save.isSelected { save.tap() }
            if app.keyboards.firstMatch.exists { app.stp_dismissKeyboard() }
            app.buttons["Continue"].scrollToAndTap(in: app)
        }
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        XCTAssertTrue(app.alerts["Guide result"].staticTexts["Payment status: .paid"].waitForExistence(timeout: 30))
    }

    func testEmailUpdatePreservesCard() throws {
        try checkEmailUpdate(scenario: "email")
    }

    func testEmailUpdatePreservesCardWithoutLink() throws {
        try checkEmailUpdate(scenario: "email-no-link")
    }

    private func checkEmailUpdate(scenario: String) throws {
        launchGuide(scenario)
        try supplyShippingAndCard(embedded: false)
        let selection = app.buttons["guide_payment"].label
        enterValidEmail()
        attachScreen("Email update \(scenario)")
        XCTAssertEqual(app.buttons["guide_payment"].label, selection, "Updating checkout email must preserve the entered card")
    }

    private func enterValidEmail() {
        let field = app.textFields["Checkout email"]
        field.scrollToAndTap(in: app)
        field.typeText("guide-fresh@example.com" + XCUIKeyboardKey.return.rawValue)
        XCTAssertEqual(field.value as? String, "guide-fresh@example.com")
        app.buttons["Update email"].scrollToAndTap(in: app)
        attachScreen("Valid checkout email supplied")
    }

    func testDeclineAndRetry() throws {
        launchGuide("sheet")
        try supplyShippingAndCard(embedded: false, card: "4000000000009995")
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        let alert = app.alerts["Guide result"]
        XCTAssertTrue(alert.waitForExistence(timeout: 30))
        print("GUIDE_DECLINE: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        XCTAssertFalse(alert.staticTexts["Payment status: .paid"].exists)
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["guide_payment"].isEnabled)
        app.buttons["guide_payment"].scrollToAndTap(in: app)
        let number = app.textFields["Card number"]
        if !number.waitForExistence(timeout: 2) { app.buttons["Card"].scrollToAndTap(in: app) }
        number.forceTapWhenHittableInTestCase(self)
        number.clearText()
        try fillCardData(app, cardNumber: "4242424242424242", disableDefaultOptInIfNeeded: true)
        if app.keyboards.firstMatch.exists { app.stp_dismissKeyboard() }
        app.buttons["Continue"].forceTapWhenHittableInTestCase(self)
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        XCTAssertTrue(app.alerts["Guide result"].staticTexts["Payment status: .paid"].waitForExistence(timeout: 30))
    }

    func testExpressApplePay() throws {
        launchGuide("sheet")
        supplyShipping()
        let applePay = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Buy with Apple")).firstMatch
        XCTAssertTrue(applePay.waitForExistenceAndTap(timeout: 10))
        payWithApplePay(successElement: app.alerts["Express result"])
        XCTAssertTrue(app.alerts["Express result"].staticTexts["Payment status: .paid"].exists)
    }

    func testDelayedSEPA() throws {
        launchGuide("sepa")
        supplyShipping()
        app.buttons["guide_payment"].scrollToAndTap(in: app)
        // A Session scoped to one method opens its form directly.
        app.textFields["Full name"].waitForExistenceAndTap()
        app.typeText("Jenny Rosen")
        XCTAssertEqual(app.textFields["Email"].value as? String, "jenny.rosen@example.com")
        app.textFields["IBAN"].forceTapWhenHittableInTestCase(self)
        app.typeText("AT321904300235473204")
        app.fillAddressWithAutocomplete()
        if app.keyboards.firstMatch.exists { app.stp_dismissKeyboard() }
        app.buttons["Continue"].scrollToAndTap(in: app)
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        if app.buttons["Confirm"].waitForExistence(timeout: 3) { app.buttons["Confirm"].tap() }
        XCTAssertTrue(app.alerts["Guide result"].waitForExistence(timeout: 30))
        print("GUIDE_SEPA: \(app.alerts["Guide result"].staticTexts.allElementsBoundByIndex.map(\.label))")
        attachScreen("SEPA result")
        XCTAssertTrue(app.alerts["Guide result"].staticTexts["Payment status: .unpaid"].exists)
    }

    func testAuthentication() throws {
        launchGuide("sheet")
        try supplyShippingAndCard(embedded: false, card: "4000002500003155")
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        // This guide test card presents the web 3DS challenge, not the native
        // challenge used by the playground's 3184 card.
        XCTAssertTrue(app.buttons["COMPLETE"].waitForExistenceAndTap(timeout: 20))
        XCTAssertTrue(app.staticTexts["Authentication Complete"].waitForExistence(timeout: 15))
        // The test authentication page explicitly says to close this window.
        app.buttons["Close"].waitForExistenceAndTap()
        XCTAssertTrue(app.alerts["Guide result"].staticTexts["Payment status: .paid"].waitForExistence(timeout: 30))
        attachScreen("Authentication outcome")
    }

    func testReturnFromOrderDetailsPreservesSelection() throws {
        try checkReturnFromOrderDetails(scenario: "navigation")
    }

    func testReturnFromOrderDetailsWithLoadGuard() throws {
        try checkReturnFromOrderDetails(scenario: "navigation-fixed")
    }

    private func checkReturnFromOrderDetails(scenario: String) throws {
        launchGuide(scenario)
        let sessionID = app.staticTexts["guide_total"].value as? String
        try supplyShippingAndCard(embedded: false)
        XCTAssertTrue(app.buttons["guide_pay"].isEnabled)
        app.buttons["Order details"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Merchant order details"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        // Wait for a possible reload instead of only checking the first frame on return.
        let lostSelection = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Select payment method"),
            object: app.buttons["guide_payment"]
        )
        let observed = XCTWaiter.wait(for: [lostSelection], timeout: 10)
        attachScreen("Returned from order details \(scenario)")
        XCTAssertEqual(app.staticTexts["guide_total"].value as? String, sessionID)
        XCTAssertEqual(observed, .timedOut, "Returning to checkout must not reload away the customer's selected payment method")
        XCTAssertTrue(app.buttons["guide_pay"].isEnabled)
    }

    func testCurrencySelector() {
        launchGuide("currency")
        XCTAssertTrue(app.staticTexts["guide_total"].label.contains("€"))
        app.buttons["currency_option_usd"].waitForExistenceAndTap()
        expectation(for: NSPredicate(format: "label == %@", "Total $50.00"), evaluatedWith: app.staticTexts["guide_total"])
        waitForExpectations(timeout: 10)
        app.buttons["currency_option_eur"].waitForExistenceAndTap()
        expectation(for: NSPredicate(format: "label CONTAINS %@", "€"), evaluatedWith: app.staticTexts["guide_total"])
        waitForExpectations(timeout: 10)
        attachScreen("Currency selector updated total")
    }

    private func attachScreen(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launchGuide(_ scenario: String) {
        app.launchEnvironment["STP_CHECKOUT_GUIDE"] = scenario
        app.launch()
        XCTAssertTrue(app.staticTexts["guide_total"].waitForExistence(timeout: 30))
        if scenario != "sepa" && scenario != "currency" { XCTAssertEqual(app.staticTexts["guide_total"].label, "Total $50.00") }
        attachScreen("Loaded \(scenario)")
    }

    private func completeCardCheckout(scenario: String) throws {
        launchGuide(scenario)
        try supplyShippingAndCard(embedded: scenario.contains("embedded"))
        attachScreen("Ready \(scenario)")
        app.buttons["guide_pay"].scrollToAndTap(in: app)
        XCTAssertTrue(app.alerts["Guide result"].staticTexts["Payment status: .paid"].waitForExistence(timeout: 30))
    }

    private func supplyShippingAndCard(embedded: Bool, card: String = "4242424242424242") throws {
        supplyShipping()
        try supplyCard(embedded: embedded, card: card)
    }

    private func supplyShipping() {
        app.buttons["Add shipping address"].scrollToAndTap(in: app)
        app.textFields["Full name"].waitForExistenceAndTap()
        app.typeText("Jane Doe")
        app.textFields["Address"].waitForExistenceAndTap()
        app.buttons["Enter address manually"].waitForExistenceAndTap()
        app.textFields["Address line 1"].waitForExistenceAndTap()
        app.typeText("510 Townsend St")
        app.textFields["City"].tap()
        app.typeText("San Francisco")
        app.textFields["State"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        if app.keyboards.firstMatch.exists { app.stp_dismissKeyboard() }
        app.buttons["Save address"].forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["510 Townsend St"].waitForExistence(timeout: 10))
    }

    private func supplyCard(embedded: Bool, card: String) throws {
        if embedded {
            app.buttons["Card"].scrollToAndTap(in: app)
        } else {
            app.buttons["guide_payment"].scrollToAndTap(in: app)
        }
        if !app.textFields["Card number"].waitForExistence(timeout: 2) {
            app.buttons["Card"].scrollToAndTap(in: app)
        }
        try fillCardData(app, cardNumber: card, disableDefaultOptInIfNeeded: true)
        if app.keyboards.firstMatch.exists { app.stp_dismissKeyboard() }
        app.buttons["Continue"].forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.buttons["guide_pay"].waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["guide_pay"])
        waitForExpectations(timeout: 10)
    }
}

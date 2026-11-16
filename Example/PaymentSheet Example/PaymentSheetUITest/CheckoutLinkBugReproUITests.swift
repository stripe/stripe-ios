//
//  CheckoutLinkBugReproUITests.swift
//  PaymentSheetUITest
//
//  Created by George Birch on 11/16/26.
//

import XCTest

final class CheckoutLinkBugReproUITests: PaymentSheetUITestCase {

    func testLinkInlineSignupStartsUncheckedWhenMerchantDisablesDefaultOptIn() throws {
        // Keep going after the first failure so the run reports both the checkbox and Continue button states.
        continueAfterFailure = true

        // Given a guest Checkout Session without an email, for the US merchant whose mobile Link default opt-in is disabled
        app.launchEnvironment["STP_CHECKOUT_ELEMENTS"] = "true"
        app.launch()

        app.buttons["Reset"].waitForExistenceAndTap()
        // Guest is the default customer. Clear the default session email so Link inline signup is offered.
        XCTAssertTrue(app.buttons["checkout_picker_Email"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["None"].waitForExistenceAndTap())
        XCTAssertTrue(app.textFields["checkout_email_value"].waitForNonExistence(timeout: 5))
        // Drag along the leading edge so the gesture never starts on a text field or a control.
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.25))
        scrollStart.press(forDuration: 0.1, thenDragTo: scrollEnd)
        // Hide the save-card checkbox, so the card form shows the Link signup checkbox.
        // Shipping collection is on by default, so Automatic Tax uses the shipping address and leaves Link enabled.
        let offerSaveToggle = app.switches["Payment Method Offer Save"]
        offerSaveToggle.scrollToAndTap(in: app)
        XCTAssertEqual(offerSaveToggle.value as? String, "0")
        XCTAssertTrue(app.buttons["Create Checkout Session"].waitForExistenceAndTap())
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))

        // When the customer opens the Payment Element card form and enters card details
        app.buttons["Select payment method"].scrollToAndTap(in: app)
        let cardRow = app.buttons["Card"]
        if cardRow.waitForExistence(timeout: 10) {
            cardRow.tap()
        }
        try fillCardData(app)

        // Then the Link signup checkbox starts unchecked, matching PaymentSheet for the same merchant,
        // and the card details alone are enough to continue.
        let linkSignupSwitch = app.switches["Save my info for faster checkout with Link"]
        XCTAssertTrue(linkSignupSwitch.waitForExistence(timeout: 10))
        XCTAssertFalse(linkSignupSwitch.isSelected, "Link signup must not be pre-checked")
        app.stp_dismissKeyboard()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Continue"].isEnabled, "Card details alone should enable Continue")
    }

    // MARK: - Bank linking in $0 Checkout Sessions

    func testZeroAmountCheckoutLinkBankRowOpensFinancialConnections() throws {
        // Given a $0 "Free T-Shirt" Checkout Session with card and Link
        // When the customer taps the Bank row in the Payment Element and taps Continue
        zeroAmountBankTapContinueOnBankRow(cartScenario: .zeroAmount)

        // Then Financial Connections opens on its consent screen, and no linking error is shown
        zeroAmountBankAssertFinancialConnectionsOpened()
    }

    func testStandardCheckoutLinkBankRowOpensFinancialConnections() throws {
        // Given a paid Checkout Session with card and Link, as a control for the $0 test above
        // When the customer taps the Bank row in the Payment Element and taps Continue
        zeroAmountBankTapContinueOnBankRow(cartScenario: .standard)

        // Then Financial Connections opens on its consent screen, and no linking error is shown
        zeroAmountBankAssertFinancialConnectionsOpened()
    }

    /// Creates a guest card + Link Checkout Session for the given cart, opens the Payment Element with the
    /// "view" presentation, and taps Continue on the Bank row's form.
    private func zeroAmountBankTapContinueOnBankRow(cartScenario: CheckoutPlayground.CartScenario) {
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .embedded
        settings.cartScenario = cartScenario
        settings.automaticPaymentMethods = false
        settings.paymentMethodTypes = ["card", "link"]
        // A fresh session email is a new Link consumer, so no Link account is signed in.
        settings.email = .init(source: .checkoutSession, value: "link_repro+\(UUID().uuidString)@example.com")
        // Shipping and tax are not needed to open the bank form.
        settings.shippingAddressCollection = false
        settings.automaticTax = false
        loadCheckoutPlayground(app, settings)
        XCTAssertTrue(app.buttons["Create Checkout Session"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))

        // The "view" presentation opens a screen that hosts the Payment Element's vertical list.
        app.buttons["Select payment method"].scrollToAndTap(in: app)
        let bankRow = app.buttons["Bank"]
        XCTAssertTrue(bankRow.waitForExistence(timeout: 10))
        bankRow.scrollToAndTap(in: app)
        // The session email fills the bank form, so Continue starts linking right away.
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
    }

    /// Asserts that Financial Connections opened, rather than the form showing its bank linking error.
    private func zeroAmountBankAssertFinancialConnectionsOpened() {
        let linkFailureLabel = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS 'Something went wrong when linking your account'"))
            .firstMatch
        let consentButton = app.buttons["Agree and continue"]
        // Wait until either the Financial Connections consent screen or the form's error appears.
        let deadline = Date().addingTimeInterval(20)
        while !consentButton.exists, !linkFailureLabel.exists, Date() < deadline {
            _ = consentButton.waitForExistence(timeout: 1)
        }
        XCTAssertFalse(linkFailureLabel.exists, "The bank form shows: \(linkFailureLabel.label)")
        XCTAssertTrue(consentButton.exists, "Financial Connections should open on its consent screen")
    }

    // MARK: - Adding a bank inside native Link

    func testNativeLinkWalletAddBankOpensFinancialConnections() throws {
        // Given a card + Link Checkout Session that shows only the Express Checkout Element, with native Link
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .eceOnly
        settings.automaticPaymentMethods = false
        settings.paymentMethodTypes = ["card", "link"]
        settings.linkMode = .native
        // With no session email, the Link button starts Link signup for a new customer.
        settings.email = .init(source: .none)
        // Shipping and tax are not needed to open the Link wallet.
        settings.shippingAddressCollection = false
        settings.automaticTax = false
        loadCheckoutPlayground(app, settings)
        XCTAssertTrue(app.buttons["Create Checkout Session"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))

        // ...and a new customer who taps the Link button and signs up for Link
        XCTAssertTrue(app.buttons["Pay with Link"].waitForExistenceAndTap(timeout: 10))
        fillOutLinkSignup(app, email: "link_repro+\(UUID().uuidString)@example.com")

        // When the customer opens the wallet's payment picker, taps "Add a payment method", and chooses Bank
        XCTAssertTrue(app.otherElements["Stripe.Link.PaymentMethodPicker"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.buttons["Add a payment method"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["Bank"].waitForExistenceAndTap())

        // Then Financial Connections opens on its consent screen
        XCTAssertTrue(
            app.buttons["Agree and continue"].waitForExistence(timeout: 20),
            "Financial Connections should open after choosing Bank in the Link wallet"
        )
    }

    // MARK: - Opening native Link replacing the Payment Element's selection

    func testClosingNativeLinkOpenedFromLinkRowKeepsLinkSelected() throws {
        // Keep going after the first failure so the run also shows what tapping Buy again opens.
        continueAfterFailure = true

        // Given a card + Link Checkout Session in the "view" Payment Element presentation, with the
        // playground's default native Link mode and Apple Pay
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .embedded
        settings.automaticPaymentMethods = false
        settings.paymentMethodTypes = ["card", "link"]
        settings.linkMode = .native
        settings.applePayEnabled = true
        // A new Customer has no remembered selection, so Payment Element's hidden FlowController starts on Apple Pay.
        // Guests share one remembered selection, which becomes Link once any guest taps the Link row.
        settings.customerType = .new
        // With no session email, Link opens on its signup screen, so the customer can close it without logging in.
        settings.email = .init(source: .none)
        // Shipping and tax are not needed, and Automatic Tax without a shipping address would turn off Link.
        settings.shippingAddressCollection = false
        settings.automaticTax = false
        // Hide the Express Checkout Element, so the Payment Element's Link row is the only way into Link.
        settings.expressCheckoutElement.isEnabled = false
        loadCheckoutPlayground(app, settings)
        XCTAssertTrue(app.buttons["Create Checkout Session"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))

        // ...and the customer selects the Link row in the Payment Element
        let paymentMethodButton = app.buttons["Select payment method"]
        paymentMethodButton.scrollToAndTap(in: app)
        XCTAssertTrue(app.buttons["Link"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.buttons["Done"].waitForExistenceAndTap())
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10))
        XCTAssertTrue(
            (paymentMethodButton.value as? String)?.hasPrefix("Link") ?? false,
            "Precondition: the cart should show Link, got \(paymentMethodButton.value ?? "nil")"
        )

        // When the customer taps Buy, which opens native Link, and closes Link without logging in
        let buyButton = app.buttons["checkout_buy_button"]
        buyButton.scrollToAndTap(in: app)
        let linkEmailField = app.textFields["Email"]
        XCTAssertTrue(linkEmailField.waitForExistence(timeout: 10), "Buy should open native Link's signup screen")
        XCTAssertTrue(app.buttons["UIButton.Close"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(linkEmailField.waitForNonExistence(timeout: 10))

        // Then the cart still shows Link as the payment method
        XCTAssertTrue(
            (paymentMethodButton.value as? String)?.hasPrefix("Link") ?? false,
            "After closing Link, the cart shows \(paymentMethodButton.value ?? "nil")"
        )

        // ...and tapping Buy again opens Link again, instead of the Apple Pay sheet
        buyButton.scrollToAndTap(in: app)
        XCTAssertTrue(linkEmailField.waitForExistence(timeout: 10), "Tapping Buy again did not open Link")
    }

    // MARK: - Linked bank dropped by Checkout session updates

    func testLinkedBankStaysSelectedAfterContinueWithBillingAutomaticTax() throws {
        // Keep going after the first failure so the run also shows what the cart ends up with.
        continueAfterFailure = true

        // Given a card + Link Checkout Session with Automatic Tax and no shipping collection, so tax comes from the
        // billing address, and the playground's US test address as the default billing address
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .embedded
        settings.automaticPaymentMethods = false
        settings.paymentMethodTypes = ["card", "link"]
        // A fresh session email makes the Bank row available, and is a new Link consumer in Financial Connections.
        settings.email = .init(source: .checkoutSession, value: "link_repro+\(UUID().uuidString)@example.com")
        settings.checkoutSessionPaymentMethodSave = false
        settings.shippingAddressCollection = false
        settings.automaticTax = true
        settings.defaultBillingAddressOption = .usTestAddress
        settings.expressCheckoutElement.isEnabled = false
        loadCheckoutPlayground(app, settings)
        XCTAssertTrue(app.buttons["Create Checkout Session"].waitForExistenceAndTap(timeout: 10))
        guard app.navigationBars["Your Cart"].waitForExistence(timeout: 30) else {
            XCTFail("The cart did not open. Texts shown: \(app.staticTexts.allElementsBoundByIndex.prefix(6).map(\.label))")
            return
        }

        // ...and the customer links the test bank from the Payment Element's Bank row
        let paymentMethodButton = app.buttons["Select payment method"]
        paymentMethodButton.scrollToAndTap(in: app)
        let bankRow = app.buttons["Bank"]
        XCTAssertTrue(bankRow.waitForExistence(timeout: 10))
        bankRow.scrollToAndTap(in: app)
        // The session email and the default billing address fill the bank form, so Continue starts linking.
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
        linkedBankDroppedLinkTestBank()
        XCTAssertTrue(app.staticTexts["••••6789"].waitForExistence(timeout: 15), "The bank form should show the linked bank")

        // When the customer taps Continue, which sends the billing address to Checkout for tax before closing the form
        sleep(2) // Wait for Financial Connections to finish dismissing.
        XCTAssertTrue(continueButton.waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(continueButton.waitForNonExistence(timeout: 15), "The bank form should close")

        // Then the Bank row stays selected...
        let selectedBankRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Bank' AND isSelected == true")).firstMatch
        XCTAssertTrue(selectedBankRow.waitForExistence(timeout: 5), "The Bank row should stay selected after Continue")
        let afterContinueScreenshot = XCTAttachment(screenshot: app.screenshot())
        afterContinueScreenshot.name = "Payment Element after Continue"
        afterContinueScreenshot.lifetime = .keepAlways
        add(afterContinueScreenshot)

        // ...and the cart shows the linked bank as the payment method
        XCTAssertTrue(app.buttons["Done"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10))
        XCTAssertTrue(
            (paymentMethodButton.value as? String)?.contains("6789") ?? false,
            "After Continue, the cart shows \(paymentMethodButton.value ?? "nil")"
        )
    }

    /// Steps through Financial Connections' native flow for a new Link consumer and links the "Success" test
    /// institution. Unlike `stepThroughNativeInstantDebitsFlow`, this keeps the phone number's default US country
    /// code instead of picking it from a picker wheel, which this simulator doesn't show.
    private func linkedBankDroppedLinkTestBank() {
        // "Consent" pane
        XCTAssertTrue(app.buttons["Agree and continue"].waitForExistenceAndTap(timeout: 20))

        // "Sign Up" pane: the session email is prefilled, so only a phone number is needed.
        let phoneTextField = app.textFields["phone_text_field"]
        XCTAssertTrue(phoneTextField.waitForExistence(timeout: 10), "Failed to find phone text field")
        phoneTextField.tap()
        phoneTextField.typeText("4015006000")
        XCTAssertTrue(app.buttons["link_login.primary_button"].waitForExistenceAndTap(timeout: 10))

        // "Institution picker" pane
        XCTAssertTrue(app.tables.cells.staticTexts["Success"].waitForExistenceAndTap(timeout: 60))

        // "Account picker" pane, then the "Success" pane
        XCTAssertTrue(app.buttons["connect_accounts_button"].waitForExistenceAndTap(timeout: 120))
        XCTAssertTrue(app.buttons["success_done_button"].waitForExistenceAndTap(timeout: 120))
    }

    // MARK: - Native Link card picked in the Payment Element sheet, then a session update

    func testNativeLinkCardStaysSelectedInSheetAfterSavingShippingAddress() throws {
        // Keep going after the first failure so the run also shows what tapping Buy does.
        continueAfterFailure = true

        // Given a card + Link Checkout Session in the "sheet" Payment Element presentation, with native Link and
        // no Apple Pay. Two payment method types give the sheet its horizontal layout, with Link in its header.
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .flowController
        settings.automaticPaymentMethods = false
        settings.paymentMethodTypes = ["card", "link"]
        settings.linkMode = .native
        settings.applePayEnabled = false
        // A fresh session email is a new Link customer, who signs up inside native Link.
        settings.email = .init(source: .checkoutSession, value: "link_repro+\(UUID().uuidString)@example.com")
        // Collect a shipping address without tax, so saving one only updates the session locally.
        settings.shippingAddressCollection = true
        settings.automaticTax = false
        settings.expressCheckoutElement.isEnabled = false
        loadCheckoutPlayground(app, settings)
        XCTAssertTrue(app.buttons["Create Checkout Session"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 30))

        // ...and the customer opens the sheet, taps Link, signs up with the session email and a phone number,
        // adds a Mastercard in Link, and taps Continue
        let paymentMethodButton = app.buttons["Select payment method"]
        paymentMethodButton.scrollToAndTap(in: app)
        XCTAssertTrue(app.buttons["Pay with Link"].waitForExistenceAndTap(timeout: 10))
        let linkSheet = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let phoneField = linkSheet.textFields["Phone number"]
        XCTAssertTrue(phoneField.waitForExistenceAndTap(timeout: 10), "Link should open on its signup screen")
        phoneField.typeText("3432353214")
        linkSheet.buttons["Continue"].forceTapWhenHittableInTestCase(self)
        // The new Link account's wallet is empty, so add a card. Link asks whether to add a bank or a card.
        let addPaymentMethodButton = app.buttons["Add a payment method"]
        if !addPaymentMethodButton.waitForExistence(timeout: 15) {
            app.otherElements["Stripe.Link.PaymentMethodPicker"].waitForExistenceAndTap(timeout: 5)
        }
        addPaymentMethodButton.forceTapWhenHittableInTestCase(self)
        let cardAction = app.buttons["Debit or credit card"]
        if cardAction.waitForExistence(timeout: 5) {
            cardAction.tap()
        }
        XCTAssertTrue(app.textFields["Card number"].waitForExistence(timeout: 15), "Link should show its card form")
        try fillCardData(app, cardNumber: "5555555555554444")
        app.stp_dismissKeyboard()
        let continueButton = linkSheet.buttons["Continue"]
        continueButton.forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(linkSheet.waitForNonExistence(timeout: 20), "Link should close after Continue")
        let linkCardSelected = NSPredicate(format: "value BEGINSWITH 'Link' AND value CONTAINS '4444'")
        expectation(for: linkCardSelected, evaluatedWith: paymentMethodButton, handler: nil)
        waitForExpectations(timeout: 10)
        let selectedLinkCard = paymentMethodButton.value as? String
        let beforeUpdateScreenshot = XCTAttachment(screenshot: app.screenshot())
        beforeUpdateScreenshot.name = "Cart after picking a Link card"
        beforeUpdateScreenshot.lifetime = .keepAlways
        add(beforeUpdateScreenshot)

        // When the customer saves a shipping address in the Shipping Address Element
        app.buttons["Add shipping address"].scrollToAndTap(in: app)
        horizontalLinkSelectionFillShippingAddress()
        // Close the keyboard, which covers the Save Address button.
        app.stp_dismissKeyboard()
        app.buttons["Save Address"].forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["510 Townsend St"].waitForExistence(timeout: 10), "The cart should show the saved address")

        // Then the cart still shows the Link card the customer picked
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 5))
        XCTAssertEqual(
            paymentMethodButton.value as? String,
            selectedLinkCard,
            "After saving the address, the cart shows \(paymentMethodButton.value ?? "nil")"
        )
        let afterUpdateScreenshot = XCTAttachment(screenshot: app.screenshot())
        afterUpdateScreenshot.name = "Cart after saving a shipping address"
        afterUpdateScreenshot.lifetime = .keepAlways
        add(afterUpdateScreenshot)

        // ...and tapping Buy pays with it
        app.buttons["checkout_buy_button"].scrollToAndTap(in: app)
        let successAlert = app.alerts["Success"]
        if !successAlert.waitForExistence(timeout: 20) {
            let shownAlert = app.alerts.firstMatch
            XCTFail(
                "Buy did not complete the payment. Alert: \(shownAlert.exists ? shownAlert.label : "none"), "
                + "message: \(shownAlert.staticTexts.allElementsBoundByIndex.map(\.label))"
            )
        }
    }

    /// Fills in the Shipping Address Element with a San Francisco address.
    private func horizontalLinkSelectionFillShippingAddress() {
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
    }
}

//
//  CheckoutSessionUITests.swift
//  PaymentSheet Example
//

import XCTest

class CheckoutSessionUITests: PaymentSheetUITestCase {

    // MARK: - Helpers

    private func checkoutSessionSettings(
        uiStyle: PaymentSheetTestPlaygroundSettings.UIStyle,
        layout: PaymentSheetTestPlaygroundSettings.Layout = .horizontal,
        customerMode: PaymentSheetTestPlaygroundSettings.CustomerMode = .guest
    ) -> PaymentSheetTestPlaygroundSettings {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = uiStyle
        settings.layout = layout
        settings.integrationType = .checkoutSession
        settings.mode = .payment
        settings.customerMode = customerMode
        settings.customerKeyType = .customerSession
        settings.paymentMethodSave = .enabled
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkDisplay = .never
        if uiStyle == .embedded {
            settings.formSheetAction = .continue
        }
        return settings
    }

    private func assertBillingAddressEmpty(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            checkoutBillingAddressElement.waitForExistence(timeout: 10),
            "Checkout billing address debug element never appeared",
            file: file,
            line: line
        )
        XCTAssertNil(
            checkoutBillingAddress["country"],
            "Expected empty checkout billing address, got: \(checkoutBillingAddress)",
            file: file,
            line: line
        )
    }

    /// Saves card(s) with full default billing, then reloads so the next session starts with empty billing.
    private func saveCardsAndReloadFreshCheckoutSession(
        settings: inout PaymentSheetTestPlaygroundSettings,
        cardNumbers: [String] = ["4242424242424242"]
    ) throws {
        settings.customerMode = .new
        settings.uiStyle = .flowController
        if settings.layout != .vertical {
            settings.layout = .horizontal
        }
        // Full billing + defaults so the saved PM keeps country/line1/postal for dismiss-sync tests
        settings.defaultBillingAddress = .on
        settings.attachDefaults = .on
        settings.collectAddress = .full
        settings.collectName = .always
        loadPlayground(app, settings)

        for (index, cardNumber) in cardNumbers.enumerated() {
            if index > 0 {
                reload(app, settings: settings)
            }
            app.buttons["Payment method"].waitForExistenceAndTap()
            if settings.layout == .vertical {
                if index == 0 {
                    app.buttons["Card"].waitForExistenceAndTap()
                } else {
                    app.buttons["New card"].waitForExistenceAndTap()
                }
            } else {
                app.buttons["+ Add"].waitForExistenceAndTap()
                app.buttons["Card"].waitForExistenceAndTap()
            }

            // Defaults fill name/address; just enter card number / expiry / CVC
            let numberField = app.textFields["Card number"]
            numberField.forceTapWhenHittableInTestCase(self)
            app.typeText(cardNumber)
            app.typeText("1228") // Expiry
            app.typeText("123") // CVC
            app.stp_dismissKeyboard()

            let saveToggle = app.switches.containing(NSPredicate(format: "label CONTAINS[c] 'Save'")).firstMatch
            if saveToggle.waitForExistence(timeout: 2), !saveToggle.isSelected {
                saveToggle.tap()
            }

            app.buttons["Continue"].waitForExistenceAndTap()
            waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")

            let confirmButton = app.buttons["Confirm"]
            confirmButton.forceTapWhenHittableInTestCase(self)
            XCTAssertTrue(
                app.staticTexts["Success!"].waitForExistence(timeout: 15),
                "Confirm did not succeed after saving card \(cardNumber)"
            )
        }

        // Same customer, fresh checkout session - billing starts empty again
        reload(app, settings: settings)
        assertBillingAddressEmpty()
    }

    // MARK: - Existing happy paths

    func testCheckoutSession_Embedded_Card() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .embedded
        settings.integrationType = .checkoutSession
        settings.mode = .payment
        settings.formSheetAction = .continue
        settings.linkDisplay = .never
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)
        app.buttons["Continue"].tap()
        // After dismissing the form, scroll down and tap the confirm button
        app.buttons["Checkout"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    func testCheckoutSession_FlowController_Card() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.integrationType = .checkoutSession
        settings.mode = .payment
        settings.linkDisplay = .never
        loadPlayground(app, settings)

        // Open payment options
        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app)

        let continueButton = app.buttons["Continue"]
        continueButton.tap()

        // Confirm sits behind the sheet; wait until it's hittable (sync + dismiss finished)
        let confirmButton = app.buttons["Confirm"]
        confirmButton.forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    // MARK: - Billing sync on Continue

    func testCheckoutSession_FlowController_Horizontal_Continue_SyncsBillingAddress() throws {
        let settings = checkoutSessionSettings(uiStyle: .flowController, layout: .horizontal)
        loadPlayground(app, settings)
        assertBillingAddressEmpty()

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)

        app.buttons["Continue"].waitForExistenceAndTap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "12345")

        app.buttons["Confirm"].forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    func testCheckoutSession_FlowController_Vertical_Continue_SyncsBillingAddress() throws {
        let settings = checkoutSessionSettings(uiStyle: .flowController, layout: .vertical)
        loadPlayground(app, settings)
        assertBillingAddressEmpty()

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)

        app.buttons["Continue"].waitForExistenceAndTap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "12345")

        app.buttons["Confirm"].forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    func testCheckoutSession_Embedded_Continue_SyncsBillingAddress() throws {
        let settings = checkoutSessionSettings(uiStyle: .embedded)
        loadPlayground(app, settings)
        assertBillingAddressEmpty()

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)
        app.buttons["Continue"].waitForExistenceAndTap()

        waitForCheckoutBillingAddress(country: "US", postalCode: "12345")

        app.buttons["Checkout"].scrollToAndTap(in: app)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))
    }

    // MARK: - Billing sync on dismiss / cancel

    func testCheckoutSession_FlowController_Horizontal_DismissAfterSPM_SyncsBillingAddress() throws {
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .horizontal,
            customerMode: .new
        )
        try saveCardsAndReloadFreshCheckoutSession(settings: &settings)
        assertBillingAddressEmpty()

        // Opening + closing commits the already-selected SPM (no Continue)
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 5))
        app.buttons["Close"].waitForExistenceAndTap()

        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
    }

    func testCheckoutSession_FlowController_Horizontal_SelectSPM_AutoDismiss_SyncsBillingAddress_ZipOnly() throws {
        // Zip-only collection still puts country on the PM, so sync should work.
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .horizontal,
            customerMode: .new
        )
        loadPlayground(app, settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app, postalEnabled: true)
        let saveToggle = app.switches.containing(NSPredicate(format: "label CONTAINS[c] 'Save'")).firstMatch
        if saveToggle.waitForExistence(timeout: 2), !saveToggle.isSelected {
            saveToggle.tap()
        }
        app.buttons["Continue"].waitForExistenceAndTap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "12345")
        app.buttons["Confirm"].forceTapWhenHittableInTestCase(self)
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15))

        reload(app, settings: settings)
        assertBillingAddressEmpty()

        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 5), "Saved zip-only card not found after reload")
        app.buttons["•••• 4242"].tap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "12345")
    }

    func testCheckoutSession_FlowController_Horizontal_SelectSPM_AutoDismiss_SyncsBillingAddress() throws {
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .horizontal,
            customerMode: .new
        )
        try saveCardsAndReloadFreshCheckoutSession(settings: &settings)
        assertBillingAddressEmpty()

        // Horizontal auto-dismisses on SPM select (no Continue)
        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["•••• 4242"].waitForExistenceAndTap()

        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
    }

    func testCheckoutSession_FlowController_Vertical_DismissAfterSPM_SyncsBillingAddress() throws {
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .vertical,
            customerMode: .new
        )
        try saveCardsAndReloadFreshCheckoutSession(settings: &settings)
        assertBillingAddressEmpty()

        app.buttons["Payment method"].waitForExistenceAndTap()
        let savedCard = app.buttons["•••• 4242"]
        XCTAssertTrue(savedCard.waitForExistence(timeout: 5))
        if !savedCard.isSelected {
            savedCard.tap()
        }
        app.buttons["Close"].waitForExistenceAndTap()

        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
    }

    func testCheckoutSession_FlowController_Vertical_ContinueWithSPM_SyncsBillingAddress() throws {
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .vertical,
            customerMode: .new
        )
        try saveCardsAndReloadFreshCheckoutSession(settings: &settings)
        assertBillingAddressEmpty()

        app.buttons["Payment method"].waitForExistenceAndTap()
        let savedCard = app.buttons["•••• 4242"]
        XCTAssertTrue(savedCard.waitForExistence(timeout: 5))
        if !savedCard.isSelected {
            savedCard.tap()
        }
        app.buttons["Continue"].waitForExistenceAndTap()

        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
    }

    // MARK: - Embedded manage sheet dismiss

    func testCheckoutSession_Embedded_ManageDismiss_SyncsBillingAddress() throws {
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .horizontal,
            customerMode: .new
        )
        // Need two cards so Edit opens the manage list (one card goes straight to update).
        try saveCardsAndReloadFreshCheckoutSession(
            settings: &settings,
            cardNumbers: ["4242424242424242", "5555555555554444"]
        )

        // Switch UI style in-process — relaunching would reset the customer (UITesting AppDelegate).
        // Autoreload kicks off a fresh Embedded load with the same customer.
        app.buttons["embedded"].waitForExistenceAndTap(timeout: 5)
        XCTAssertTrue(
            app.buttons["Present embedded payment element"].waitForExistence(timeout: 15),
            "Embedded did not load after switching UI style"
        )
        assertBillingAddressEmpty()

        app.buttons["Present embedded payment element"].tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistenceAndTap(timeout: 10))
        XCTAssertTrue(app.staticTexts["Manage cards"].waitForExistence(timeout: 5))

        app.buttons["•••• 4242"].waitForExistenceAndTap()

        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
    }

    // MARK: - Edge cases

    func testCheckoutSession_FlowController_Vertical_DeleteAllSPMs_PreservesSessionBilling() throws {
        // Deleting every SPM shouldn't clear billing already on the session.
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .vertical,
            customerMode: .new
        )
        settings.allowsRemovalOfLastSavedPaymentMethod = .on
        try saveCardsAndReloadFreshCheckoutSession(settings: &settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        let savedCard = app.buttons["•••• 4242"]
        XCTAssertTrue(savedCard.waitForExistence(timeout: 5))
        if !savedCard.isSelected {
            savedCard.tap()
        }
        app.buttons["Continue"].waitForExistenceAndTap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
        // Billing can update before the sheet finishes dismissing
        waitForSheetToDismiss()

        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 5))
        app.buttons["Edit"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Remove"].waitForExistence(timeout: 5))
        app.buttons["Remove"].tap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        XCTAssertTrue(app.buttons["Card"].waitForExistence(timeout: 5))
        app.buttons["Close"].waitForExistenceAndTap()
        waitForSheetToDismiss()

        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
    }

    func testCheckoutSession_FlowController_Vertical_UpdateCardBilling_SyncsOnlyOnCommit() throws {
        // Updating billing on the card form updates the PM only; session sync waits for commit.
        var settings = checkoutSessionSettings(
            uiStyle: .flowController,
            layout: .vertical,
            customerMode: .new
        )
        try saveCardsAndReloadFreshCheckoutSession(settings: &settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        let savedCard = app.buttons["•••• 4242"]
        XCTAssertTrue(savedCard.waitForExistence(timeout: 5))
        if !savedCard.isSelected {
            savedCard.tap()
        }
        app.buttons["Continue"].waitForExistenceAndTap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "94102", line1: "510 Townsend St.")
        waitForSheetToDismiss()

        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 5))
        app.buttons["Edit"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Remove"].waitForExistence(timeout: 5))

        let zipField = app.textFields["ZIP"]
        XCTAssertTrue(zipField.waitForExistence(timeout: 5))
        zipField.tap()
        zipField.clearText()
        zipField.typeText("99999" + XCUIKeyboardKey.return.rawValue)
        app.buttons["Save"].waitForExistenceAndTap()

        XCTAssertTrue(app.buttons["•••• 4242"].waitForExistence(timeout: 10))
        XCTAssertEqual(
            checkoutBillingAddress["postalCode"] as? String,
            "94102",
            "Session billing should still be the old ZIP after Save; got: \(checkoutBillingAddress)"
        )

        app.buttons["Continue"].waitForExistenceAndTap()
        waitForCheckoutBillingAddress(country: "US", postalCode: "99999", line1: "510 Townsend St.")
    }

    private func waitForSheetToDismiss(timeout: TimeInterval = 10) {
        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        // Confirm is behind the sheet; hittable once dismiss finishes
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if confirmButton.isHittable {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("Timed out waiting for FlowController sheet to dismiss")
    }
}

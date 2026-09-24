//
//  CheckoutElementsUITests.swift
//  PaymentSheet Example
//

import XCTest

final class CheckoutElementsUITests: PaymentSheetUITestCase {
    func testSavedPaymentMethodControls() throws {
        // Given a Checkout Session for a returning customer with saved payment method controls enabled
        app.launchEnvironment["STP_CHECKOUT_ELEMENTS"] = "true"
        app.launch()

        app.buttons["Reset"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["checkout_picker_Customer"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["Returning"].waitForExistenceAndTap())
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        scrollStart.press(forDuration: 0.1, thenDragTo: scrollEnd)
        XCTAssertTrue(app.buttons["checkout_picker_Email source"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["Server — Customer"].waitForExistenceAndTap())
        app.switches["Collect Shipping Address"].scrollToAndTap(in: app)
        app.switches["Automatic Tax"].scrollToAndTap(in: app)
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()

        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))

        // When the customer opens Payment Element
        let paymentMethodButton = app.buttons["Select payment method"]
        paymentMethodButton.scrollToAndTap(in: app)

        // Then their saved card is displayed and can be selected
        let savedCard = app.buttons["•••• 4242"].firstMatch
        XCTAssertTrue(savedCard.waitForExistence(timeout: 10))
        savedCard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 10))

        // When the customer removes the saved card
        // The returning-customer fixture creates a fresh Customer for each request, so
        // removing this payment method does not mutate shared test state.
        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["edit_saved_button"].waitForExistenceAndTap()
        app.cells["•••• 4242"].buttons["CircularButton.Edit"].waitForExistenceAndTap()
        app.buttons["Remove"].waitForExistenceAndTap()
        app.alerts.buttons["Remove"].waitForExistenceAndTap()

        // Then the saved card is removed and the customer can add and save a new card
        XCTAssertFalse(savedCard.waitForExistence(timeout: 2))
        app.buttons["Done"].waitForExistenceAndTap()
        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["Add new payment method"].forceTapWhenHittableInTestCase(self)
        try fillCardData(app, cardNumber: "5555555555554444")

        let savePaymentMethodToggle = app.switches.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Save payment details")
        ).firstMatch
        XCTAssertTrue(savePaymentMethodToggle.waitForExistence(timeout: 5))
        XCTAssertFalse(savePaymentMethodToggle.isSelected)
        savePaymentMethodToggle.tap()
        XCTAssertTrue(savePaymentMethodToggle.isSelected)

        app.stp_dismissKeyboard()
        app.buttons["Continue"].forceTapWhenHittableInTestCase(self)

        // When the customer confirms with the new card, Checkout completes successfully
        XCTAssertTrue(app.staticTexts["•••• 4444"].waitForExistence(timeout: 10))
        let buyButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Buy")
        ).firstMatch
        buyButton.scrollToAndTap(in: app)

        XCTAssertTrue(app.alerts["Success"].waitForExistence(timeout: 20))
    }

    func testElementsStaySynchronizedWithCheckoutSession() throws {
        // Given a Checkout Session with Customer.email simulating a customer in Germany
        app.launchEnvironment["STP_CHECKOUT_ELEMENTS"] = "true"
        app.launch()

        app.buttons["Reset"].waitForExistenceAndTap()
        app.buttons["checkout_picker_Customer"].waitForExistenceAndTap()
        app.buttons["New"].waitForExistenceAndTap()
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        scrollStart.press(forDuration: 0.1, thenDragTo: scrollEnd)
        XCTAssertTrue(app.buttons["checkout_picker_Email source"].waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["Server — Customer"].waitForExistenceAndTap())
        app.buttons["No Override"].scrollToAndTap(in: app)
        app.buttons["Germany (DE)"].waitForExistenceAndTap()
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()

        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))
        let lineItemAmount = app.staticTexts["checkout_line_item_amount"].firstMatch
        let subtotalAmount = app.staticTexts["checkout_subtotal_amount"]
        let totalAmount = app.staticTexts["checkout_total_amount"]
        let buyButton = app.buttons["checkout_buy_button"]
        let taxPrompt = app.descendants(matching: .any)["checkout_tax_prompt"]
        XCTAssertTrue(lineItemAmount.waitForExistence(timeout: 10))
        XCTAssertTrue(subtotalAmount.exists)
        XCTAssertTrue(totalAmount.exists)
        XCTAssertTrue(buyButton.exists)
        XCTAssertTrue(taxPrompt.exists)

        // Then the merchant surface and Payment Element reflect the localized Session
        XCTAssertTrue(lineItemAmount.label.contains("€"))
        XCTAssertTrue(subtotalAmount.label.contains("€"))
        XCTAssertEqual(totalAmount.label, subtotalAmount.label)
        XCTAssertTrue(buyButton.label.contains(totalAmount.label))
        let applePayButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Buy with Apple")
        ).firstMatch
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pay with Link"].exists)
        XCTAssertTrue(app.buttons["Select payment method"].exists)

        // When the customer selects the integration currency in Currency Selector Element
        let usdCurrencyOption = app.buttons["currency_option_usd"]
        usdCurrencyOption.waitForExistenceAndTap()

        // Then every merchant-owned amount reflects the new Session
        expectation(
            for: NSPredicate(format: "label == %@", "$120.00"),
            evaluatedWith: totalAmount,
            handler: nil
        )
        waitForExpectations(timeout: 10)
        XCTAssertTrue(lineItemAmount.label.contains("$"))
        XCTAssertEqual(subtotalAmount.label, "$120.00")
        XCTAssertTrue(buyButton.label.contains("$120.00"))
        expectation(
            for: NSPredicate(format: "hittable == true"),
            evaluatedWith: usdCurrencyOption,
            handler: nil
        )
        waitForExpectations(timeout: 10)

        // When the customer saves an address in Shipping Address Element
        scrollStart.press(forDuration: 0.1, thenDragTo: scrollEnd)
        app.buttons["Add shipping address"].scrollToAndTap(in: app)
        fillShippingAddress()

        let saveAddressButton = app.buttons["Save Address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        // Then the merchant surface reflects the new Session
        XCTAssertTrue(app.staticTexts["Jane Doe"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["510 Townsend St"].exists)
        expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: taxPrompt,
            handler: nil
        )
        waitForExpectations(timeout: 10)
        let taxAmount = app.staticTexts["checkout_tax_amount"]
        XCTAssertTrue(taxAmount.waitForExistence(timeout: 10))
        XCTAssertTrue(taxAmount.label.contains("$"))
        XCTAssertNotEqual(taxAmount.label, "$0.00")
        XCTAssertEqual(subtotalAmount.label, "$120.00")
        XCTAssertNotEqual(totalAmount.label, subtotalAmount.label)
        XCTAssertTrue(buyButton.label.contains(totalAmount.label))

        // When the customer selects a card in Payment Element
        app.buttons["Select payment method"].scrollToAndTap(in: app)
        if !app.textFields["Card number"].waitForExistence(timeout: 2) {
            app.buttons["Add new payment method"].forceTapWhenHittableInTestCase(self)
        }
        if !app.textFields["Card number"].waitForExistence(timeout: 2) {
            app.buttons["+ Add"].forceTapWhenHittableInTestCase(self)
        }
        try fillCardData(app)
        app.stp_dismissKeyboard()
        app.buttons["Continue"].forceTapWhenHittableInTestCase(self)

        // Then the merchant surface reflects the selected payment method after Checkout updates.
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 10))
        buyButton.scrollToAndTap(in: app)

        XCTAssertTrue(app.alerts["Success"].waitForExistence(timeout: 20))
    }

    func testExpressCheckoutElementApplePayCompletesCheckout() {
        // Given an ECE-only Checkout Session without address-dependent tax in the normal hosted playground
        app.launchEnvironment["STP_CHECKOUT_ELEMENTS"] = "true"
        app.launch()

        app.buttons["Reset"].waitForExistenceAndTap()
        let paymentElementPicker = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "PaymentElement")
        ).firstMatch
        XCTAssertTrue(paymentElementPicker.waitForExistenceAndTap())
        XCTAssertTrue(app.buttons["ece only"].waitForExistenceAndTap())

        // ECE Apple Pay does not yet request a shipping postal address. Enabling shipping-sourced
        // automatic tax causes confirmation to fail with `customer_tax_location_invalid` until
        // CheckoutApplePayContext implements shipping contact collection.
        let collectShippingAddress = app.switches["Collect Shipping Address"]
        XCTAssertTrue(collectShippingAddress.waitForExistence(timeout: 4))
        collectShippingAddress.scrollToAndTap(in: app)
        let automaticTax = app.switches["Automatic Tax"]
        XCTAssertTrue(automaticTax.waitForExistence(timeout: 4))
        automaticTax.scrollToAndTap(in: app)
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()

        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))
        let applePayButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Buy with Apple")
        ).firstMatch
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Select payment method"].exists)
        let buyButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Buy ·")
        ).firstMatch
        XCTAssertFalse(buyButton.exists)

        // When the customer confirms with Apple Pay from Express Checkout Element
        applePayButton.tap()

        // Then Checkout completes using the wallet confirmation flow
        payWithApplePay(successElement: app.alerts["Success"])
    }

    private func fillShippingAddress() {
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

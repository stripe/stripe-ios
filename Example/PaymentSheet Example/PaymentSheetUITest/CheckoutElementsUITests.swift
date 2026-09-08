//
//  CheckoutElementsUITests.swift
//  PaymentSheet Example
//

import XCTest

final class CheckoutElementsUITests: PaymentSheetUITestCase {
    func testElementsStaySynchronizedWithCheckoutSession() throws {
        // Given a Checkout Session
        app.launchEnvironment["STP_CHECKOUT_ELEMENTS"] = "true"
        app.launch()

        app.buttons["Reset"].waitForExistenceAndTap()
        app.buttons["No Override"].scrollToAndTap(in: app)
        app.buttons["Germany (DE)"].waitForExistenceAndTap()
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()

        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Enter shipping address to calculate"].waitForExistence(timeout: 10))

        // When the customer selects the integration currency in Currency Selector Element
        let usdCurrencyOption = app.buttons["currency_option_usd"]
        usdCurrencyOption.waitForExistenceAndTap()

        // Then the merchant surface reflects the new Session
        XCTAssertTrue(app.staticTexts["$120.00"].waitForExistence(timeout: 10))
        expectation(
            for: NSPredicate(format: "hittable == true"),
            evaluatedWith: usdCurrencyOption,
            handler: nil
        )
        waitForExpectations(timeout: 10)

        // When the customer saves an address in Shipping Address Element
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        scrollStart.press(forDuration: 0.1, thenDragTo: scrollEnd)
        app.buttons["Add shipping address"].scrollToAndTap(in: app)
        fillShippingAddress()

        let saveAddressButton = app.buttons["Save Address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        // Then the merchant surface reflects the new Session
        XCTAssertTrue(app.staticTexts["Jane Doe"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["510 Townsend St"].exists)
        XCTAssertFalse(app.staticTexts["Enter shipping address to calculate"].exists)

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
        let buyButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Buy")
        ).firstMatch
        buyButton.scrollToAndTap(in: app)

        XCTAssertTrue(app.alerts["Success"].waitForExistence(timeout: 20))
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

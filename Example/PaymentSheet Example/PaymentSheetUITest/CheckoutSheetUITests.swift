import XCTest

final class CheckoutSheetUITests: PaymentSheetUITestCase {
    func testCheckoutSheetEmailAcceptsInputWithoutTestKeyboardOverrides() {
        // Given a normal app launch with the simulator's existing keyboard configuration
        app.launchEnvironment.removeValue(forKey: "UITesting")
        launchSheetPlayground()
        app.buttons["checkout_picker_Email source"].scrollToAndTap(in: app)
        XCTAssertTrue(app.buttons["None"].waitForExistenceAndTap())
        createAndOpenSheet()
        if app.buttons["Pay another way"].exists {
            app.buttons["Pay another way"].tap()
        } else {
            app.buttons["Continue checkout"].waitForExistenceAndTap()
        }
        let email = app.textFields["checkout_sheet_email"]
        XCTAssertTrue(email.waitForExistence(timeout: 10))

        // When the customer types into the automatically focused email field
        app.typeText("jane")
        XCTAssertEqual(email.value as? String, "jane")
        app.typeText("@example.com")

        // Then typing survives view updates and enables the next task
        XCTAssertEqual(email.value as? String, "jane@example.com")
        XCTAssertTrue(app.buttons["Continue to shipping"].isEnabled)
        XCTAssertFalse(app.alerts["Broken constraint!"].exists)
        capture("checkout-sheet-email-input")

        // When the customer refocuses the field and continues editing
        email.tap()
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "@example.com".count))
        app.typeText("x@example.com")
        XCTAssertEqual(email.value as? String, "janex@example.com")
    }

    func testCheckoutSheetCollectsContactAndShippingAndCanReopen() {
        // Given a session without collected contact or shipping details
        launchSheetPlayground()
        app.buttons["checkout_picker_Email source"].scrollToAndTap(in: app)
        app.buttons["None"].waitForExistenceAndTap()
        app.buttons["checkout_picker_Apple Pay Display"].scrollToAndTap(in: app)
        app.buttons["Never"].waitForExistenceAndTap()
        createAndOpenSheet()
        capture("checkout-sheet-express")
        if app.buttons["Pay another way"].exists {
            app.buttons["Pay another way"].tap()
        } else {
            app.buttons["Continue checkout"].tap()
        }

        // When the customer completes the contact and shipping tasks
        app.textFields["checkout_sheet_email"].waitForExistenceAndTap()
        app.typeText("jane@example.com")
        app.buttons["Continue to shipping"].scrollToAndTap(in: app)
        XCTAssertTrue(app.textFields["Full name"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts["Broken constraint!"].exists)
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
        app.typeText("94103")
        XCTAssertFalse(app.alerts["Broken constraint!"].exists)
        capture("checkout-sheet-shipping")
        app.buttons["Continue to payment"].scrollToAndTap(in: app)
        // An already-selected wallet can take checkout straight to review after shipping is saved.
        if !app.buttons["Card"].waitForExistence(timeout: 5) {
            XCTAssertTrue(app.buttons["checkout_sheet_review_shipping"].waitForExistence(timeout: 10))
        }

        // Then closing and reopening checkout retains the session details without confirming it
        app.buttons["checkout_sheet_close"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["launch_checkout_sheet"].waitForExistence(timeout: 10))
        app.buttons["launch_checkout_sheet"].tap()
        XCTAssertTrue(app.staticTexts["jane@example.com"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "510 Townsend St")).firstMatch.exists
        )
        capture("checkout-sheet-reopened")
    }

    func testCheckoutSheetCollectsPaymentAndConfirmsSession() throws {
        // Given a real test-mode Checkout Session with known contact and shipping information
        launchSheetPlayground()
        app.buttons["checkout_picker_Default Shipping Address"].scrollToAndTap(in: app)
        app.buttons["US test address"].waitForExistenceAndTap()
        createAndOpenSheet()
        XCTAssertTrue(app.staticTexts["checkout_sheet_total"].waitForExistence(timeout: 10))
        capture("checkout-sheet-review-with-missing-payment")

        // When the customer enters a card inside Checkout Sheet's existing navigation
        app.buttons["checkout_sheet_review_payment"].scrollToAndTap(in: app)
        app.buttons["Card"].waitForExistenceAndTap()
        try fillCardData(app)
        app.stp_dismissKeyboard()
        capture("checkout-sheet-card")
        app.buttons["Continue"].forceTapWhenHittableInTestCase(self)
        app.buttons["Review"].scrollToAndTap(in: app)
        XCTAssertTrue(app.buttons["Pay now"].waitForExistence(timeout: 10))
        capture("checkout-sheet-review")
        app.buttons["Pay now"].tap()

        // Then the real Checkout Session completes and the merchant receives the result after Done
        XCTAssertTrue(app.staticTexts["Payment complete"].waitForExistence(timeout: 30))
        capture("checkout-sheet-confirmation")
        app.buttons["Done"].waitForExistenceAndTap()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Checkout completed.")).firstMatch
                .waitForExistence(timeout: 10)
        )
    }

    private func launchSheetPlayground() {
        app.launchEnvironment["STP_CHECKOUT_SHEET"] = "true"
        app.launch()
        app.buttons["Reset"].waitForExistenceAndTap()
        app.buttons["checkout_picker_PaymentElement"].waitForExistenceAndTap()
        app.buttons["Checkout Sheet"].waitForExistenceAndTap()
    }

    private func createAndOpenSheet() {
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["launch_checkout_sheet"].waitForExistence(timeout: 30))
        app.buttons["launch_checkout_sheet"].tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

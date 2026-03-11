//
//  PaymentSheetStandardUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//

import XCTest

class PaymentSheetStandardUITests: PaymentSheetUITestCase {
    func testPaymentSheetStandard() throws {
        app.launch()
        app.staticTexts["PaymentSheet"].tap()
        app.staticTexts["Buy"].waitForExistenceAndTap(timeout: 60)

        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Pay €9.73"].tap()
        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    /// Ensure PaymentSheet does not call any invalid functions that
    /// could break UINavigationController's internal state.
    /// See https://github.com/stripe/stripe-ios/issues/4243 for details.
    func testPaymentSheetDoesNotBreakUI() {
        app.launch()
        app.staticTexts["PaymentSheet"].tap()
        app.staticTexts["Buy"].waitForExistenceAndTap(timeout: 60)

        // Get screen position of a static item at the top of the VC:
        let yourCartText = XCUIApplication().staticTexts["Your cart"]
        let yourCartFrame = yourCartText.frame

        // Wait for the sheet to load
        let sheetPayButton = app.buttons["Pay €9.73"].waitForExistence(timeout: 60)

        // Close PaymentSheet. At this point, if we messed up our presentation
        // logic, the containing UINavigationController will be in a bad state.
        app.buttons["Close"].waitForExistenceAndTap()

        // Exercise the UINavigationController by popping and pushing the VC
        let backButton = XCUIApplication().buttons["Back"]
        backButton.waitForExistenceAndTap()
        app.staticTexts["PaymentSheet"].waitForExistenceAndTap()

        // If the static element has moved from the original location, we messed something up.
        XCTAssertEqual(yourCartFrame, yourCartText.frame)
    }

    func testPaymentSheetDoesNotBreakUISwiftUI() {
        // Same as above, but invoke from SwiftUI.
        app.launch()
        app.staticTexts["PaymentSheet"].tap()
        let backButton = XCUIApplication().buttons["Back"]
        // Get the position of the static text in the main PS Example (Our SwiftUI example doesn't have anything anchored to a specific location)
        let yourCartText = XCUIApplication().staticTexts["Your cart"]
        let yourCartFrame = yourCartText.frame

        // Go back and invoke PaymentSheet via SwiftUI
        backButton.waitForExistenceAndTap()
        app.staticTexts["PaymentSheet (SwiftUI)"].tap()
        app.buttons["Buy"].waitForExistenceAndTap(timeout: 60)

        // Wait for the sheet to load
        _ = app.buttons["Pay €9.73"].waitForExistence(timeout: 60)

        // Close the sheet (at this point UINavigationController would be in the bad state)
        app.buttons["Close"].waitForExistenceAndTap()

        // Go back to the main PS example and check the layout. Is it the same?
        backButton.waitForExistenceAndTap()
        app.staticTexts["PaymentSheet"].waitForExistenceAndTap()
        XCTAssertEqual(yourCartFrame, yourCartText.frame)
    }

    func testCardFormAmexCVV() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["PaymentSheet"].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()

        app.buttons["Card"].waitForExistenceAndTap()
        let numberField = app.textFields["Card number"]
        XCTAssertTrue(numberField.waitForExistence(timeout: 60.0))
        numberField.tap()
        numberField.typeText("378282246310005")

        // Test that Amex card allows 4 digits
        let cvcField = app.textFields["CVC"]
        XCTAssertTrue(cvcField.waitForExistence(timeout: 10.0))

        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))

        XCTAssertTrue((cvcField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvcField.typeText("1234"))

        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }

    func testPaymentSheetFlowController() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController"].tap()
        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"]

        let paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        let addCardButton = app.buttons["Card"].waitForExistenceAndTap()

        try! fillCardData(app)
        app.buttons["Continue"].tap()

        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testPaymentSheetFlowControllerDeferred_update() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController (Deferred)"].tap()

        // Update product quantities and enable subscription
        let subscribeSwitch = app.switches["subscribe_switch"]

        let subscribeSwitchEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: subscribeSwitch
        )
        wait(for: [subscribeSwitchEnabledExpectation], timeout: 60, enforceOrder: true)

        app.switches["subscribe_switch"].tap()
        app.steppers["hotdog_stepper"].tap()
        app.steppers["hotdog_stepper"].tap()
        app.steppers["salad_stepper"].tap()

        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"]

        var paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        app.buttons["Card"].waitForExistenceAndTap()

        try! fillCardData(app)

        app.buttons["Continue"].tap()

        // Update quantity of an item to force an update
        let saladStepper = app.steppers["salad_stepper"]
        XCTAssertTrue(saladStepper.waitForExistence(timeout: 4.0))
        saladStepper.tap()

        paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        // Continue should be enabled since card details were preserved when closing payment sheet
        XCTAssertTrue(app.buttons["Continue"].waitForExistenceAndTap(timeout: 4.0))

        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testPaymentSheetFlowControllerSaveAndRemoveCard() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        XCTAssertEqual(
            // filter out async passive captcha and attestation logs
            analyticsLog.map({ $0[string: "event"] }).filter({ !($0?.starts(with: "elements.captcha.passive") ?? false) && !($0?.contains("attest") ?? false) }),
            ["mc_load_started", "link.account_lookup.complete", "mc_load_succeeded", "mc_custom_init_customer_applepay", "mc_custom_sheet_savedpm_show"]
        )
        // `mc_load_succeeded` event `selected_lpm` should be "apple_pay", the default payment method.
        XCTAssertEqual(analyticsLog[2][string: "selected_lpm"], "apple_pay")
        app.buttons["+ Add"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Card information"].waitForExistence(timeout: 2))

        let formShownAnalytic = try XCTUnwrap(analyticsLog.first { $0[string: "event"] == "mc_form_shown" }, "Should fire the `mc_form_shown`")
        XCTAssertEqual(formShownAnalytic[string: "selected_lpm"], "card", "The `mc_form_shown` event should have `selected_lpm` = card")

        try! fillCardData(app)

        // toggle save this card on and off
        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()  // toggle back off
        XCTAssertFalse(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()

        // Check analytics
        XCTAssertEqual(
            analyticsLog.suffix(4).map({ $0[string: "event"] }),
            ["mc_form_interacted", "mc_card_number_completed", "mc_form_completed", "mc_confirm_button_tapped"]
        )
        XCTAssertEqual(
            analyticsLog.suffix(4).map({ $0[string: "selected_lpm"] }),
            ["card", nil, "card", "card"]
        )

        app.buttons["Confirm"].tap()
        var successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertEqual(analyticsLog.last?[string: "event"], "mc_custom_payment_newpm_success")
        XCTAssertEqual(analyticsLog.last?[string: "selected_lpm"], "card")
        // Make sure they all have the same session id
        let sessionID = analyticsLog.first![string: "session_id"]
        XCTAssertTrue(!sessionID!.isEmpty)
        for analytic in analyticsLog {
            XCTAssertEqual(analytic[string: "session_id"], sessionID)
        }
        // Make sure the appropriate events have "selected_lpm" = "card"
        for analytic in analyticsLog {
            if ["mc_form_shown", "mc_form_interacted", "mc_form_completed", "mc_confirm_button_tapped", "mc_custom_payment_newpm_success"].contains(analytic[string: "event"]) {
               XCTAssertEqual(analytic[string: "selected_lpm"], "card")
            }
        }

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        XCTAssertNotEqual(analyticsLog.first?[string: "session_id"], sessionID) // Sanity check this has a different session ID than before
        XCTAssertEqual(app.cells.count, 3) // Should be "Add" and "Apple Pay" and "Link"
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app)
        // toggle save this card on
        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        // return to payment method selector
        app.staticTexts["•••• 4242"].waitForExistenceAndTap(timeout: 30)  // The card should be saved now and selected as default instead of Apple Pay
        XCTAssertEqual(app.cells.count, 4) // Should be "Add", "Apple Pay", "Link", and saved card

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        // circularEditButton shows up in the view hierarchy, but it's not actually on the screen or tappable so we scroll a little
        let startCoordinate = app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.1, thenDragTo: app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.99)))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap())

        let removeButton = app.buttons["Remove"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 60.0))
        removeButton.tap()

        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 60.0))
        confirmRemoval.tap()

        XCTAssertTrue(app.staticTexts["Select your payment method"].waitForExistence(timeout: 3.0))
        XCTAssertEqual(app.cells.count, 3) // Should be "Add", "Apple Pay", "Link"

        // Give time for analyticsLog to receive mc_custom_paymentoption_removed
        sleep(1)

        XCTAssertEqual(
            analyticsLog.suffix(1).map({ $0[string: "event"] }),
            ["mc_custom_paymentoption_removed"]
        )
        XCTAssertEqual(
            analyticsLog.suffix(1).map({ $0[string: "selected_lpm"] }),
            ["card"]
        )
    }

    func testPaymentSheetFlowControllerLinkWalletSelection() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .flowController
        settings.layout = .horizontal
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "link,card"
        // Use a non-US merchant because the US merchant is gated into Link RUX in FlowController
        settings.merchantCountryCode = .FR
        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]
        paymentMethodButton.waitForExistenceAndTap(timeout: 10)

        // Fill out card form first
        try! fillCardData(app, disableDefaultOptInIfNeeded: true)
        app.buttons["Continue"].tap()
        sleep(2)
        XCTAssertEqual(paymentMethodButton.label, "•••• 4242, card, 12345, US")

        // Now select Link
        paymentMethodButton.tap()
        app.buttons["Pay with Link"].waitForExistenceAndTap()
        sleep(2)
        XCTAssertEqual(paymentMethodButton.label, "Link, link")

        // Open and close PaymentSheet without making changes
        paymentMethodButton.tap()
        app.tapCoordinate(at: CGPoint(x: 100, y: 100))
        sleep(2)
        XCTAssertEqual(paymentMethodButton.label, "Link, link")

        // Open again and choose to continue with card
        paymentMethodButton.tap()
        app.buttons["Continue"].tap()
        sleep(2)
        XCTAssertEqual(paymentMethodButton.label, "•••• 4242, card, 12345, US")
    }

    func testPaymentSheetSwiftUI() throws {
        app.launch()

        app.staticTexts["PaymentSheet (SwiftUI)"].tap()
        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Done"].waitForExistenceAndTap(timeout: 3.0)
        app.buttons["Pay €9.73"].waitForExistenceAndTap(timeout: 3.0)
        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Success!"))
    }

    func testPaymentSheetSwiftUIFlowController() throws {
        app.launch()

        app.staticTexts["PaymentSheet.FlowController (SwiftUI)"].tap()
        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.forceTapElement()

        app.buttons["Card"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Continue"].tap()

        // XCTest is too eager to tap the buy button: Wait until the sheet dismisses first.
        waitToDisappear(app.textFields["Card number"])

        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.forceTapElement()

        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Success!"))
    }

    func testUPIPaymentMethodPolling() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.customerKeyType = .legacy
        settings.merchantCountryCode = .IN
        settings.currency = .inr
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let payButton = app.buttons["Pay ₹50.99"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 10))
        guard let upi = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "UPI") else {
            XCTFail()
            return
        }
        upi.tap()

        XCTAssertFalse(payButton.isEnabled)
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.pending@stripeupi")
        upi_id.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()

        let approvePaymentText = app.staticTexts["Approve payment"]
        XCTAssertTrue(approvePaymentText.waitForExistence(timeout: 10.0))

        // UPI Specific CTA
        let predicate = NSPredicate(format: "label BEGINSWITH 'Open your UPI app to approve your payment within'")
        let upiCTAText = XCUIApplication().staticTexts.element(matching: predicate)
        XCTAssertTrue(upiCTAText.waitForExistence(timeout: 10.0))
    }

    func testBLIKPaymentMethodPolling() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
                settings.merchantCountryCode = .FR
        settings.currency = .pln
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let payButton = app.buttons["Pay PLN 50.99"]
        guard let blik = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "BLIK") else {
            XCTFail()
            return
        }
        blik.tap()

        XCTAssertFalse(payButton.isEnabled)
        let blik_code = app.textFields["BLIK code"]
        blik_code.tap()
        blik_code.typeText("123456")
        blik_code.typeText(XCUIKeyboardKey.return.rawValue)

        payButton.tap()

        let approvePaymentText = app.staticTexts["Approve payment"]
        XCTAssertTrue(approvePaymentText.waitForExistence(timeout: 15.0))

        // BLIK Specific CTA
        let predicate = NSPredicate(format: "label BEGINSWITH 'Confirm the payment in your bank\\'s app within'")
        let blikCTAText = XCUIApplication().staticTexts.element(matching: predicate)
        XCTAssertTrue(blikCTAText.waitForExistence(timeout: 10.0))
    }

    func test3DS2Card_alwaysAuthenticate() throws {
        app.launch()
        app.staticTexts["PaymentSheet"].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()
        app.buttons["Card"].waitForExistenceAndTap()

        // Card number from https://docs.stripe.com/testing#regulatory-cards
        try! fillCardData(app, cardNumber: "4000002760003184")
        app.buttons["Pay €9.73"].tap()
        let challengeCodeTextField = app.textFields["STDSTextField"]
        XCTAssertTrue(challengeCodeTextField.waitForExistenceAndTap())
        challengeCodeTextField.typeText("424242" + XCUIKeyboardKey.return.rawValue)
        app.buttons["Submit"].waitForExistenceAndTap()
        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testPreservesFormDetails() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.mode = .setup
        settings.uiStyle = .paymentSheet
        settings.layout = .horizontal
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card,cashapp,us_bank_account"
        loadPlayground(app, settings)

        // Add a card first so we can test saved screen
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        try! fillCardData(app, tapCheckboxWithText: "Save payment details to Example, Inc. for future purchases")
        app.buttons["Set up"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
        app.buttons["Reload"].tap()

        func _testHorizontalPreservesFormDetails() {
            // Typing something into the card form...
            let numberField = app.textFields["Card number"]
            numberField.waitForExistenceAndTap()
            app.typeText("4")
            // ...and tapping to a different form and back...
            XCTAssertTrue(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Cash App Pay")?.waitForExistenceAndTap() ?? false)
            XCTAssertTrue(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Card")?.waitForExistenceAndTap() ?? false)
            // ...should preserve the card form
            XCTAssertEqual(numberField.value as? String, "4, Your card number is incomplete.")
            // ...tapping to the saved PM screen and back should do the same
            app.buttons["Back"].waitForExistenceAndTap()
            app.buttons["+ Add"].waitForExistenceAndTap()
            XCTAssertEqual(numberField.value as? String, "4, Your card number is incomplete.")
            // Exit
            app.buttons["Back"].waitForExistenceAndTap()
            app.buttons["Close"].waitForExistenceAndTap()
        }
        // PaymenSheet + Horizontal
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        _testHorizontalPreservesFormDetails()
    }

    func testCardScannerOpensAutomatically() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.opensCardScannerAutomatically = .on

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Verify STPCardScanner is NOT in analytics product_usage when sheet is open but card form hasn't been opened
        let initialProductUsage = analyticsLog.last!["product_usage"] as! [String]
        XCTAssertFalse(initialProductUsage.contains("STPCardScanner"), "STPCardScanner should not be in product_usage before opening card form")

        // Open the card form
        app.buttons["Card"].waitForExistenceAndTap()

        // Wait for the close card scanner button to appear, which indicates the scanner is open and analytics updated
        let closeScannerButton = app.buttons["Close card scanner"]
        XCTAssertTrue(closeScannerButton.waitForExistence(timeout: 10.0), "Close card scanner button should appear when scanner opens")

        // Verify STPCardScanner IS in analytics product_usage after opening card form
        let updatedProductUsage = analyticsLog.last!["product_usage"] as! [String]
        XCTAssertTrue(updatedProductUsage.contains("STPCardScanner"), "STPCardScanner should be in product_usage after opening card form")

        // Close the card scanner
        closeScannerButton.tap()

        // Verify card scanner is closed
        XCTAssertFalse(closeScannerButton.waitForExistence(timeout: 2.0), "Card scanner should be closed after tapping close button")

        // Verify we can open the scanner again using the scan button
        let scanCardButton = app.buttons["Scan card"]
        XCTAssertTrue(scanCardButton.waitForExistence(timeout: 5.0), "Scan card button should exist")
        scanCardButton.tap()
        XCTAssertTrue(closeScannerButton.waitForExistence(timeout: 10.0), "Card scanner should open when tapping scan button")

        // Verify that editing a form field closes the scanner
        let cardNumberField = app.textFields["Card number"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 10.0), "Card number field should exist")
        cardNumberField.tap()

        // Verify scanner is closed after editing form field
        XCTAssertFalse(closeScannerButton.exists, "Card scanner should be closed when editing form fields")
    }
}

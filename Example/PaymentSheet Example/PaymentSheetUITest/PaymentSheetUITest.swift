//
//  PaymentSheetUITestCase.swift
//  PaymentSheetUITest
//
//  Created by David Estes on 1/21/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheetUITestCase: XCTestCase {
    var app: XCUIApplication!

    /// This element's `label` contains all the analytic events sent by the SDK since the the playground was loaded, as a base-64 encoded string.
    /// - Note: Only exists in test playground.
    lazy var analyticsLogElement: XCUIElement = { app.staticTexts["_testAnalyticsLog"] }()
    /// Convenience var to grab all the events sent since the playground was loaded.
    var analyticsLog: [[String: Any]] {
        let logRawString = analyticsLogElement.label
        guard
            let data = Data(base64Encoded: logRawString),
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        return json
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = [
            "UITesting": "true",
            // This makes the Financial Connections SDK trigger the (testmode) production flow instead of a stub. See `FinancialConnectionsSDKAvailability`.
            "FinancialConnectionsSDKAvailable": "true",
            "FinancialConnectionsStubbedResult": "false",
        ]
    }
}

// XCTest runs classes in parallel, not individual tests. Split the tests into separate classes to keep build times at a reasonable level.
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
            analyticsLog.map({ $0[string: "event"] }),
            // fraud detection telemetry should not be sent in tests, so it should report an API failure
            ["mc_load_started", "link.account_lookup.complete", "mc_load_succeeded", "fraud_detection_data_repository.api_failure", "mc_custom_init_customer_applepay", "mc_custom_sheet_savedpm_show"]
        )
        // `mc_load_succeeded` event `selected_lpm` should be "apple_pay", the default payment method.
        XCTAssertEqual(analyticsLog[2][string: "selected_lpm"], "apple_pay")
        app.buttons["+ Add"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Card information"].waitForExistence(timeout: 2))

        // Should fire the `mc_form_shown` event w/ `selected_lpm` = card
        XCTAssertEqual(analyticsLog.last?[string: "event"], "mc_form_shown")
        XCTAssertEqual(analyticsLog.last?[string: "selected_lpm"], "card")

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

    func testIdealPaymentMethodHasTextFieldsAndDropdown() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.currency = .eur
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay €50.99"]

        guard let iDEAL = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "iDEAL") else {
            XCTFail()
            return
        }
        iDEAL.tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Full name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["iDEAL Bank"]
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "ASN Bank")
        app.toolbars.buttons["Done"].tap()

        payButton.tap()

        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
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
}

class PaymentSheetDeferredUITests: PaymentSheetUITestCase {

    // MARK: Deferred tests (client-side)

    func testDeferredPaymentIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))

        XCTAssertEqual(
            // Ignore luxe_* analytics since there are a lot and I'm not sure if they're the same every time
            analyticsLog.map({ $0[string: "event"] }).filter({ $0 != "luxe_image_selector_icon_from_bundle" && $0 != "luxe_image_selector_icon_downloaded" }),
            // fraud detection telemetry should not be sent in tests, so it should report an API failure
            ["mc_complete_init_applepay", "mc_load_started", "mc_load_succeeded", "fraud_detection_data_repository.api_failure", "mc_complete_sheet_newpm_show", "mc_lpms_render", "mc_form_shown"]
        )
        XCTAssertEqual(analyticsLog.last?[string: "selected_lpm"], "card")

        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        XCTAssertEqual(
            analyticsLog.suffix(9).map({ $0[string: "event"] }),
            ["mc_form_interacted", "mc_card_number_completed", "mc_form_completed", "mc_confirm_button_tapped", "stripeios.payment_method_creation", "stripeios.paymenthandler.confirm.started", "stripeios.payment_intent_confirmation", "stripeios.paymenthandler.confirm.finished", "mc_complete_payment_newpm_success"]
        )

        // Make sure they all have the same session id
        let sessionID = analyticsLog.first![string: "session_id"]
        XCTAssertTrue(!sessionID!.isEmpty)
        for analytic in analyticsLog {
            XCTAssertEqual(analytic[string: "session_id"], sessionID)
        }

    }

    func testDeferredPaymentIntent_ClientSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].tap()

        let declineText = app.staticTexts["Your card was declined."]
        XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.mode = .setup
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.uiStyle = .flowController
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_FlowController_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.uiStyle = .flowController
        settings.mode = .setup
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    /* Disable Link test
     func testDeferferedIntentLinkSignup_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )

     app.buttons["Present PaymentSheet"].tap()

     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()

     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     XCTAssertTrue(modal.waitForExistence(timeout: 10))

     let emailField = modal.textFields["Email"]
     XCTAssertTrue(emailField.waitForExistence(timeout: 10))
     emailField.tap()
     emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")

     let phoneField = modal.textFields["Phone"]
     XCTAssert(phoneField.waitForExistence(timeout: 10))
     phoneField.tap()
     phoneField.typeText("3105551234")

     // The name field is only required for non-US countries. Only fill it out if it exists.
     let nameField = modal.textFields["Name"]
     if nameField.exists {
     nameField.tap()
     nameField.typeText("Jane Done")
     }

     modal.buttons["Join Link"].tap()

     // Because we are presenting view controllers with `modalPresentationStyle = .overFullScreen`,
     // there are currently 2 card forms on screen. Specifying a container helps the `fillCardData()`
     // method operate on the correct card form.
     try fillCardData(app, container: modal)

     // Pay!
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()

     let successText = app.staticTexts["Success!"]
     XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredIntent_ApplePayFlowControllerFlow_ClientSideConfirmation() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.uiStyle = .flowController
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .pm
        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
        paymentMethodButton.tap()

        let applePay = app.collectionViews.buttons["Apple Pay"]
        XCTAssertTrue(applePay.waitForExistence(timeout: 10.0))
        applePay.tap()

        app.buttons["Confirm"].tap()

        payWithApplePay()
    }
}

class PaymentSheetDeferredUIBankAccountTests: PaymentSheetUITestCase {
    func testDeferredIntentPaymentIntent_USBankAccount_ClientSideConfirmation() {
        _testUSBankAccount(mode: .payment, integrationType: .deferred_csc)
    }

    func testDeferredIntentPaymentIntent_USBankAccount_ServerSideConfirmation() {
        _testUSBankAccount(mode: .payment, integrationType: .deferred_ssc)
    }

    func testDeferredIntentSetupIntent_USBankAccount_ClientSideConfirmation() {
        _testUSBankAccount(mode: .setup, integrationType: .deferred_csc)
    }

    func testDeferredIntentSetupIntent_USBankAccount_ServerSideConfirmation() {
        _testUSBankAccount(mode: .setup, integrationType: .deferred_ssc)
    }

    /* Disable Link test
     func testDeferredIntentLinkSignIn_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try loginAndPay()
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkSignIn_ClientSideConfirmation_LostCardDecline() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistence(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let failedText = modal.staticTexts["The payment failed."]
     XCTAssertTrue(failedText.waitForExistence(timeout: 10))
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkFlowControllerFlow_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     let paymentMethodButton = app.buttons["Select Payment Method"]
     XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"]
     XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].tap()
     
     try loginAndPay()
     }
     */
}

class PaymentSheetDeferredServerSideUITests: PaymentSheetUITestCase {
    // MARK: Deferred tests (server-side)

    func testDeferredPaymentIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_ServerSideConfirmation_Multiprocessor() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Pay $50.99"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_SeverSideConfirmation_LostCardDecline() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil, cardNumber: "4000000000009987")

        app.buttons["Pay $50.99"].tap()

        let declineText = app.staticTexts["Your card was declined."]
        XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        settings.mode = .setup
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        try? fillCardData(app, container: nil)

        app.buttons["Set up"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredPaymentIntent_FlowController_ServerSideConfirmation_ManualConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mc
        settings.uiStyle = .flowController
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testDeferredSetupIntent_FlowController_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController
        settings.mode = .setup
        loadPlayground(app, settings)

        let selectButton = app.buttons["Payment method"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10.0))
        selectButton.tap()
        let selectText = app.staticTexts["Select your payment method"]
        XCTAssertTrue(selectText.waitForExistence(timeout: 10.0))

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try? fillCardData(app, container: nil)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    /* Disable link test
     func testDeferferedIntentLinkSignup_ServerSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     XCTAssertTrue(modal.waitForExistence(timeout: 10))
     
     let emailField = modal.textFields["Email"]
     XCTAssertTrue(emailField.waitForExistence(timeout: 10))
     emailField.tap()
     emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")
     
     let phoneField = modal.textFields["Phone"]
     XCTAssert(phoneField.waitForExistence(timeout: 10))
     phoneField.tap()
     phoneField.typeText("3105551234")
     
     // The name field is only required for non-US countries. Only fill it out if it exists.
     let nameField = modal.textFields["Name"]
     if nameField.exists {
     nameField.tap()
     nameField.typeText("Jane Done")
     }
     
     modal.buttons["Join Link"].tap()
     
     // Because we are presenting view controllers with `modalPresentationStyle = .overFullScreen`,
     // there are currently 2 card forms on screen. Specifying a container helps the `fillCardData()`
     // method operate on the correct card form.
     try fillCardData(app, container: modal)
     
     // Pay!
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let successText = app.staticTexts["Success!"]
     XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
     }
     */
    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation_ManualConfirmation() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mc
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testDeferredPaymentIntent_ApplePay_ServerSideConfirmation_Multiprocessor() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.integrationType = .deferred_mp
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let applePayButton = app.buttons["apple_pay_button"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 4.0))
        applePayButton.tap()

        payWithApplePay()
    }

    func testPaymentSheetFlowControllerSaveAndRemoveCard_DeferredIntent_ServerSideConfirmation() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.applePayEnabled = .off // disable Apple Pay
        settings.apmsEnabled = .off
        // This test case is testing a feature not available when Link is on,
        // so we must manually turn off Link.
        settings.linkPassthroughMode = .passthrough
        settings.integrationType = .deferred_ssc
        settings.uiStyle = .flowController

        loadPlayground(app, settings)

        var paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

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
        app.buttons["Confirm"].tap()
        var successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()
        try! fillCardData(app)  // If the previous card was saved, we'll be on the 'saved pms' screen and this will fail

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
        paymentMethodButton = app.staticTexts["•••• 4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        app.buttons["CircularButton.Edit"].waitForExistenceAndTap()

        let removeButton = app.buttons["Remove"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 60.0))
        removeButton.tap()

        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 60.0))
        confirmRemoval.tap()

        // Should recognize no more pms available and switch to add screen
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 3))
    }
}

class PaymentSheetExternalPMUITests: PaymentSheetUITestCase {
    // MARK: - External PayPal
    func testExternalPaypalPaymentSheet() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.externalPaymentMethods = .paypal

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        let payButton = app.buttons["Pay $50.99"]
        guard let paypal = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "PayPal") else {
            XCTFail()
            return
        }
        paypal.tap()
        payButton.tap()
        XCTAssertNotNil(app.staticTexts["Confirm external_paypal?"])
        app.buttons["Cancel"].tap()

        payButton.tap()
        app.buttons["Fail"].tap()
        XCTAssertTrue(app.staticTexts["Something went wrong!"].waitForExistence(timeout: 5.0))

        payButton.tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 5.0))
    }

    func testExternalPaypalPaymentSheetFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.externalPaymentMethods = .paypal
        settings.uiStyle = .flowController

        loadPlayground(app, settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()

        scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "PayPal")?.waitForExistenceAndTap()

        app.buttons["Continue"].tap()

        // Verify EPMs vend the correct PaymentOptionDisplayData
        XCTAssertTrue(app.staticTexts["PayPal"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.staticTexts["external_paypal"].waitForExistence(timeout: 5.0))

        app.buttons["Confirm"].tap()

        XCTAssertNotNil(app.staticTexts["Confirm external_paypal?"])
        app.buttons["Cancel"].tap()
        XCTAssertNotNil(app.staticTexts["Payment canceled."])

        let payButton = app.buttons["Confirm"]
        payButton.tap()
        app.buttons["Fail"].tap()
        XCTAssertTrue(app.staticTexts["Payment failed: Error Domain= Code=0 \"Something went wrong!\" UserInfo={NSLocalizedDescription=Something went wrong!}"].waitForExistence(timeout: 5.0))

        payButton.tap()
        app.alerts.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 5.0))
    }
}
class PaymentSheetCustomerSessionDedupeUITests: PaymentSheetUITestCase {
    // MARK: - Customer Session
    func testDedupedPaymentMethods_paymentSheet() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerKeyType = .legacy
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .pm
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app)

        // Complete payment
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].isEnabled)
        // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
        XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1))

        // Add another PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].isEnabled)

        // Assert there are two payment methods using legacy customer ephemeral key
        XCTAssertEqual(app.staticTexts.matching(identifier: "•••• 4242").count, 2)

        // Close sheet
        app.buttons["Close"].waitForExistenceAndTap()

        // Change to CustomerSessions
        app.buttons["customer_session"].waitForExistenceAndTap()

        // Switch to see all payment methods
        app.buttons["CSSettings"].waitForExistenceAndTap(timeout: 3)
        app.buttons["PaymentMethodRedisplayFilters, always"].waitForExistenceAndTap(timeout: 3)
        app.buttons["unspecified_limited_always"].waitForExistenceAndTap(timeout: 3)
        app.buttons["Done"].waitForExistenceAndTap(timeout: 3)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))
        // Assert there is only a single payment method using CustomerSession
        XCTAssertEqual(app.staticTexts.matching(identifier: "•••• 4242").count, 1)
        app.buttons["Close"].waitForExistenceAndTap()
    }

    func testDedupedPaymentMethods_FlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerKeyType = .legacy
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .pm
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(app, settings)

        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to None
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.staticTexts["•••• 4242"].waitForExistenceAndTap()  // The card should be saved now and selected as default instead of Apple Pay
        XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 5))

        // Add another PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Should be able to edit two saved PMs
        reload(app, settings: settings)
        app.staticTexts["•••• 4242"].waitForExistenceAndTap()

        // Wait for the sheet to appear
        XCTAssertTrue(app.buttons["+ Add"].waitForExistence(timeout: 3))

        // Scroll all the way over
        XCTAssertNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove"))

        // Assert there are two payment methods using legacy customer ephemeral key
        // value == 3, 1 value on playground + 2 payment method
        XCTAssertEqual(app.staticTexts.matching(identifier: "•••• 4242").count, 3)

        // Close sheet
        app.buttons["Close"].waitForExistenceAndTap()

        // Change to CustomerSessions
        app.buttons["customer_session"].waitForExistenceAndTap()

        // Switch to see all payment methods
        app.buttons["CSSettings"].waitForExistenceAndTap(timeout: 3)
        app.buttons["PaymentMethodRedisplayFilters, always"].waitForExistenceAndTap(timeout: 3)
        app.buttons["unspecified_limited_always"].waitForExistenceAndTap(timeout: 3)
        app.buttons["Done"].waitForExistenceAndTap(timeout: 3)

        reload(app, settings: settings)
        app.staticTexts["•••• 4242"].waitForExistenceAndTap()

        // Assert there is only a single payment method using CustomerSession
        // value == 2, 1 value on playground + 1 payment method
        XCTAssertEqual(app.staticTexts.matching(identifier: "•••• 4242").count, 2)
        app.buttons["Close"].waitForExistenceAndTap()
    }
    // MARK: - Remove last saved PM

    func testRemoveLastSavedPaymentMethodPaymentSheet_clientConfig() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkDisplay = .never
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        settings.customerKeyType = .legacy

        try _testRemoveLastSavedPaymentMethodPaymentSheet(settings: settings, hasEditPMFunction: false)
    }
    func testRemoveLastSavedPaymentMethodPaymentSheet() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkDisplay = .never

        settings.allowsRemovalOfLastSavedPaymentMethod = .on
        settings.customerKeyType = .customerSession
        settings.paymentMethodRemoveLast = .disabled
        settings.paymentMethodSave = .enabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .on

        try _testRemoveLastSavedPaymentMethodPaymentSheet(settings: settings, tapCheckboxWithText: "Save payment details to Example, Inc. for future purchases", hasEditPMFunction: true)
    }
    func _testRemoveLastSavedPaymentMethodPaymentSheet(settings: PaymentSheetTestPlaygroundSettings, tapCheckboxWithText: String? = nil, hasEditPMFunction: Bool) throws {
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app, tapCheckboxWithText: tapCheckboxWithText)

        // Complete payment
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].isEnabled)

        if hasEditPMFunction {
            // Go to the edit screen
            XCTAssertTrue(app.buttons["Edit"].waitForExistenceAndTap())
            XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there
            XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 3))

            // Shouldn't be able to remove non-CBC eligible card when removeLast is disabled
            XCTAssertFalse(app.buttons["Remove"].waitForExistence(timeout: 1))
            XCTAssertTrue(app.buttons["Back"].waitForExistenceAndTap(timeout: 3))
            XCTAssertTrue(app.buttons["Done"].waitForExistenceAndTap(timeout: 3))
        } else {
            // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
            XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1))
        }

        // Add another PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "5555555555554444", tapCheckboxWithText: tapCheckboxWithText)

        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].isEnabled)
        // Should be able to edit two saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Edit")?.tap())
        XCTAssertTrue(app.buttons["Remove"].waitForExistenceAndTap())
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        if hasEditPMFunction {
            XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 3))
            XCTAssertFalse(app.buttons["Remove"].waitForExistence(timeout: 1))
            XCTAssertTrue(app.buttons["Back"].waitForExistenceAndTap(timeout: 3))
            XCTAssertTrue(app.buttons["Close"].waitForExistenceAndTap(timeout: 3))
        } else {
            // Should be kicked out of edit mode now that we have one saved PM
            XCTAssertFalse(app.staticTexts["Done"].waitForExistence(timeout: 1)) // "Done" button is gone - we are not in edit mode
            XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1)) // "Edit" button is gone - we can't edit
            XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 1))
            app.buttons["Close"].waitForExistenceAndTap()
        }
        // Reload w/ same customer & ensure 5555 card was detached
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay $50.99"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pay $50.99"].isEnabled)
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.staticTexts["•••• 5555"].waitForExistence(timeout: 1))
    }

    func test_RemoveLastSavedPaymentMethodFlowController_clientConfig() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkDisplay = .never

        settings.customerKeyType = .legacy
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(app, settings)

        try _testRemoveLastSavedPaymentMethodFlowController(settings: settings, hasEditPMFunction: false)
    }
    func test_RemoveLastSavedPaymentMethodFlowController_customerSession() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.linkDisplay = .never

        settings.customerKeyType = .customerSession
        settings.paymentMethodRemoveLast = .disabled
        settings.paymentMethodSave = .enabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .on
        loadPlayground(app, settings)

        try _testRemoveLastSavedPaymentMethodFlowController(settings: settings,
                                                            tapCheckboxWithText: "Save payment details to Example, Inc. for future purchases",
                                                            hasEditPMFunction: true)
    }

    func _testRemoveLastSavedPaymentMethodFlowController(settings: PaymentSheetTestPlaygroundSettings, tapCheckboxWithText: String? = nil, hasEditPMFunction: Bool) throws {
        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app, tapCheckboxWithText: tapCheckboxWithText)

        // Complete payment
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.staticTexts["•••• 4242"].waitForExistenceAndTap()  // The card should be saved now and selected as default instead of Apple Pay

        if hasEditPMFunction {
            // Go to the edit screen
            XCTAssertTrue(app.buttons["Edit"].waitForExistenceAndTap())
            XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there
            XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 3))

            // Shouldn't be able to remove non-CBC eligible card when removeLast is disabled
            XCTAssertFalse(app.buttons["Remove"].waitForExistence(timeout: 1))
            XCTAssertTrue(app.buttons["Back"].waitForExistenceAndTap(timeout: 3))
            XCTAssertTrue(app.buttons["Done"].waitForExistenceAndTap(timeout: 3))
        } else {
            // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
            XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1))
        }
        // Ensure we can tap another payment method, which will dismiss Flow Controller
        app.buttons["Apple Pay"].waitForExistenceAndTap()

        // Re-present the sheet
        app.staticTexts["apple_pay"].waitForExistenceAndTap()  // The Apple Pay is now the default because we tapped it

        // Add another PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "5555555555554444", tapCheckboxWithText: tapCheckboxWithText)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Should be able to edit two saved PMs
        reload(app, settings: settings)
        app.staticTexts["•••• 4444"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Edit")?.tap())
        XCTAssertTrue(app.buttons["Remove"].waitForExistenceAndTap())
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        if hasEditPMFunction {
            XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 3))
            XCTAssertFalse(app.buttons["Remove"].waitForExistence(timeout: 3))
        } else {
            // Should be kicked out of edit mode now that we have one saved PM
            XCTAssertFalse(app.staticTexts["Done"].waitForExistence(timeout: 1)) // "Done" button is gone - we are not in edit mode
            XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1)) // "Edit" button is gone - we can't edit
            XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 1))
        }
    }

    func test_updatePaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .returning
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.linkEnabledMode = .off
        settings.linkDisplay = .never

        settings.customerKeyType = .customerSession
        loadPlayground(app, settings)
        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 15))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap())

        // Test incomplete date
        let expField = app.textFields["expiration date"]
        XCTAssertTrue(expField.waitForExistence(timeout: 3.0))
        expField.tap()
        expField.typeText(XCUIKeyboardKey.delete.rawValue)
        expField.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertTrue(app.buttons["Save"].waitForExistenceAndTap(timeout: 3.0))
        XCTAssertTrue(app.staticTexts["Your card's expiration date is incomplete."].waitForExistence(timeout: 3.0))

        // Test expired card
        expField.tap()
        expField.typeText("99")
        XCTAssertTrue(app.staticTexts["Your card has expired."].waitForExistence(timeout: 3.0))

        // Enter valid date of mm/32
        expField.typeText(XCUIKeyboardKey.delete.rawValue)
        expField.typeText(XCUIKeyboardKey.delete.rawValue)
        expField.typeText("32")

        app.textFields["Country or region"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States")
        app.toolbars.buttons["Done"].tap()

        let zipField = app.textFields["ZIP"]
        XCTAssertTrue(expField.waitForExistence(timeout: 3.0))
        zipField.tap()
        zipField.typeText("55555")
        XCTAssertTrue(app.buttons["Save"].waitForExistenceAndTap(timeout: 3.0))

        // Close Sheet
        XCTAssertTrue(app.staticTexts["Done"].waitForExistenceAndTap(timeout: 15))
        XCTAssertTrue(app.buttons["Close"].waitForExistenceAndTap(timeout: 3))

        // Reload w/ same settings to verify date was persisted
        reload(app, settings: settings)
        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should still default to apple
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 15))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(expField.waitForExistence(timeout: 3.0))
        guard let expirationDate = expField.value as? String,
              let zipCode = zipField.value as? String else {
            XCTFail("Unable to get values from fields")
            return
        }

        XCTAssertEqual(expirationDate.suffix(3), "/32")
        XCTAssertEqual(zipCode, "55555")
    }
    func test_updatePaymentMethod_fullBilling() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .returning
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.linkEnabledMode = .off
        settings.collectAddress = .full

        settings.customerKeyType = .customerSession
        loadPlayground(app, settings)
        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 15))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap())

        app.textFields["Country or region"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States")
        app.toolbars.buttons["Done"].tap()

        app.textFields["State"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Alabama")
        app.toolbars.buttons["Done"].tap()

        let line1Field = app.textFields["Address line 1"]
        XCTAssertTrue(line1Field.waitForExistence(timeout: 3.0))
        line1Field.tap()
        line1Field.typeText("123 main")

        let cityField = app.textFields["City"]
        XCTAssertTrue(cityField.waitForExistence(timeout: 3.0))
        cityField.tap()
        cityField.typeText("San Francisco")

        let zipField = app.textFields["ZIP"]
        XCTAssertTrue(zipField.waitForExistence(timeout: 3.0))
        zipField.tap()
        zipField.typeText("12345" + XCUIKeyboardKey.return.rawValue)

        XCTAssertTrue(app.buttons["Save"].waitForExistenceAndTap(timeout: 3.0))

        // Close Sheet
        XCTAssertTrue(app.staticTexts["Done"].waitForExistenceAndTap(timeout: 15))
        XCTAssertTrue(app.buttons["Close"].waitForExistenceAndTap(timeout: 3))

        // Reload w/ same settings to verify date was persisted
        reload(app, settings: settings)
        app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should still default to apple
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 15))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap())

        let stateField = app.textFields["State"]
        let countryField = app.textFields["Country or region"]
        XCTAssertTrue(stateField.waitForExistence(timeout: 3.0))
        XCTAssertTrue(countryField.waitForExistence(timeout: 3.0))

        guard let line1 = line1Field.value as? String,
              let city = cityField.value as? String,
              let state = stateField.value as? String,
              let zipCode = zipField.value as? String,
              let country = countryField.value as? String else {
            XCTFail("Unable to get values from fields")
            return
        }
        XCTAssertEqual(line1, "123 main")
        XCTAssertEqual(city, "San Francisco")
        XCTAssertEqual(state, "Alabama")
        XCTAssertEqual(zipCode, "12345")
        XCTAssertEqual(country, "United States")
    }
}

class PaymentSheetCustomerSessionCBCUITests: PaymentSheetUITestCase {
    // MARK: - PaymentMethodRemoval w/ CBC
    func testPSPaymentMethodRemoveTwoCards() {

        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.customerKeyType = .customerSession
        settings.paymentMethodRedisplay = .enabled
        settings.paymentMethodAllowRedisplayFilters = .unspecified_limited_always
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.paymentMethodRemove = .disabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)

        // Complete payment
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app)
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Detect there are no remove buttons on each tile and the update screen
        XCTAssertNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: 5))
        XCTAssertFalse(app.buttons["Remove"].exists)

        app.buttons["Back"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Done"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Close"].waitForExistenceAndTap(timeout: 5)
    }
    func testPSPaymentMethodRemoveDisabled_keeplastSavedPaymentMethod_CBC_clientConfig() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.customerKeyType = .customerSession
        settings.paymentMethodRedisplay = .enabled
        settings.paymentMethodAllowRedisplayFilters = .unspecified_limited_always
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.paymentMethodRemove = .disabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .off

        _testPSPaymentMethodRemoveDisabled_keeplastSavedPaymentMethod_CBC(settings: settings)
    }
    func testPSPaymentMethodRemoveDisabled_keeplastSavedPaymentMethod_CBC_customerSession() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .paymentWithSetup
        settings.uiStyle = .paymentSheet
        settings.customerKeyType = .customerSession
        settings.paymentMethodRedisplay = .enabled
        settings.paymentMethodAllowRedisplayFilters = .unspecified_limited_always
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.applePayEnabled = .on
        settings.apmsEnabled = .off
        settings.paymentMethodRemove = .enabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .on
        settings.paymentMethodRemoveLast = .disabled

        _testPSPaymentMethodRemoveDisabled_keeplastSavedPaymentMethod_CBC(settings: settings)
    }

    func _testPSPaymentMethodRemoveDisabled_keeplastSavedPaymentMethod_CBC(settings: PaymentSheetTestPlaygroundSettings) {
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)

        // Complete payment
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Detect there are no remove buttons on each tile and the update screen
        XCTAssertNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertFalse(app.buttons["Remove"].exists)

        app.buttons["Back"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Done"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Close"].waitForExistenceAndTap(timeout: 5)
    }

    func testPreservesSelectionAfterDismissPaymentSheetFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new

        loadPlayground(app, settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        try fillCardData(app, tapCheckboxWithText: "Save payment details to Example, Inc. for future purchases")

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 5.0))
        reload(app, settings: settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()

        // Tap to dismiss PaymentSheet
        app.tapCoordinate(at: CGPoint(x: 100, y: 100))
        // Give time for the dismiss animation and the payment option to update
        sleep(2)

        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistenceAndTap(timeout: 10))
    }
}

class PaymentSheetCVCRecollectionUITests: PaymentSheetUITestCase {
    func testCVCRecollectionFlowController_deferredCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]

        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app)

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Confirm"].waitForExistenceAndTap()
        // CVC field should already be selected
        app.typeText("123")

        let confirmButtons: XCUIElementQuery = app.buttons.matching(identifier: "Confirm")
        for index in 0..<confirmButtons.count {
            if confirmButtons.element(boundBy: index).isHittable {
                confirmButtons.element(boundBy: index).tap()
            }
        }
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCVCRecollectionComplete_deferredCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .paymentSheet
        settings.integrationType = .deferred_csc
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app)

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Pay $50.99"].waitForExistenceAndTap(timeout: 5.0)

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let cvcField = app.textFields["CVC"]
        cvcField.forceTapWhenHittableInTestCase(self)
        app.typeText("123")
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCVCRecollectionFlowController_intentFirstCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.integrationType = .normal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        let paymentMethodButton = app.buttons["Payment method"]

        paymentMethodButton.waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app)

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        app.buttons["Confirm"].waitForExistenceAndTap()
        // CVC field should already be selected
        app.typeText("123")

        let confirmButtons: XCUIElementQuery = app.buttons.matching(identifier: "Confirm")
        for index in 0..<confirmButtons.count {
            if confirmButtons.element(boundBy: index).isHittable {
                confirmButtons.element(boundBy: index).tap()
            }
        }
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    func testCVCRecollectionComplete_intentFirstCSC() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .paymentSheet
        settings.integrationType = .normal
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.requireCVCRecollection = .on

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try! fillCardData(app)

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        let payButton = app.buttons["Pay $50.99"]
        XCTAssert(payButton.isEnabled)
        payButton.tap()

        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)

        XCTAssertFalse(successText.exists)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let cvcField = app.textFields["CVC"]
        cvcField.forceTapWhenHittableInTestCase(self)
        app.typeText("123")
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    func testLinkOnlyFlowController() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        // Use the GB merchant to use web-based Link
        settings.merchantCountryCode = .GB
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.applePayEnabled = .off
        settings.linkPassthroughMode = .pm

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["pay_with_link_button"].waitForExistenceAndTap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        // Cancel the Link sign in system dialog
        // Note: `addUIInterruptionMonitor` is flakey so we do this hack instead
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Cancel"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Payment canceled."].waitForExistence(timeout: 5))
        // Re-tapping the payment method button should present the main screen again
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Card information"].waitForExistence(timeout: 5))
    }

    /* Disable Link test
     func testDeferredIntentLinkSignIn_SeverSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try loginAndPay()
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkSignIn_ServerSideConfirmation_LostCardDecline() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistence(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let declineText = app.staticTexts["Your card was declined."]
     XCTAssertTrue(declineText.waitForExistence(timeout: 10.0))
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkFlowControllerFlow_SeverSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     "confirm_mode": "Server",
     ]
     )
     
     let paymentMethodButton = app.buttons["Select Payment Method"]
     XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"]
     XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].tap()
     
     try loginAndPay()
     }
     */
}

class PaymentSheetCardBrandFilteringUITests: PaymentSheetUITestCase {
    func testPaymentSheet_disallowedBrands() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.cardBrandAcceptance = .blockAmEx
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("3712")

        // Text should show that we cannot process American Express
        XCTAssertTrue(app.staticTexts["American Express is not accepted"].waitForExistence(timeout: 5.0))

        numberField.clearText()

        // Try and pay with a Visa
        try fillCardData(app)

        app.buttons["Pay $50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testPaymentSheet_allowedBrands() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.cardBrandAcceptance = .allowVisa
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("3712")

        // Text should show that we cannot process American Express
        XCTAssertTrue(app.staticTexts["American Express is not accepted"].waitForExistence(timeout: 5.0))

        numberField.clearText()

        // Try and pay with a Visa
        try fillCardData(app)

        app.buttons["Pay $50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
}

// MARK: - Link
class PaymentSheetLinkUITests: PaymentSheetUITestCase {
    // MARK: PaymentSheet Link inline signup

    // Tests the #1 flow in PaymentSheet where the merchant disable saved payment methods and first time Link user
    func testLinkPaymentSheet_disabledSPM_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .checkbox)
    }

    // Tests the #2 flow in PaymentSheet where the merchant disable saved payment methods and returning Link user
    func testLinkPaymentSheet_disabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #3 flow in PaymentSheet where the merchant enables saved payment methods, buyer has no SPMs and first time Link user
    func testLinkPaymentSheet_enabledSPM_noSPMs_firstTimeLinkUser() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .fieldConsent)
    }

    // Tests the #4 flow in PaymentSheet where the merchant enables saved payment methods, buyer has no SPMs and returning Link user
    func testLinkPaymentSheet_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests Native Link with a returning user, 2FA prompt shows first
    func testLinkPaymentSheet_native_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let codeField = app.textViews["Code field"]
        _ = codeField.waitForExistence(timeout: 5.0)
        codeField.typeText("000000")
        let pwlController = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let payButton = pwlController.buttons["Pay $50.99"]
        _ = payButton.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests Native Link in Flow Controller with a returning user
    func testLinkPaymentSheetFC_native_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.uiStyle = .flowController
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["Link"].waitForExistenceAndTap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        let codeField = app.textViews["Code field"]
        _ = codeField.waitForExistence(timeout: 5.0)
        codeField.typeText("000000")
        let pwlController = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let payButton = pwlController.buttons["Pay $50.99"]
        _ = payButton.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #5 flow in PaymentSheet where the merchant enables saved payment methods, buyer has SPMs and first time Link user
    func testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser_legacy() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.customerKeyType = .legacy
        _testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser(settings: settings)
    }
    func testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser_customerSession() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.customerKeyType = .customerSession
        _testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser(settings: settings)
    }
    func _testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser(settings: PaymentSheetTestPlaygroundSettings) {
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Begin by saving a card for this new user who is not signed up for Link
        try! fillCardData(app)

        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        fillLinkAndPay(mode: .fieldConsent, cardNumber: "5555555555554444")

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Ensure both PMs exist
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.staticTexts["•••• 4444"].waitForExistence(timeout: 5.0))
    }

    // Tests the #6 flow in PaymentSheet where the merchant enables saved payment methods, buyer has SPMs and returning Link user
    func testLinkPaymentSheet_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

        // Setup a saved card to simulate having saved payment methods
        try! fillCardData(app, postalEnabled: false) // postal pre-filled by default billing address

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        closeButton.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        assertLinkInlineSignupNotShown()
    }

    // MARK: PaymentSheet.FlowController Link inline signup

    // Tests the #7 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and saved payment methods and first time Link user
    // Seealso: testLinkOnlyFlowController for testing wallet button behavior in this flow
    func testLinkPaymentSheetFlow_disabledApplePay_disabledSPM_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .checkbox, uiStyle: .flowController)
    }

    // Tests the #8 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_disabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Ensure Link wallet button is shown
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #9 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and first time Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController)
    }

    // Tests the #10 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Ensure Link wallet button is shown
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #11 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and first time Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_hasSPMs_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Begin by saving a card for this new user who is not signed up for Link
        try! fillCardData(app)

        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)
        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController, showLinkWalletButton: false)
    }

    // Tests the #11.1 flow in PaymentSheet.FlowController where the merchant enables Apple Pay and enables saved payment methods and first time Link user
    func testLinkPaymentSheetFlow_enabledApplePay_enabledSPM_hasSPMs_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .on

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["+ Add"].waitForExistenceAndTap())
        // Begin by saving a card for this new user who is not signed up for Link
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        try! fillCardData(app)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController, showLinkWalletButton: false)
    }

    // Tests the #12 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Setup a saved card to simulate having saved payment methods
        try! fillCardData(app, postalEnabled: false) // postal pre-filled by default billing address

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        app.buttons["+ Add"].waitForExistenceAndTap()
        assertLinkInlineSignupNotShown() // Link should not be shown in this flow
    }

    // Tests the #12.1 flow in PaymentSheet.FlowController where the merchant enables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_enablesApplePay_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .on
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        app.buttons["+ Add"].waitForExistenceAndTap()
        assertLinkInlineSignupNotShown() // Link should not be shown in this flow
    }

    func testLinkPaymentSheetFlowController_returnsCardPaymentOptionDisplayDataForLinkInlineSignup() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        fillLinkCardAndSignup(mode: .checkbox)

        // Assert that card is the returned payment method type
        app.buttons["Continue"].tap()
        XCTAssertEqual(app.buttons["Payment method"].label, "•••• 4242, card, 12345, US")
    }

    func testLinkInlineSignup_gb() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.userOverrideCountry = .GB

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try fillCardData(app)

        app.switches["Save your info for secure 1-click checkout with Link"].tap()

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")

        let phoneField = app.textFields["Phone number"]
        // Phone field appears after the network call finishes. We want to wait for it to appear.
        XCTAssert(phoneField.waitForExistence(timeout: 10))
        phoneField.tap()
        phoneField.typeText("3105551234")

        // The name field is required for non-US countries
        let nameField = app.textFields["Full name"]
        XCTAssert(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Jane Doe")

        // Pay!
        app.buttons["Pay $50.99"].tap()

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    func testLinkInlineSignup_deferred() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .checkbox)
    }

    // MARK: Link bank payments

    func testLinkCardBrand() {
        _testInstantDebits(mode: .payment, useLinkCardBrand: true)
    }

    func testLinkCardBrand_flowController() {
        _testInstantDebits(mode: .payment, useLinkCardBrand: true, uiStyle: .flowController)
    }

    // MARK: Native Link bank payments

    func testBankPaymentInNativeLinkInPaymentMethodMode() {
        testBankPaymentInNativeLink(passthroughMode: false)
    }

    func testBankPaymentInNativeLinkInPassthroughMode() {
        testBankPaymentInNativeLink(passthroughMode: true)
    }

    private func testBankPaymentInNativeLink(passthroughMode: Bool) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .guest
        settings.linkPassthroughMode = passthroughMode ? .passthrough : .pm
        settings.defaultBillingAddress = .customEmail
        settings.customEmail = "foo@bar.com"
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = passthroughMode ? "card" : "card,link"
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Enter OTC in dialog
        let textField = app.textViews["Code field"]
        XCTAssertTrue(textField.waitForExistence(timeout: 10.0))
        textField.typeText("000000")

        app.otherElements["Stripe.Link.PaymentMethodPicker"].waitForExistenceAndTap(timeout: 10)

        let bankRow = app
            .otherElements
            .matching(NSPredicate(format: "label CONTAINS 'Test Institution'"))
            .firstMatch
        XCTAssertTrue(bankRow.waitForExistenceAndTap())

        app.buttons
            .matching(identifier: "Pay $50.99")
            .matching(NSPredicate(format: "isEnabled == true"))
            .firstMatch
            .waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // MARK: Native Link payments with billing details collection

    func testBillingDetailsCollectionInNativeLinkInPassthroughModeForNewUser() {
        testBillingDetailsCollectionInNativeLinkForNewUser(passthroughMode: true)
    }

    func testBillingDetailsCollectionInNativeLinkInPaymentMethodModeForNewUser() {
        testBillingDetailsCollectionInNativeLinkForNewUser(passthroughMode: false)
    }

    func testBillingDetailsCollectionInNativeLinkInPassthroughModeForExistingUser() {
        testBillingDetailsCollectionInNativeLinkForExistingUser(passthroughMode: true)
    }

    func testBillingDetailsCollectionInNativeLinkInPaymentMethodModeForExistingUser() {
        testBillingDetailsCollectionInNativeLinkForExistingUser(passthroughMode: false)
    }

    private func testBillingDetailsCollectionInNativeLinkForNewUser(passthroughMode: Bool) {
        let email = "billing_details_test+\(UUID().uuidString)@link.com"
        let cvc = "1234"

        let settings = createLinkPlaygroundSettings(
            passthroughMode: passthroughMode,
            collectBillingDetails: true
        )
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Sign up and add a payment method with billing details
        signUpFor(app, email: email)
        fillOutLinkCardData(app, cardNumber: "378282246310005", cvc: cvc, includingBillingDetails: true)

        payLink(app)
        assertLinkPaymentSuccess(app)
    }

    private func testBillingDetailsCollectionInNativeLinkForExistingUser(passthroughMode: Bool) {
        let email = "billing_details_test+\(UUID().uuidString)@link.com"
        let cvc = "1234"

        let settings = createLinkPlaygroundSettings(
            passthroughMode: passthroughMode,
            collectBillingDetails: false
        )
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Sign up and add a payment method without billing details
        signUpFor(app, email: email)
        fillOutLinkCardData(app, cardNumber: "378282246310005", cvc: cvc, includingBillingDetails: false)
        payLink(app)
        assertLinkPaymentSuccess(app)

        // Now request billing details
        let settingsWithBillingDetails = createLinkPlaygroundSettings(
            passthroughMode: passthroughMode,
            collectBillingDetails: true
        )
        loadPlayground(app, settingsWithBillingDetails)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Pay again
        logInToLink(app, email: email)

        // Enter CVC if requested
        let cvcField = app.textFields["CVC"]
        if cvcField.waitForExistence(timeout: 5) {
            cvcField.tap()
            cvcField.typeText(cvc)
        }

        payLink(app)

        // Fill out missing details
        XCTAssertTrue(app.staticTexts["Confirm payment details"].waitForExistence(timeout: 5))
        fillOutBillingDetails(app)

        payLink(app)
        assertLinkPaymentSuccess(app)
    }

    // MARK: Link test helpers

    private enum LinkMode {
        case checkbox
        case fieldConsent
    }

    private func fillLinkAndPay(mode: LinkMode,
                                uiStyle: PaymentSheetTestPlaygroundSettings.UIStyle = .paymentSheet,
                                showLinkWalletButton: Bool = true,
                                cardNumber: String? = nil) {

        fillLinkCardAndSignup(mode: mode, showLinkWalletButton: showLinkWalletButton, cardNumber: cardNumber)

        // Pay!
        switch uiStyle {
        case .paymentSheet:
            app.buttons["Pay $50.99"].tap()
        case .flowController:
            app.buttons["Continue"].tap()
            app.buttons["Confirm"].waitForExistenceAndTap()
        case .embedded:
            // TODO(porter) Fill in embedded UI test steps
            break
        }
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
        // Roundabout way to validate that signup completed successfully
        let signupCompleteAnalytic = analyticsLog.first { payload in
            payload["event"] as? String == "link.signup.complete"
        }
        XCTAssertNotNil(signupCompleteAnalytic)
    }

    private func fillLinkCardAndSignup(
        mode: LinkMode,
        showLinkWalletButton: Bool = true,
        cardNumber: String? = nil
    ) {
        try! fillCardData(app, cardNumber: cardNumber)

        if showLinkWalletButton {
            // Confirm Link wallet button is visible
            XCTAssertTrue(app.buttons["pay_with_link_button"].exists)
        }

        if mode == .checkbox {
            app.switches["Save your info for secure 1-click checkout with Link"].tap()
        }

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")

        let phoneField = app.textFields["Phone number"]
        XCTAssert(phoneField.waitForExistence(timeout: 10))
        phoneField.tap()
        phoneField.typeText("3105551234")

        // The name field is only required for non-US countries. Only fill it out if it exists.
        let nameField = app.textFields["Full name"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Jane Done")
        }
    }

    private func assertLinkInlineSignupNotShown() {
        // Ensure checkbox is not shown for checkbox mode
        XCTAssertFalse(app.switches["Save your info for secure 1-click checkout with Link"].waitForExistence(timeout: 2))
        // Ensure email is not shown for field consent mode
        XCTAssertFalse(app.textFields["Email"].waitForExistence(timeout: 3))
    }

//    TODO: This is disabled until the Link team adds some hooks for testing.
//    func testLinkWebFlow() throws {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.layout = .horizontal
//        settings.customerMode = .guest
//        settings.linkMode = .on
//
//        loadPlayground(app, settings)
//
//        app.buttons["Present PaymentSheet"].tap()
//
//        app.buttons["Pay with Link"].forceTapWhenHittableInTestCase(self)
//
//        // Allow link.com to sign in
//        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
//        springboard.buttons["Continue"].forceTapWhenHittableInTestCase(self)
//
//        let emailField = app.webViews.textFields.firstMatch
//        emailField.forceTapWhenHittableInTestCase(self)
//        emailField.typeText("test@example.com")
//
//        let verificationCodeField = app.webViews.staticTexts["•"]
//        verificationCodeField.forceTapWhenHittableInTestCase(self)
//        verificationCodeField.typeText("000000")
//
//        // Pay!
//        app.webViews.buttons["Pay $50.99"].tap()
//
//        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
//    }
}

class PaymentSheetDefaultSPMUITests: PaymentSheetUITestCase {
    func testDefaultSPMHorizontalNavigation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.customerMode = .returning
        settings.layout = .horizontal

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        app.buttons["Edit"].waitForExistenceAndTap()

        XCTAssertEqual(app.buttons.matching(identifier: "CircularButton.Edit").count, 2)
    }
    func testDefaultSPMVerticalNavigation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.customerMode = .returning
        settings.layout = .vertical

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()

        XCTAssertEqual(app.buttons.matching(identifier: "chevron").count, 2)
    }

    func testAddNewDefaultHorizontalNavigation_CustomerSession() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.customerKeyType = .customerSession
        settings.paymentMethodSetAsDefault = .enabled

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Add a card and set it as default
        try! fillCardData(app)
        // toggle save this card on
        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)
        // this card should be automatically set as the default, as there are no other saved pms
        XCTAssertFalse(app.switches["Set as default payment method"].waitForExistence(timeout: 3))

        // Complete payment
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, false)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_complete_payment_newpm_success" }.last?["set_as_default"] as? Bool, true)

        // Reload the sheet
        app.buttons["Reload"].waitForExistenceAndTap()
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Check that the card ending in 4242 is selected
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        app.buttons["Edit"].waitForExistenceAndTap()
        // Check that the card ending in 4242 has the default badge
        XCTAssertTrue(app.cells["•••• 4242"].staticTexts["Default"].waitForExistence(timeout: 3))
        app.cells["•••• 4242"].buttons["CircularButton.Edit"].waitForExistenceAndTap()
        // Ensure checkbox is not enabled if it's already the default
        var setDefaultToggle = app.switches["Default payment method"]
        XCTAssertTrue(setDefaultToggle.waitForExistence(timeout: 3))
        XCTAssertTrue(setDefaultToggle.isSelected)
        setDefaultToggle.tap()
        XCTAssertTrue(setDefaultToggle.isSelected)
        app.buttons["Back"].waitForExistenceAndTap()
        app.buttons["Done"].waitForExistenceAndTap()

        // Add a card and don't set it as default
        app.buttons["+ Add"].waitForExistenceAndTap()

        try! fillCardData(app, cardNumber: "5555555555554444")
        // toggle save this card on
        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)
        // do not set this card as default
        XCTAssertFalse(app.switches["Set as default payment method"].isSelected)

        // Complete payment
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_complete_payment_newpm_success" }.last?["set_as_default"] as? Bool, false)

        // Reload the sheet
        app.buttons["Reload"].waitForExistenceAndTap()
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Check that the card ending in 4242 is still selected
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        app.buttons["Edit"].waitForExistenceAndTap()
        // Check that the card ending in 4242 still has the default badge
        XCTAssertTrue(app.cells["•••• 4242"].staticTexts["Default"].waitForExistence(timeout: 3))
        app.cells["•••• 4242"].buttons["CircularButton.Edit"].waitForExistenceAndTap()
        // Ensure checkbox is not enabled if it's already the default
        setDefaultToggle = app.switches["Default payment method"]
        XCTAssertTrue(setDefaultToggle.waitForExistence(timeout: 3))
        XCTAssertTrue(setDefaultToggle.isSelected)
        setDefaultToggle.tap()
        XCTAssertTrue(setDefaultToggle.isSelected)
        app.buttons["Back"].waitForExistenceAndTap()
        app.cells["•••• 4444"].buttons["CircularButton.Edit"].waitForExistenceAndTap()
        // Ensure checkbox is enabled if it's not the default
        setDefaultToggle = app.switches["Set as default payment method"]
        XCTAssertTrue(setDefaultToggle.waitForExistence(timeout: 3))
        XCTAssertFalse(setDefaultToggle.isSelected)
        setDefaultToggle.tap()
        XCTAssertTrue(setDefaultToggle.isSelected)

        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, true)
    }

    func testSetAsDefaultHorizontalNavigation_CustomerSession() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .returning
        settings.customerKeyType = .customerSession
        settings.paymentMethodSetAsDefault = .enabled

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        XCTAssertEqual(app.buttons.matching(identifier: "CircularButton.Edit").count, 2)
        // Check that no payment method has been marked as default yet
        XCTAssertFalse(app.staticTexts["Default"].waitForExistence(timeout: 3))
        // Edit the card ending in 4242
        app.cells["•••• 4242"].buttons["CircularButton.Edit"].waitForExistenceAndTap()
        // Edit the card ending in 4242
        app.switches["Set as default payment method"].waitForExistenceAndTap()
        app.buttons["Save"].waitForExistenceAndTap()
        // Check that the card ending in 4242 has a default badge
        XCTAssertTrue(app.cells["•••• 4242"].staticTexts["Default"].waitForExistence(timeout: 3))
        XCTAssertEqual(analyticsLog.last?[string: "event"], "mc_set_default_payment_method")
        XCTAssertEqual(analyticsLog.last?[string: "payment_method_type"], "card")
        app.buttons["Done"].waitForExistenceAndTap()
        // Check that the card ending in 4242 is now selected
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, false)
        // Reload the sheet
        app.buttons["Reload"].waitForExistenceAndTap()
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Check that the card ending in 4242 is still selected
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        app.buttons["Edit"].waitForExistenceAndTap()
        // Check that the card ending in 4242 still has the default badge
        XCTAssertTrue(app.cells["•••• 4242"].staticTexts["Default"].waitForExistence(timeout: 3))
        app.cells["•••• 4242"].buttons["CircularButton.Edit"].waitForExistenceAndTap()
        // Ensure checkbox is not enabled if it's already the default
        let setDefaultToggle = app.switches["Default payment method"]
        XCTAssertTrue(setDefaultToggle.waitForExistence(timeout: 3))
        XCTAssertTrue(setDefaultToggle.isSelected)
        setDefaultToggle.tap()
        XCTAssertTrue(setDefaultToggle.isSelected)
        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, true)
    }

    func testSetAsDefaultVerticalNavigation_CustomerSession() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .vertical
        settings.customerMode = .returning
        settings.customerKeyType = .customerSession
        settings.paymentMethodSetAsDefault = .enabled

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        XCTAssertEqual(app.buttons.matching(identifier: "chevron").count, 2)
        // Edit the card ending in 4242
        app.buttons["•••• 4242"].waitForExistenceAndTap()
        // Edit the card ending in 4242
        app.switches["Set as default payment method"].waitForExistenceAndTap()
        app.buttons["Save"].waitForExistenceAndTap()
        app.buttons["Done"].waitForExistenceAndTap()
        // Check that the card ending in 4242 has a default badge and is selected
        XCTAssertTrue(app.buttons["Visa ending in 4 2 4 2, Default"].isSelected)
        XCTAssertEqual(analyticsLog.last?[string: "event"], "mc_set_default_payment_method")
        XCTAssertEqual(analyticsLog.last?[string: "payment_method_type"], "card")
        app.buttons["Back"].waitForExistenceAndTap()
        // Scroll down
        let startCoordinate = app.scrollViews.element(boundBy: 1).coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.1, thenDragTo: app.scrollViews.element(boundBy: 1).coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.1)))
        app.buttons["Pay $50.99"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, false)
        // Reload the sheet
        app.buttons["Reload"].waitForExistenceAndTap()
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Check that the card ending in 4242 is still selected
        XCTAssertTrue(app.buttons["•••• 4242"].isSelected)
        app.buttons["View more"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()
        // Check that the card ending in 4242 still has the default badge
        XCTAssertTrue(app.buttons["Visa ending in 4 2 4 2, Default"].waitForExistenceAndTap())
        // Ensure checkbox is not enabled if it's already the default
        let setDefaultToggle = app.switches["Default payment method"]
        XCTAssertTrue(setDefaultToggle.waitForExistence(timeout: 3))
        XCTAssertTrue(setDefaultToggle.isSelected)
        setDefaultToggle.tap()
        XCTAssertTrue(setDefaultToggle.isSelected)
        // Check analytics
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["set_as_default_enabled"] as? Bool, true)
        XCTAssertEqual(analyticsLog.filter { $0[string: "event"] == "mc_load_succeeded" }.last?["has_default_payment_method"] as? Bool, true)
    }
}

// MARK: Helpers
extension PaymentSheetUITestCase {
    func _testUSBankAccount(mode: PaymentSheetTestPlaygroundSettings.Mode, integrationType: PaymentSheetTestPlaygroundSettings.IntegrationType, vertical: Bool = false) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        settings.mode = mode
        settings.customerKeyType = .customerSession
        settings.integrationType = integrationType
        if vertical {
            settings.layout = .vertical
        }

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select US bank account
        if vertical {
            XCTAssertTrue(app.buttons["US bank account"].waitForExistenceAndTap())
        } else {
            XCTAssertTrue(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US bank account")?.waitForExistenceAndTap() ?? false)
        }

        // Fill out name and email fields
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Full name"].tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test-\(UUID().uuidString)@example.com" + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].tap()
        app.staticTexts["Test Institution"].forceTapElement()
        // "Success" institution is automatically selected because its the first
        app.buttons["connect_accounts_button"].waitForExistenceAndTap(timeout: 10)

        skipLinkSignup(app)

        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        // Make sure bottom notice mandate is visible
        let paymentMandateText = "By continuing, you agree to authorize payments pursuant to these terms."
        let setupMandateText = "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."

        switch mode {
        case .payment:
            // Save the payment method
            XCTAssertTrue(app.textViews[paymentMandateText].waitForExistence(timeout: 5))
            let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()

            // Tapping the checkbox changes the mandate
            XCTAssertTrue(app.textViews[setupMandateText].waitForExistence(timeout: 5))
        default:
            // Since the payment method is being set up, it always shows the setup mandate
            XCTAssertTrue(app.textViews[setupMandateText].waitForExistence(timeout: 5))
            let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()

            // Tapping the checkbox doesn't change the mandate
            XCTAssertTrue(app.textViews[setupMandateText].waitForExistence(timeout: 5))
        }

        // Confirm
        let confirmButtonText = mode == .payment ? "Pay $50.99" : "Set up"

        app.buttons[confirmButtonText].waitForExistenceAndTap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload and pay with the now-saved US bank account
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].tap()
        XCTAssertTrue(app.buttons["••••6789"].waitForExistenceAndTap())

        // Make sure bottom notice mandate is visible
        XCTAssertTrue(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].exists)

        app.buttons[confirmButtonText].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }

    func _testInstantDebits(
        mode: PaymentSheetTestPlaygroundSettings.Mode,
        vertical: Bool = false,
        useLinkCardBrand: Bool = false,
        uiStyle: PaymentSheetTestPlaygroundSettings.UIStyle = .paymentSheet
    ) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = mode
        settings.uiStyle = uiStyle
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = useLinkCardBrand ? "card" : "card,link"
        if vertical {
            settings.layout = .vertical
        }

        loadPlayground(app, settings)

        if uiStyle == .flowController {
            app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
            app.buttons["+ Add"].waitForExistenceAndTap()
        } else {
            app.buttons["Present PaymentSheet"].tap()
        }

        // Select "Bank"
        if vertical {
            XCTAssertTrue(app.buttons["Bank"].waitForExistenceAndTap())
        } else {
            XCTAssertTrue(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Bank")?.waitForExistenceAndTap() ?? false)
        }
        let email = "paymentsheetuitest-\(UUID().uuidString)@example.com"

        // Fill out name and email fields
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Email"].tap()
        app.typeText(email + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        Self.stepThroughNativeInstantDebitsFlow(app: app)

        // Back to Payment Sheet
        switch uiStyle {
        case .paymentSheet:
            app.buttons[mode == .setup ? "Set up" : "Pay $50.99"].waitForExistenceAndTap(timeout: 10)
        case .flowController, .embedded:
            // Give time for the dismiss animation
            sleep(2)
            app.buttons["Continue"].waitForExistenceAndTap(timeout: 10)
            XCTAssertTrue(app.staticTexts["••••6789"].waitForExistence(timeout: 10))
            app.buttons["Confirm"].waitForExistenceAndTap(timeout: 10)
        }

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    func payWithApplePay() {
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)

        let predicate = NSPredicate(format: "label CONTAINS 'Simulated Card - AmEx, ‪•••• 1234‬'")

        let cardButton = applePay.buttons.containing(predicate).firstMatch
        XCTAssertTrue(cardButton.waitForExistence(timeout: 10.0))
        cardButton.forceTapElement()

        addApplePayBillingIfNeeded(applePay)

        let cardSelectionButton = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].firstMatch
        XCTAssertTrue(cardSelectionButton.waitForExistence(timeout: 10.0))
        cardSelectionButton.forceTapElement()

        let payButton = applePay.buttons["Pay with Passcode"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 10.0))
        payButton.forceTapElement()

        let successText = app.staticTexts["Success!"]
        //      This actually takes upwards of 20 seconds sometimes, especially in the deferred flow :/
        XCTAssertTrue(successText.waitForExistence(timeout: 30.0))
    }

    func addApplePayBillingIfNeeded(_ applePay: XCUIApplication) {
        // Fill out billing details if required
        let addBillingDetailsButton = applePay.buttons["Add Billing Address"]
        if addBillingDetailsButton.waitForExistence(timeout: 4.0) {
            addBillingDetailsButton.tap()

            let firstNameCell = applePay.textFields["First Name"]
            firstNameCell.tap()
            firstNameCell.typeText("Jane")

            let lastNameCell = applePay.textFields["Last Name"]
            lastNameCell.tap()
            lastNameCell.typeText("Doe")

            let streetCell = applePay.textFields["Street"]
            streetCell.tap()
            streetCell.typeText("One Apple Park Way")

            let cityCell = applePay.textFields["City"]
            cityCell.tap()
            cityCell.typeText("Cupertino")

            let stateCell = applePay.textFields["State"]
            stateCell.tap()
            stateCell.typeText("CA")

            let zipCell = applePay.textFields["ZIP"]
            zipCell.tap()
            zipCell.typeText("95014")

            applePay.buttons["Done"].tap()
        }
    }

    func _testCardBrandChoice(isSetup: Bool = false, settings: PaymentSheetTestPlaygroundSettings) {
        app.buttons["Present PaymentSheet"].tap()

        let cardBrandTextField = app.textFields["Select card brand (optional)"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistence(timeout: 2))

        let numberField = app.textFields["Card number"]
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeUp()
        app.toolbars.buttons["Cancel"].tap()

        // We should still have no selected card brand
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistence(timeout: 2))

        // Select Visa from the CBC dropdown
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeUp()
        app.toolbars.buttons["Done"].tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].waitForExistence(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeUp() // Swipe to select Visa
        app.toolbars.buttons["Done"].tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Finish checkout
        let confirmButtonText = isSetup ? "Set up" : "Pay €50.99"
        app.buttons[confirmButtonText].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    static func stepThroughNativeInstantDebitsFlow(app: XCUIApplication, emailPrefilled: Bool = true) {
        // "Consent" pane
        app.buttons["Agree and continue"].waitForExistenceAndTap(timeout: 10)

        // "Sign Up" pane
        if !emailPrefilled {
            app.textFields
                .matching(NSPredicate(format: "label CONTAINS 'Email address'"))
                .firstMatch
                .waitForExistenceAndTap(timeout: 10)
            let email = "linkpaymentcontrolleruitest-\(UUID().uuidString)@example.com"
            app.typeText(email + XCUIKeyboardKey.return.rawValue)
        }

        let phoneTextField = app.textFields["phone_text_field"]
        XCTAssertTrue(phoneTextField.waitForExistence(timeout: 10.0), "Failed to find phone text field")

        let countryCodeSelector = app.otherElements["phone_country_code_selector"]
        XCTAssertTrue(countryCodeSelector.waitForExistence(timeout: 10.0), "Failed to find phone text field")
        countryCodeSelector.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States (+1)")
        app.toolbars.buttons["Done"].tap()

        phoneTextField.tap()
        phoneTextField.typeText("4015006000")

        let linkLoginCtaButton = app.buttons["link_login.primary_button"]
        XCTAssertTrue(linkLoginCtaButton.waitForExistence(timeout: 10.0))
        linkLoginCtaButton.tap()

        // "Institution picker" pane
        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Payment Success"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        let accountPickerLinkAccountsButton = app.buttons["connect_accounts_button"]
        XCTAssertTrue(accountPickerLinkAccountsButton.waitForExistence(timeout: 120.0), "Failed to open Account Picker pane - \(#function) waiting failed")  // wait for accounts to fetch
        XCTAssert(accountPickerLinkAccountsButton.isEnabled, "no account selected")
        accountPickerLinkAccountsButton.tap()

        // "Success" pane
        let successDoneButton = app.buttons["success_done_button"]
        XCTAssertTrue(successDoneButton.waitForExistence(timeout: 120.0), "Failed to open Success pane - \(#function) waiting failed")  // wait for accounts to link
        successDoneButton.tap()
    }
}

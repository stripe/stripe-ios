//
//  PaymentSheetCustomerSessionDedupeUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

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
        line1Field.clearText()
        line1Field.typeText("123 main")

        let cityField = app.textFields["City"]
        XCTAssertTrue(cityField.waitForExistence(timeout: 3.0))
        cityField.tap()
        cityField.clearText()
        cityField.typeText("San Francisco")

        let zipField = app.textFields["ZIP"]
        XCTAssertTrue(zipField.waitForExistence(timeout: 3.0))
        zipField.tap()
        zipField.clearText()
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
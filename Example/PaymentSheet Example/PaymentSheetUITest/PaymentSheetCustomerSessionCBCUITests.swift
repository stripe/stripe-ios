//
//  PaymentSheetCustomerSessionCBCUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

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
        settings.confirmationMode = .paymentMethod

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
        settings.confirmationMode = .paymentMethod

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
        settings.confirmationMode = .paymentMethod

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
//
//  PaymentSheetDefaultSPMUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

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
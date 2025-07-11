//
//  PaymentSheet_AddressTests.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 6/16/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheet_AddressTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
    }

    // REMOVED: testManualAddressEntry() - Migrated to AddressValidationTests.swift unit tests
    // The core address validation logic is now tested at the unit level for better performance and reliability

    // REMOVED: testAddressWithDefaults() - Migrated to AddressValidationTests.swift unit tests
    // Address defaults logic is now tested at the unit level with mock data

    // REMOVED: testAddressAutoComplete_UnitedStates() - Migrated to AddressAutocompleteTests.swift unit tests
    // Address autocomplete logic is now tested at the unit level with mock API responses

    // REMOVED: testAddressAutoComplete_NewZeland() - Migrated to AddressAutocompleteTests.swift unit tests
    // Unsupported country logic is now tested at the unit level without UI automation

    // CRITICAL E2E TEST: This test validates complex state management between shipping and billing addresses
    // across multiple UI components. This integration cannot be easily replicated in unit tests.
    func testPaymentSheetFlowControllerUpdatesShipping() {

            var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.applePayEnabled = .off
        settings.apmsEnabled = .off
        settings.linkPassthroughMode = .passthrough
        settings.uiStyle = .flowController
        settings.shippingInfo = .on
            loadPlayground(
                app,
                settings
            )

        // Using PaymentSheet.FlowController w/o a shipping address...
        app.buttons["Payment method"].waitForExistenceAndTap()

        // ...should not show the "Billing address is same as shipping" checkbox
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "")
        XCTAssertFalse(app.switches["Billing address is same as shipping"].exists)
        app.buttons["Close"].tap()

        // Entering a shipping address...
        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        app.textFields["Full name"].tap()
        app.textFields["Full name"].typeText("Jane Doe")
        // Tapping the address field should go to autocomplete
        app.textFields["Address"].waitForExistenceAndTap()
        app.buttons["Enter address manually"].waitForExistenceAndTap()
        app.textFields["Address line 1"].waitForExistenceAndTap()
        app.typeText("510 Townsend St")
        app.textFields["City"].tap()
        app.typeText("San Francisco")
        app.textFields["State"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
        app.toolbars.buttons["Done"].tap()
        app.typeText("California")
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        app.buttons["Save address"].tap()

        // ...and then using PaymentSheet.FlowController...
        app.buttons["Payment method"].waitForExistenceAndTap()

        // ...should show the "Billing address is same as shipping" checkbox selected and set the address values to shipping
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")
        XCTAssertTrue(app.switches["Billing address is same as shipping"].isSelected)

        // Updating the shipping address country...
        app.buttons["Close"].tap()
        app.buttons["Address"].tap()
        app.textFields["Country or region"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇨🇦 Canada")
        app.toolbars.buttons["Done"].tap()
        app.textFields["Province"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Ontario")
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save address"].tap()

        // ...should update PaymentSheet.FlowController
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "Canada")

        // If you change the billing address, however...
        let updatedBillingAddressPostalCode = "12345"
        app.textFields["Postal code"].tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5)
        app.textFields["Postal code"].typeText(deleteString + updatedBillingAddressPostalCode)

        // ...the "Billing address is same as shipping" checkbox should become deselected...
        XCTAssertFalse(app.switches["Billing address is same as shipping"].isSelected)

        // ...and changing the shipping address...
        app.buttons["Close"].tap()
        app.buttons["Address"].tap()
        app.textFields["Country or region"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States")
        app.toolbars.buttons["Done"].tap()
        app.textFields["State"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save address"].tap()

        // ...should not affect your billing address...
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "Canada")
        XCTAssertEqual(app.textFields["Postal code"].value as? String, updatedBillingAddressPostalCode)

        // ...until 'Billing address is same as shipping' checkbox is selected again
        app.switches["Billing address is same as shipping"].tap()
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")
    }

    // REMOVED: testManualAddressEntry_phoneCountryDoesPersist() - Migrated to AddressValidationTests.swift unit tests
    // Phone country persistence logic is now tested at the unit level

    // CRITICAL E2E TEST: This test validates complex UI state synchronization between shipping and billing
    // address forms, including checkbox behavior and field auto-population. This is a critical user flow.
    func testShippingEqualsBillingCheckboxAutoUncheck() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.shippingInfo = .onWithDefaults

        loadPlayground(app, settings)
        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        let checkbox = app.switches["Use billing address for shipping"]
        XCTAssertTrue(checkbox.waitForExistence(timeout: 2.0))
        XCTAssertTrue(checkbox.isSelected)

        // Get references to all fields we'll validate
        let nameField = app.textFields["Full name"]
        let line1Field = app.textFields["Address line 1"]
        let cityField = app.textFields["City"]
        let stateField = app.textFields["State"]
        let postalField = app.textFields["ZIP"]
        let phoneField = app.textFields["Phone number"]

        // Validate initial state - all fields should be populated with defaults
        XCTAssertEqual(nameField.value as? String, "Jane Doe")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(postalField.value as? String, "94102")
        XCTAssertEqual(phoneField.value as? String, "(555) 555-5555")

        // 1. Manually toggle off -> validate text fields are cleared (dropdowns keep their values)
        checkbox.tap()
        XCTAssertFalse(checkbox.isSelected)
        XCTAssertEqual(nameField.value as? String ?? "", "")
        XCTAssertEqual(line1Field.value as? String ?? "", "")
        XCTAssertEqual(cityField.value as? String ?? "", "")
        // Note: stateField is a dropdown and doesn't clear to empty
        XCTAssertEqual(postalField.value as? String ?? "", "")
        XCTAssertEqual(phoneField.value as? String ?? "", "")

        // Toggle back on -> validate all fields are repopulated
        checkbox.tap()
        XCTAssertTrue(checkbox.isSelected)
        XCTAssertEqual(nameField.value as? String, "Jane Doe")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(postalField.value as? String, "94102")
        XCTAssertEqual(phoneField.value as? String, "(555) 555-5555")

        // 2. Edit line1 to be different -> checkbox auto-unchecks
        line1Field.tap()
        let existingValue = line1Field.value as? String ?? ""
        line1Field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        line1Field.typeText("123 New St")
        XCTAssertFalse(checkbox.isSelected)

        // 3. Change value back to original default -> checkbox should re-check automatically
        line1Field.tap()
        line1Field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "123 New St".count))
        line1Field.typeText("510 Townsend St.")
        XCTAssertTrue(checkbox.isSelected)

        // 4. User unchecks again -> validate text fields clear (dropdowns keep their values)
        checkbox.tap()
        XCTAssertFalse(checkbox.isSelected)
        XCTAssertEqual(nameField.value as? String ?? "", "")
        XCTAssertEqual(line1Field.value as? String ?? "", "")
        XCTAssertEqual(cityField.value as? String ?? "", "")
        XCTAssertEqual(postalField.value as? String ?? "", "")
        XCTAssertEqual(phoneField.value as? String ?? "", "")

        // 5. Re-check again -> validate all fields repopulate
        checkbox.tap()
        XCTAssertTrue(checkbox.isSelected)
        XCTAssertEqual(nameField.value as? String, "Jane Doe")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(postalField.value as? String, "94102")
        XCTAssertEqual(phoneField.value as? String, "(555) 555-5555")

        // 6. Change State to a different value -> checkbox auto-unchecks
        stateField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Alabama")
        app.toolbars.buttons["Done"].tap()
        XCTAssertFalse(checkbox.isSelected)

        // 7. Change State back to default (California) -> checkbox re-checks automatically
        stateField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(checkbox.isSelected)
        // Validate all fields are back to defaults
        XCTAssertEqual(nameField.value as? String, "Jane Doe")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(postalField.value as? String, "94102")
        XCTAssertEqual(phoneField.value as? String, "(555) 555-5555")

        // 8. Verify the address is valid
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
    }
}

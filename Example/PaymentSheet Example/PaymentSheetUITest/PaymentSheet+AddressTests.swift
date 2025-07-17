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

    func testManualAddressEntry() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.shippingInfo = .on

        loadPlayground(
            app,
            settings
        )

        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The Save Address button should be disabled
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertFalse(saveAddressButton.isEnabled)

        app.textFields["Full name"].tap()
        app.textFields["Full name"].typeText("Jane Doe")

        // Tapping the address field should go to autocomplete
        app.textFields["Address"].waitForExistenceAndTap()
        app.buttons["Enter address manually"].waitForExistenceAndTap()

        // Tapping the address line 1 field should now just let us enter the field manually
        app.textFields["Address line 1"].waitForExistenceAndTap()
        app.typeText("510 Townsend St")

        // Tapping autocomplete button in line 1 field should take us to autocomplete with the line 1 already entered in the search field
        app.buttons["autocomplete_affordance"].tap()
        XCTAssertEqual(app.textFields["Address"].value as! String, "510 Townsend St")
        app.buttons["Enter address manually"].waitForExistenceAndTap()

        // Continue entering address manually...
        app.textFields["Address line 2"].tap()
        app.typeText("Apt 152")
        app.textFields["City"].tap()
        app.typeText("San Francisco")
        app.textFields["State"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "California")
        app.toolbars.buttons["Done"].tap()
        // The save address button should still be disabled until we fill in all required fields
        XCTAssertFalse(saveAddressButton.isEnabled)
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        app.textFields["Phone number"].tap()
        app.textFields["Phone number"].typeText("5555555555")

        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        // The merchant app should get back the expected address
        let expectedAddress = """
Jane Doe
510 Townsend St, Apt 152
San Francisco CA 94102
US
+15555555555
"""
        XCTAssertEqual(shippingButton.label, expectedAddress)

        // Opening the shipping address back up...
        shippingButton.tap()
        // ...and editing ZIP to be invalid...
        let zip = app.textFields["ZIP"]
        XCTAssertEqual(zip.value as! String, "94102")
        zip.tap()
        app.typeText(XCUIKeyboardKey.delete.rawValue) // Invalid length
        // ...should disable the save address button
        XCTAssertFalse(saveAddressButton.isEnabled)
        // If we dismiss the sheet while its invalid...
        app.buttons["Close"].tap()
        // The merchant app should get back nil
        XCTAssertEqual(shippingButton.label, "Address")

        // Checkbox should NOT be shown when no defaults provided
        XCTAssertFalse(app.buttons["Use billing address for shipping"].exists)
    }

    func testAddressWithDefaults() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.shippingInfo = .onWithDefaults
        settings.uiStyle = .flowController

        loadPlayground(
            app,
            settings
        )

        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // Autocomplete should be presentable
        XCTAssertTrue(app.buttons["autocomplete_affordance"].waitForExistenceAndTap(timeout: 4.0))
        XCTAssertTrue(app.buttons["Enter address manually"].waitForExistenceAndTap(timeout: 4.0))

        // The Save address button should be enabled
        XCTAssertTrue(app.buttons["Save address"].waitForExistence(timeout: 4.0))
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)

        saveAddressButton.tap()

        // The merchant app should get back the expected address
        let expectedAddress = """
Jane Doe
510 Townsend St.
San Francisco CA 94102
US
+15555555555
"""
        XCTAssertEqual(shippingButton.label, expectedAddress)
    }

    func testAddressAutoComplete_UnitedStates() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        loadPlayground(
            app,
            settings
        )
        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The Save address button should be disabled
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertFalse(saveAddressButton.isEnabled)

        // Tapping the address field should go to autocomplete
        app.textFields["Address"].waitForExistenceAndTap()

        // Enter partial address and tap first result
        app.typeText("354 Oyster Point")
        let searchedCell = app.tables.element(boundBy: 0).cells.containing(NSPredicate(format: "label CONTAINS %@", "354 Oyster Point Blvd")).element
        _ = searchedCell.waitForExistence(timeout: 5)
        searchedCell.tap()

        // Verify text fields
        _ = app.textFields["Address line 1"].waitForExistence(timeout: 5)
        XCTAssertEqual(app.textFields["Address line 1"].value as! String, "354 Oyster Point Blvd")
        XCTAssertEqual(app.textFields["Address line 2"].value as! String, "")
        XCTAssertEqual(app.textFields["City"].value as! String, "South San Francisco")
        XCTAssertEqual(app.textFields["State"].value as! String, "California")
        XCTAssertEqual(app.textFields["ZIP"].value as! String, "94080")

        // Type in phone number
        app.textFields["Phone number"].tap()
        app.textFields["Phone number"].typeText("5555555555")

        // Type in the name to complete the form
        app.textFields["Full name"].tap()
        app.typeText("Jane Doe")

        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        // The merchant app should get back the expected address
        let expectedAddress = """
Jane Doe
354 Oyster Point Blvd
South San Francisco CA 94080
US
+15555555555
"""
        XCTAssertEqual(shippingButton.label, expectedAddress)
    }

    /// This test ensures we don't show auto complete for an unsupported country
    func testAddressAutoComplete_NewZeland() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        loadPlayground(
            app,
            settings
        )

        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The Save address button should be disabled
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertFalse(saveAddressButton.isEnabled)

        app.textFields["Full name"].tap()
        app.textFields["Full name"].typeText("Jane Doe")

        // Set country to New Zealand
        app.textFields["Country or region"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇳🇿 New Zealand")
        app.toolbars.buttons["Done"].tap()

        // Address line 1 field should not contain an autocomplete affordance b/c autocomplete doesn't support New Zealand
        XCTAssertFalse(app.buttons["autocomplete_affordance"].exists)

        // Tapping the address line 1 field...
        app.textFields["Address line 1"].tap()

        // ...should not go to auto complete b/c it's disabled for New Zealand
        XCTAssertFalse(app.buttons["Enter address manually"].waitForExistence(timeout: 3))

        // Make sure we can still fill out the form

        // Tapping the address line 1 field should now just let us enter the field manually
        app.textFields["Address line 1"].tap()
        app.typeText("1 South Bay Parade")
        app.textFields["Address line 2"].tap()
        app.typeText("Apt 152")
        app.textFields["City"].tap()
        app.typeText("Kaikōura")
        // The save address button should still be disabled until we fill in all required fields
        XCTAssertFalse(saveAddressButton.isEnabled)
        app.textFields["Postal code"].tap()
        app.typeText("7300")
        app.textFields["Phone number"].tap()
        app.textFields["Phone number"].typeText("5555555555")
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        // The merchant app should get back the expected address
        _ = shippingButton.waitForExistence(timeout: 5.0)
        let expectedAddress = """
Jane Doe
1 South Bay Parade, Apt 152
Kaikōura 7300
NZ
+645555555555
"""
        XCTAssertEqual(shippingButton.label, expectedAddress)
    }

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

    func testManualAddressEntry_phoneCountryDoesPersist() throws {

            var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
            loadPlayground(
                app,
                settings
            )

        let shippingButton = app.buttons["Address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()

        // The Save Address button should be disabled
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertFalse(saveAddressButton.isEnabled)

        // Select UK for phone number country
        app.textFields["United States +1"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇬🇧 United Kingdom +44")
        app.toolbars.buttons["Done"].tap()

        // Ensure UK is persisted as phone country after tapping done
        XCTAssert(app.textFields["United Kingdom +44"].exists)
    }

    // Helper method to wait for checkbox state and assert
    private func waitForCheckboxState(_ checkbox: XCUIElement, expectedState: Bool, timeout: TimeInterval = 2.0, file: StaticString = #file, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == %@", NSNumber(value: expectedState)),
            object: checkbox
        )
        wait(for: [expectation], timeout: timeout)

        if expectedState {
            XCTAssertTrue(checkbox.isSelected, file: file, line: line)
        } else {
            XCTAssertFalse(checkbox.isSelected, file: file, line: line)
        }
    }

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
        // Checkbox should start unchecked because shipping address (defaultValues) is populated
        waitForCheckboxState(checkbox, expectedState: false)

        // Get references to all fields we'll validate
        let nameField = app.textFields["Full name"]
        let line1Field = app.textFields["Address line 1"]
        let cityField = app.textFields["City"]
        let stateField = app.textFields["State"]
        let postalField = app.textFields["ZIP"]
        let phoneField = app.textFields["Phone number"]

        // Validate initial state - all fields should be populated with shipping address (defaultValues)
        XCTAssertEqual(nameField.value as? String, "Jane Doe")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(postalField.value as? String, "94102")
        XCTAssertEqual(phoneField.value as? String, "(555) 555-5555")

        // 1. Check the checkbox -> should populate with billing address
        checkbox.tap()
        waitForCheckboxState(checkbox, expectedState: true)
        XCTAssertEqual(nameField.value as? String, "John Smith")
        XCTAssertEqual(line1Field.value as? String, "123 Main Street")
        XCTAssertEqual(cityField.value as? String, "New York")
        XCTAssertEqual(stateField.value as? String, "New York")
        XCTAssertEqual(postalField.value as? String, "10001")
        XCTAssertEqual(phoneField.value as? String, "(555) 123-4567")

        // 2. Uncheck the checkbox -> should populate with shipping address  
        checkbox.tap()
        waitForCheckboxState(checkbox, expectedState: false)
        XCTAssertEqual(nameField.value as? String, "Jane Doe")
        XCTAssertEqual(line1Field.value as? String, "510 Townsend St.")
        XCTAssertEqual(cityField.value as? String, "San Francisco")
        XCTAssertEqual(stateField.value as? String, "California")
        XCTAssertEqual(postalField.value as? String, "94102")
        XCTAssertEqual(phoneField.value as? String, "(555) 555-5555")

        // 3. Edit line1 to match billing address -> checkbox should auto-check
        line1Field.tap()
        let existingValue = line1Field.value as? String ?? ""
        line1Field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count))
        line1Field.typeText("123 Main Street")

        // Edit other fields to match billing address exactly
        nameField.tap()
        let existingName = nameField.value as? String ?? ""
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingName.count))
        nameField.typeText("John Smith")

        cityField.tap()
        let existingCity = cityField.value as? String ?? ""
        cityField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingCity.count))
        cityField.typeText("New York")

        stateField.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "New York")
        app.toolbars.buttons["Done"].tap()

        postalField.tap()
        let existingPostal = postalField.value as? String ?? ""
        postalField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingPostal.count))
        postalField.typeText("10001")

        phoneField.tap()
        let existingPhone = phoneField.value as? String ?? ""
        phoneField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingPhone.count))
        phoneField.typeText("5551234567")

        // Now checkbox should be auto-checked since form matches billing address
        waitForCheckboxState(checkbox, expectedState: true)

        // 4. Edit line1 to be different from billing -> checkbox should auto-uncheck
        line1Field.tap()
        line1Field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "123 Main Street".count))
        line1Field.typeText("456 Different St")
        waitForCheckboxState(checkbox, expectedState: false)

        // 5. Verify the address is valid
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
    }
}

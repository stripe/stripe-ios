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
        app.launch()
    }

    func testManualAddressEntry() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
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
        app.textFields["Address line 2"].tap()
        app.typeText("Apt 152")
        app.textFields["City"].tap()
        app.typeText("San Francisco")
        app.textFields["State"].tap()
        app.typeText("California")
        // The save address button should still be disabled until we fill in all required fields
        XCTAssertFalse(saveAddressButton.isEnabled)
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        app.textFields["Phone"].tap()
        app.textFields["Phone"].typeText("5555555555")
        
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()
        
        // The merchant app should get back the expected address
        XCTAssertEqual(shippingButton.label, "Jane Doe, 510 Townsend St, Apt 152, San Francisco California 94102, US, +15555555555")
        
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
        XCTAssertEqual(shippingButton.label, "Add")
    }
    
    func testAddressWithDefaults() throws {
        loadPlayground(app, settings: ["shipping_info": "provided"])

        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        
        // The Save address button should be enabled
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertTrue(saveAddressButton.isEnabled)
        
        saveAddressButton.tap()
        
        // The merchant app should get back the expected address
        XCTAssertEqual(shippingButton.label, "Jane Doe, 510 Townsend St., San Francisco California 94102, CA, +15555555555")
    }
    
    func testAddressAutoComplete_UnitedStates() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        
        // The Save address button should be disabled
        let saveAddressButton = app.buttons["Save address"]
        XCTAssertFalse(saveAddressButton.isEnabled)
        
        // Tapping the address field should go to autocomplete
        app.textFields["Address"].waitForExistenceAndTap()
        
        // Enter partial address and tap first result
        app.typeText("4 Pennsylvania Plaza")
        let searchedCell = app.tables.element(boundBy: 0).cells.containing(NSPredicate(format: "label CONTAINS %@", "4 Pennsylvania Plaza")).element
        let _ = searchedCell.waitForExistence(timeout: 5)
        searchedCell.tap()
        
        // Verify text fields
        let _ = app.textFields["Address line 1"].waitForExistence(timeout: 5)
        XCTAssertEqual(app.textFields["Address line 1"].value as! String, "4 Pennsylvania Plaza")
        XCTAssertEqual(app.textFields["Address line 2"].value as! String, "")
        XCTAssertEqual(app.textFields["City"].value as! String, "New York")
        XCTAssertEqual(app.textFields["State"].value as! String, "NY")
        XCTAssertEqual(app.textFields["ZIP"].value as! String, "10001")
        
        // Type in phone number
        app.textFields["Phone"].tap()
        app.textFields["Phone"].typeText("5555555555")
        
        // Type in the name to complete the form
        app.textFields["Full name"].tap()
        app.typeText("Jane Doe")
        
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()

        // The merchant app should get back the expected address
        XCTAssertEqual(shippingButton.label, "Jane Doe, 4 Pennsylvania Plaza, New York NY 10001, US, +15555555555")
    }
    
    /// This test ensures we don't show auto complete for an unsupported country
    func testAddressAutoComplete_NewZeland() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
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
        app.textFields["Phone"].tap()
        app.textFields["Phone"].typeText("5555555555")
        XCTAssertTrue(saveAddressButton.isEnabled)
        saveAddressButton.tap()
        
        // The merchant app should get back the expected address
        let _ = shippingButton.waitForExistence(timeout: 5.0)
        XCTAssertEqual(shippingButton.label, "Jane Doe, 1 South Bay Parade, Apt 152, Kaikōura 7300, NZ, +645555555555")
    }
    
    func testPaymentSheetFlowControllerUpdatesShipping() {
        loadPlayground(app, settings: [
            "apple_pay": "off",
            "automatic_payment_methods": "off",
            "link": "off"
        ])

        // Using PaymentSheet.FlowController w/o a shipping address...
        app.buttons["present_saved_pms"].waitForExistenceAndTap()
        
        // ...should not show the "Billing address is same as shipping" checkbox
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "")
        XCTAssertFalse(app.switches["Billing address is same as shipping"].exists)
        app.buttons["Close"].tap()
        

        // Entering a shipping address...
        let shippingButton = app.buttons["Shipping address"]
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
        app.typeText("California")
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        app.buttons["Close"].tap()

        // ...and then using PaymentSheet.FlowController...
        app.buttons["present_saved_pms"].waitForExistenceAndTap()

        // ...should show the "Billing address is same as shipping" checkbox selected and set the address values to shipping
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")
        XCTAssertTrue(app.switches["Billing address is same as shipping"].isSelected)
        
        // Updating the shipping address country...
        app.buttons["Close"].tap()
        app.buttons["Shipping address"].tap()
        app.textFields["Country or region"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇨🇦 Canada")
        app.toolbars.buttons["Done"].tap()
        app.buttons["Close"].tap()

        //...should update PaymentSheet.FlowController
        app.buttons["present_saved_pms"].waitForExistenceAndTap()
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
        app.buttons["Shipping address"].tap()
        app.textFields["Country or region"].waitForExistenceAndTap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States")
        app.toolbars.buttons["Done"].tap()
        app.buttons["Close"].tap()
        
        // ...should not affect your billing address...
        app.buttons["present_saved_pms"].waitForExistenceAndTap()
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "Canada")
        XCTAssertEqual(app.textFields["Postal code"].value as? String, updatedBillingAddressPostalCode)
        
        // ...until 'Billing address is same as shipping' checkbox is selected again
        app.switches["Billing address is same as shipping"].tap()
        XCTAssertEqual(app.textFields["Country or region"].value as? String, "United States")
        XCTAssertEqual(app.textFields["ZIP"].value as? String, "94102")
    }
}

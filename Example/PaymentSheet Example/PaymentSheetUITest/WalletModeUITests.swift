//
//  WalletModeUITest.swift
//  PaymentSheetUITest
//

import Foundation
import XCTest

class WalletModeUITest: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }
    
    func testPaymentSheetStandard() throws {
        app.staticTexts["Saved Payment Methods (test playground)"].tap()
        let loadButton = app.staticTexts["Load customerInfo"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 60.0))
        loadButton.tap()
        let selectButton = app.staticTexts["Select"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()
        let addButton = app.buttons["+ Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 60.0))
        addButton.tap()
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Set up"].tap()
        let paymentMethodButton = app.staticTexts["••••4242"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }
}

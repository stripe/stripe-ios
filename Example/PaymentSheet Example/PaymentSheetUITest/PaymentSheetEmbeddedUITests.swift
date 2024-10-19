//
//  PayymentSheetEmbeddedUITests.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 10/18/24.
//
import XCTest

class PaymentSheetEmbeddedUITests: PaymentSheetUITestCase {
    func testUpdate() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.uiStyle = .embedded
        settings.currency = .eur
        loadPlayground(app, settings)

        app.buttons["Present embedded payment element"].waitForExistenceAndTap()
        app.buttons["Card"].waitForExistenceAndTap()

        try! fillCardData(app)
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
}

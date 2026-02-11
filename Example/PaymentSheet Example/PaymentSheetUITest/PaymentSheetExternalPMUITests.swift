//
//  PaymentSheetExternalPMUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

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
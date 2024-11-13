//
//  XCUITest+PaymentSheetTestUtilities.swift
//  PaymentSheet Example
//

import XCTest

extension XCTestCase {
    func reload(_ app: XCUIApplication, settings: PaymentSheetTestPlaygroundSettings) {
        app.buttons["Reload"].waitForExistenceAndTap(timeout: 10)
        waitForReload(app, settings: settings)
    }

    func waitForReload(_ app: XCUIApplication, settings: PaymentSheetTestPlaygroundSettings) {
        switch settings.uiStyle {
        case .paymentSheet:
            let presentButton = app.buttons["Present PaymentSheet"]
            expectation(
                for: NSPredicate(format: "enabled == true"),
                evaluatedWith: presentButton,
                handler: nil
            )
        case .flowController:
            let confirm = app.buttons["Confirm"]
            expectation(
                for: NSPredicate(format: "enabled == true"),
                evaluatedWith: confirm,
                handler: nil
            )
        case .embedded:
            let confirm = app.buttons["Present embedded payment element"]
            expectation(
                for: NSPredicate(format: "enabled == true"),
                evaluatedWith: confirm,
                handler: nil
            )
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    func loadPlayground(_ app: XCUIApplication, _ settings: PaymentSheetTestPlaygroundSettings) {
        if #available(iOS 15.0, *) {
            // Doesn't work on 16.4. Seems like a bug, can't see any confirmation that this works online.
            //   var urlComponents = URLComponents(string: "stripe-paymentsheet-example://playground")!
            //   urlComponents.query = settings.base64Data
            //   app.open(urlComponents.url!)
            // This should work, but we get an "Open in 'PaymentSheet Example'" consent dialog the first time we run it.
            // And while the dialog is appearing, `open()` doesn't return, so we can't install an interruption handler or anything to handle it.
            //   XCUIDevice.shared.system.open(urlComponents.url!)
            app.launchEnvironment = app.launchEnvironment.merging(["STP_PLAYGROUND_DATA": settings.base64Data]) { (_, new) in new }
            app.launch()
        } else {
            XCTFail("This test is only supported on iOS 15.0 or later.")
        }
        waitForReload(app, settings: settings)
    }
    func waitForReload(_ app: XCUIApplication, settings: CustomerSheetTestPlaygroundSettings) {
        let paymentMethodButton = app.buttons["Payment method"]
        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton,
            handler: nil
        )
        waitForExpectations(timeout: 10, handler: nil)
    }
    func loadPlayground(_ app: XCUIApplication, _ settings: CustomerSheetTestPlaygroundSettings) {
        if #available(iOS 15.0, *) {
            app.launchEnvironment = app.launchEnvironment.merging(["STP_CUSTOMERSHEET_PLAYGROUND_DATA": settings.base64Data]) { (_, new) in new }
            app.launch()
        } else {
            XCTFail("This test is only supported on iOS 15.0 or later.")
        }
        waitForReload(app, settings: settings)
    }
}

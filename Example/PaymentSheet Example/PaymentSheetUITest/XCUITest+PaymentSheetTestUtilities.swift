//
//  XCUITest+PaymentSheetTestUtilities.swift
//  PaymentSheet Example
//

import XCTest

extension XCTestCase {
    func reload(_ app: XCUIApplication, settings: PaymentSheetTestPlaygroundSettings, retry: Int = 0, maxRetries: Int = 3) {
        app.buttons["Reload"].waitForExistenceAndTap(timeout: 5)
        waitForReload(app, settings: settings, retry: retry, maxRetries: maxRetries)
    }

    func waitForReload(_ app: XCUIApplication, settings: PaymentSheetTestPlaygroundSettings, retry: Int = 0, maxRetries: Int = 3) {
        let timeout: TimeInterval = 5

        var successfullyLoaded = false
        switch settings.uiStyle {
        case .paymentSheet:
            successfullyLoaded = app.buttons["Present PaymentSheet"].waitForExistence(timeout: timeout)
        case .flowController:
            successfullyLoaded = app.buttons["Confirm"].waitForExistence(timeout: timeout)
        case .embedded:
            successfullyLoaded = app.buttons["Present embedded payment element"].waitForExistence(timeout: timeout)
        }

        if !successfullyLoaded {
            if retry < maxRetries {
                // Hit the reload button and try again
                reload(app, settings: settings, retry: retry + 1, maxRetries: maxRetries)
            } else {
                XCTFail("Failed to load payment sheet after \(maxRetries) retries")
            }
        }
    }
    func loadPlayground(_ app: XCUIApplication, _ settings: PaymentSheetTestPlaygroundSettings) {
        // Doesn't work on 16.4. Seems like a bug, can't see any confirmation that this works online.
        //   var urlComponents = URLComponents(string: "stripe-paymentsheet-example://playground")!
        //   urlComponents.query = settings.base64Data
        //   app.open(urlComponents.url!)
        // This should work, but we get an "Open in 'PaymentSheet Example'" consent dialog the first time we run it.
        // And while the dialog is appearing, `open()` doesn't return, so we can't install an interruption handler or anything to handle it.
        //   XCUIDevice.shared.system.open(urlComponents.url!)
        app.launchEnvironment = app.launchEnvironment.merging(["STP_PLAYGROUND_DATA": settings.base64Data]) { (_, new) in new }
        app.launch()
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
    /// Reloads the playground repeatedly until the latest `mc_load_succeeded` analytics event
    /// reports `has_default_payment_method == true`. Fails the test if this is not achieved
    /// within `maxAttempts`. This is useful when the backend sets a default payment method
    /// asynchronously after a payment, and the test needs to wait for that to propagate.
    func reloadAndWaitForDefaultPaymentMethod(
        _ app: XCUIApplication,
        settings: PaymentSheetTestPlaygroundSettings,
        analyticsLog: () -> [[String: Any]],
        maxAttempts: Int = 10
    ) {
        for _ in 1...maxAttempts {
            reload(app, settings: settings)
            let hasDefault = analyticsLog()
                .filter { $0["event"] as? String == "mc_load_succeeded" }
                .last?["has_default_payment_method"] as? Bool == true
            if hasDefault {
                return
            }
        }
        XCTFail("Default payment method was not reflected in analytics after \(maxAttempts) reload attempts")
    }

    func loadPlayground(_ app: XCUIApplication, _ settings: CustomerSheetTestPlaygroundSettings) {
        app.launchEnvironment = app.launchEnvironment.merging(["STP_CUSTOMERSHEET_PLAYGROUND_DATA": settings.base64Data]) { (_, new) in new }
        app.launch()
        waitForReload(app, settings: settings)
    }
}

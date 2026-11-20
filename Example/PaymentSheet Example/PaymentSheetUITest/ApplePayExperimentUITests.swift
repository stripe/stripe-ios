import XCTest

final class ApplePayExperimentUITests: PaymentSheetUITestCase {
    func testExperimentBaseline() { run("baseline") }
    func testExperimentPMUpdateBilling() { run("pmupdate_billing") }
    func testExperimentPMUpdateUnknown() { run("pmupdate_unknown") }
    func testExperimentBaselineResave() {
        let v = "baseline_resave"
        let applePay = openSheet("baseline")
        let pay = applePay.buttons["Pay with Passcode"]
        XCTAssertTrue(pay.waitForExistence(timeout: 8))
        pay.forceTapElement()
        sleep(6)
        snap("1-after-pay", v, applePay)
        let row = applePay.buttons.containing(NSPredicate(format: "label CONTAINS 'Update Billing Address'")).firstMatch
        if row.waitForExistence(timeout: 5) { row.forceTapElement() }
        sleep(3)
        snap("2-row-tapped", v, applePay)
        let address = applePay.buttons.containing(NSPredicate(format: "label CONTAINS 'Jane Doe'")).firstMatch
        if address.waitForExistence(timeout: 5) { address.forceTapElement() }
        sleep(3)
        snap("3-address-tapped", v, applePay)
        let zip = applePay.textFields.matching(NSPredicate(format: "value == '95014'")).firstMatch
        if zip.waitForExistence(timeout: 5) {
            zip.tap()
            zip.typeText(XCUIKeyboardKey.delete.rawValue + "4")
        }
        sleep(2)
        snap("4-zip-retyped", v, applePay)
        let editorDone = applePay.navigationBars["Billing Address"].buttons["Done"]
        snap("4b-editor-done-enabled-\(editorDone.exists && editorDone.isEnabled)", v, applePay)
        if editorDone.exists { editorDone.tap() }
        sleep(4)
        snap("5-after-editor-done", v, applePay)
        let detailsDone = applePay.navigationBars.buttons["Done"].firstMatch
        if detailsDone.exists { detailsDone.tap() }
        sleep(4)
        snap("6-main-sheet", v, applePay)
        if pay.waitForExistence(timeout: 5) {
            pay.forceTapElement()
            sleep(12)
            snap("7-after-second-pay", v, applePay)
        }
    }

    func testExperimentRealBadZip() { _ = openSheet("realbad_zip") }
    func testExperimentRealBadState() { _ = openSheet("realbad_state") }
    func testExperimentRealBadCountry() { _ = openSheet("realbad_country") }

    func testExperimentRetryUnknown() { runRetry("retry_unknown") }
    func testExperimentRetryPlain() { runRetry("retry_plain") }
    func testExperimentRetry() { runRetry("retry") }
    private func runRetry(_ v: String) {
        let applePay = openSheet(v)
        let pay = applePay.buttons["Pay with Passcode"]
        for attempt in 1...3 {
            guard pay.waitForExistence(timeout: 8) else {
                snap("7-attempt\(attempt)-no-pay-button", v, applePay)
                break
            }
            pay.forceTapElement()
            sleep(8)
            snap("7-after-pay-attempt\(attempt)", v, applePay)
            if app.alerts.firstMatch.exists { break }
        }
        // Re-select the same card to see whether didSelectPaymentMethod fires again.
        if !app.alerts.firstMatch.exists {
            let row = applePay.buttons.containing(NSPredicate(format: "label CONTAINS 'Simulated Card'")).firstMatch
            if row.waitForExistence(timeout: 5) {
                row.forceTapElement()
                sleep(3)
                snap("8-card-row-tapped", v, applePay)
                let card = applePay.buttons.containing(NSPredicate(format: "label CONTAINS 'Simulated Card - AmEx'")).firstMatch
                if card.waitForExistence(timeout: 5) { card.forceTapElement() }
                sleep(3)
                snap("9-card-reselected", v, applePay)
                let done = applePay.navigationBars.buttons["dismiss"]
                if done.exists { done.tap() }
                sleep(5)
                snap("10-main-sheet-after-reselect", v, applePay)
                if pay.waitForExistence(timeout: 8) {
                    pay.forceTapElement()
                    sleep(15)
                    snap("11-after-final-pay", v, applePay)
                }
            }
        }
        try? app.debugDescription.write(toFile: "/tmp/apexp-out/\(v)/12-app.txt", atomically: true, encoding: .utf8)
    }

    private func openSheet(_ variant: String) -> XCUIApplication {
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .eceOnly
        settings.automaticPaymentMethods = false
        settings.shippingAddressCollection = false
        settings.automaticTax = true
        app.launchEnvironment["APPLEPAY_EXPERIMENT"] = variant
        loadCheckoutPlayground(app, settings)
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))
        let applePayButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Buy with Apple")).firstMatch
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 10))
        applePayButton.tap()
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)
        addApplePayContactIfNeeded(applePay)
        let cardButton = applePay.buttons.containing(NSPredicate(format: "label CONTAINS 'Simulated Card - AmEx, ‪•••• 1234‬'")).firstMatch
        if cardButton.waitForExistence(timeout: 10) { cardButton.forceTapElement() }
        addApplePayBillingIfNeeded(applePay)
        sleep(3)
        let done = applePay.navigationBars.buttons["dismiss"]
        if done.exists {
            done.tap()
        } else {
            let sel = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].firstMatch
            if sel.waitForExistence(timeout: 5) { sel.forceTapElement() }
        }
        sleep(4)
        snap("4-main-sheet", variant, applePay)
        return applePay
    }

    private func snap(_ name: String, _ variant: String, _ applePay: XCUIApplication) {
        let shot = XCUIScreen.main.screenshot()
        let dir = "/tmp/apexp-out/\(variant)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        try? applePay.debugDescription.write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
    }

    private func run(_ variant: String) {
        var settings = CheckoutPlayground.Settings()
        settings.integrationType = .eceOnly
        settings.automaticPaymentMethods = false
        settings.shippingAddressCollection = false
        settings.automaticTax = true
        app.launchEnvironment["APPLEPAY_EXPERIMENT"] = variant
        loadCheckoutPlayground(app, settings)
        app.buttons["Create Checkout Session"].waitForExistenceAndTap()
        XCTAssertTrue(app.navigationBars["Your Cart"].waitForExistence(timeout: 15))
        let applePayButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Buy with Apple")).firstMatch
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 10))
        applePayButton.tap()

        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)
        sleep(3)
        snap("1-sheet-opened", variant, applePay)
        addApplePayContactIfNeeded(applePay)

        let predicate = NSPredicate(format: "label CONTAINS 'Simulated Card - AmEx, ‪•••• 1234‬'")
        let cardButton = applePay.buttons.containing(predicate).firstMatch
        if cardButton.waitForExistence(timeout: 10) { cardButton.forceTapElement() }
        sleep(2)
        snap("2-card-tapped", variant, applePay)
        addApplePayBillingIfNeeded(applePay)
        sleep(4)
        snap("3-after-billing", variant, applePay)

        let done = applePay.navigationBars.buttons["dismiss"]
        if done.exists {
            done.tap()
        } else {
            let sel = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].firstMatch
            if sel.waitForExistence(timeout: 5) { sel.forceTapElement() }
        }
        sleep(4)
        snap("4-main-sheet", variant, applePay)

        let pay = applePay.buttons["Pay with Passcode"]
        if pay.waitForExistence(timeout: 5) {
            snap("5-pay-button-enabled-\(pay.isEnabled)", variant, applePay)
            pay.forceTapElement()
        }
        sleep(10)
        snap("6-after-pay", variant, applePay)
        try? app.debugDescription.write(toFile: "/tmp/apexp-out/\(variant)/6-app.txt", atomically: true, encoding: .utf8)
    }
}

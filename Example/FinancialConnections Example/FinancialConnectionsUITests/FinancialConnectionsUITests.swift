//
//  FinancialConnectionsUITests.swift
//  FinancialConnectionsUITests
//
//  Created by Krisjanis Gaidis on 12/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

final class FinancialConnectionsUITests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDataTestModeOAuthNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let playgroundCell = app.tables.staticTexts["Playground"]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 60.0))
        playgroundCell.tap()

        let dataSegmentPickerButton = app.collectionViews.buttons["Data"]
        XCTAssertTrue(dataSegmentPickerButton.waitForExistence(timeout: 60.0))
        dataSegmentPickerButton.tap()

        let nativeSegmentPickerButton = app.collectionViews.buttons["Native"]
        XCTAssertTrue(nativeSegmentPickerButton.waitForExistence(timeout: 60.0))
        nativeSegmentPickerButton.tap()

        let enableTestModeSwitch = app.collectionViews.switches["Enable Test Mode"]
        XCTAssertTrue(enableTestModeSwitch.waitForExistence(timeout: 60.0))
        if (enableTestModeSwitch.value as? String) == "0" {
            enableTestModeSwitch.tap()
        }

        let showAuthFlowButton = app.buttons["Show Auth Flow"]
        XCTAssertTrue(showAuthFlowButton.waitForExistence(timeout: 60.0))
        showAuthFlowButton.tap()

        let consentAgreeButton = app.buttons["Agree"]
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0))  // glitch app can take time to lload
        consentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.collectionViews.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        let prepaneContinueButton = app.buttons["Continue"]
        XCTAssertTrue(prepaneContinueButton.waitForExistence(timeout: 60.0))
        prepaneContinueButton.tap()

        let accountPickerLinkAccountsButton = app.buttons["Link accounts"]
        XCTAssertTrue(accountPickerLinkAccountsButton.waitForExistence(timeout: 120.0))  // wait for accounts to fetch
        accountPickerLinkAccountsButton.tap()

        let successPaneDoneButton = app.buttons["Done"]
        XCTAssertTrue(successPaneDoneButton.waitForExistence(timeout: 120.0))  // wait for accounts to link
        successPaneDoneButton.tap()

        let playgroundSuccessAlert = app.alerts["Success"]
        XCTAssertTrue(playgroundSuccessAlert.waitForExistence(timeout: 60.0))

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            playgroundSuccessAlert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testPaymentTestModeLegacyNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let playgroundCell = app.tables.staticTexts["Playground"]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 60.0))
        playgroundCell.tap()

        let dataSegmentPickerButton = app.collectionViews.buttons["Payments"]
        XCTAssertTrue(dataSegmentPickerButton.waitForExistence(timeout: 60.0))
        dataSegmentPickerButton.tap()

        let nativeSegmentPickerButton = app.collectionViews.buttons["Native"]
        XCTAssertTrue(nativeSegmentPickerButton.waitForExistence(timeout: 60.0))
        nativeSegmentPickerButton.tap()

        let enableTestModeSwitch = app.collectionViews.switches["Enable Test Mode"]
        XCTAssertTrue(enableTestModeSwitch.waitForExistence(timeout: 60.0))
        if (enableTestModeSwitch.value as? String) == "0" {
            enableTestModeSwitch.tap()
        }

        let showAuthFlowButton = app.buttons["Show Auth Flow"]
        XCTAssertTrue(showAuthFlowButton.waitForExistence(timeout: 60.0))
        showAuthFlowButton.tap()

        let consentAgreeButton = app.buttons["Agree"]
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0))  // glitch app can take time to lload
        consentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.collectionViews.staticTexts["Test Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        let successAccountRow = app.scrollViews.staticTexts["Success"]
        XCTAssertTrue(successAccountRow.waitForExistence(timeout: 60.0))
        successAccountRow.tap()

        let accountPickerLinkAccountButton = app.buttons["Link account"]
        XCTAssertTrue(accountPickerLinkAccountButton.waitForExistence(timeout: 120.0))  // wait for accounts to fetch
        accountPickerLinkAccountButton.tap()

        let successPaneDoneButton = app.buttons["Done"]
        XCTAssertTrue(successPaneDoneButton.waitForExistence(timeout: 120.0))  // wait for accounts to link
        successPaneDoneButton.tap()

        let playgroundSuccessAlert = app.alerts["Success"]
        XCTAssertTrue(playgroundSuccessAlert.waitForExistence(timeout: 60.0))

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            playgroundSuccessAlert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    // note that this does NOT complete the Auth Flow, but its a decent check on
    // whether live mode is ~working
    func testDataLiveModeOAuthNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let playgroundCell = app.tables.staticTexts["Playground"]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 60.0))
        playgroundCell.tap()

        let dataSegmentPickerButton = app.collectionViews.buttons["Data"]
        XCTAssertTrue(dataSegmentPickerButton.waitForExistence(timeout: 60.0))
        dataSegmentPickerButton.tap()

        let nativeSegmentPickerButton = app.collectionViews.buttons["Native"]
        XCTAssertTrue(nativeSegmentPickerButton.waitForExistence(timeout: 60.0))
        nativeSegmentPickerButton.tap()

        let enableTestModeSwitch = app.collectionViews.switches["Enable Test Mode"]
        XCTAssertTrue(enableTestModeSwitch.waitForExistence(timeout: 60.0))
        if (enableTestModeSwitch.value as? String) == "1" {
            enableTestModeSwitch.tap()
        }

        let showAuthFlowButton = app.buttons["Show Auth Flow"]
        XCTAssertTrue(showAuthFlowButton.waitForExistence(timeout: 60.0))
        showAuthFlowButton.tap()

        let consentAgreeButton = app.buttons["Agree"]
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0))  // glitch app can take time to lload
        consentAgreeButton.tap()

        // find + tap an institution; we add extra institutions in case
        // they don't get featured
        let institutionButton: XCUIElement?
        let institutionTextInWebView: String?
        let chaseInstitutionButton = app.cells["Chase"]
        if chaseInstitutionButton.waitForExistence(timeout: 10) {
            institutionButton = chaseInstitutionButton
            institutionTextInWebView = "Chase"
        } else {
            let bankOfAmericaInstitutionButton = app.cells["Bank of America"]
            if bankOfAmericaInstitutionButton.waitForExistence(timeout: 10) {
                institutionButton = bankOfAmericaInstitutionButton
                institutionTextInWebView = "Bank of America"
            } else {
                let wellsFargoInstitutionButton = app.cells["Wells Fargo"]
                if wellsFargoInstitutionButton.waitForExistence(timeout: 10) {
                    institutionButton = wellsFargoInstitutionButton
                    institutionTextInWebView = "Wells Fargo"
                } else {
                    institutionButton = nil
                    institutionTextInWebView = nil
                }
            }
        }
        guard let institutionButton = institutionButton, let institutionTextInWebView = institutionTextInWebView else {
            XCTFail("Couldn't find a Live Mode institution.")
            return
        }
        institutionButton.tap()

        let prepaneContinueButton = app.buttons["Continue"]
        XCTAssertTrue(prepaneContinueButton.waitForExistence(timeout: 60.0))
        prepaneContinueButton.tap()

        // check that the WebView loaded
        let institutionWebViewText = app.webViews
            .staticTexts
            .containing(NSPredicate(format: "label CONTAINS '\(institutionTextInWebView)'"))
            .firstMatch
        XCTAssertTrue(institutionWebViewText.waitForExistence(timeout: 120.0))

        let secureWebViewCancelButton = app.buttons["Cancel"]
        XCTAssertTrue(secureWebViewCancelButton.waitForExistence(timeout: 60.0))
        secureWebViewCancelButton.tap()

        let navigationBarCloseButton = app.navigationBars.buttons["close"]
        XCTAssertTrue(navigationBarCloseButton.waitForExistence(timeout: 60.0))
        navigationBarCloseButton.tap()

        let cancelAlert = app.alerts["Are you sure you want to cancel?"]
        XCTAssertTrue(cancelAlert.waitForExistence(timeout: 60.0))

        let cancelAlertButon = app.alerts.buttons["Yes, cancel"]
        XCTAssertTrue(cancelAlertButon.waitForExistence(timeout: 60.0))
        cancelAlertButon.tap()

        let playgroundCancelAlert = app.alerts["Cancelled"]
        XCTAssertTrue(playgroundCancelAlert.waitForExistence(timeout: 60.0))
    }

    // note that this does NOT complete the Auth Flow, but its a decent check on
    // whether live mode is ~working
    func testDataLiveModeOAuthWebAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let playgroundCell = app.tables.staticTexts["Playground"]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 60.0))
        playgroundCell.tap()

        let dataSegmentPickerButton = app.collectionViews.buttons["Data"]
        XCTAssertTrue(dataSegmentPickerButton.waitForExistence(timeout: 60.0))
        dataSegmentPickerButton.tap()

        let nativeSegmentPickerButton = app.collectionViews.buttons["Web"]
        XCTAssertTrue(nativeSegmentPickerButton.waitForExistence(timeout: 60.0))
        nativeSegmentPickerButton.tap()

        let enableTestModeSwitch = app.collectionViews.switches["Enable Test Mode"]
        XCTAssertTrue(enableTestModeSwitch.waitForExistence(timeout: 60.0))
        if (enableTestModeSwitch.value as? String) == "1" {
            enableTestModeSwitch.tap()
        }

        let showAuthFlowButton = app.buttons["Show Auth Flow"]
        XCTAssertTrue(showAuthFlowButton.waitForExistence(timeout: 60.0))
        showAuthFlowButton.tap()

        let consentAgreeButton = app.webViews.buttons["Agree"]
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0))  // glitch app can take time to load
        consentAgreeButton.tap()

        // find + tap an institution; we add extra institutions in case
        // they don't get featured
        let institutionButton: XCUIElement?
        let institutionTextInWebView: String?
        let chaseInstitutionButton = app.webViews.buttons["Chase"]
        if chaseInstitutionButton.waitForExistence(timeout: 10) {
            institutionButton = chaseInstitutionButton
            institutionTextInWebView = "Chase"
        } else {
            let bankOfAmericaInstitutionButton = app.webViews.buttons["Bank of America"]
            if bankOfAmericaInstitutionButton.waitForExistence(timeout: 10) {
                institutionButton = bankOfAmericaInstitutionButton
                institutionTextInWebView = "Bank of America"
            } else {
                let wellsFargoInstitutionButton = app.webViews.buttons["Wells Fargo"]
                if wellsFargoInstitutionButton.waitForExistence(timeout: 10) {
                    institutionButton = wellsFargoInstitutionButton
                    institutionTextInWebView = "Wells Fargo"
                } else {
                    institutionButton = nil
                    institutionTextInWebView = nil
                }
            }
        }
        guard let institutionButton = institutionButton, let institutionTextInWebView = institutionTextInWebView else {
            XCTFail("Couldn't find a Live Mode institution.")
            return
        }
        institutionButton.tap()

        let prepaneContinueButton = app.webViews
            .buttons
            .containing(NSPredicate(format: "label CONTAINS 'Continue'"))
            .firstMatch
        XCTAssertTrue(prepaneContinueButton.waitForExistence(timeout: 60.0))
        prepaneContinueButton.tap()

        // check that the WebView loaded
        let institutionWebViewText = app.webViews
            .staticTexts
            .containing(NSPredicate(format: "label CONTAINS '\(institutionTextInWebView)'"))
            .firstMatch
        XCTAssertTrue(institutionWebViewText.waitForExistence(timeout: 120.0))

        let secureWebViewCancelButton = app.buttons["Cancel"]
        XCTAssertTrue(secureWebViewCancelButton.waitForExistence(timeout: 60.0))
        secureWebViewCancelButton.tap()

        let playgroundCancelAlert = app.alerts["Cancelled"]
        XCTAssertTrue(playgroundCancelAlert.waitForExistence(timeout: 60.0))
    }
}

extension XCTestCase {
    fileprivate func wait(timeout: TimeInterval) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "")], timeout: timeout)
    }
}

extension XCUIElement {

    fileprivate func wait(
        until expression: @escaping (XCUIElement) -> Bool,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                expression(self)
            },
            object: nil
        )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return (result == .completed)
    }
}

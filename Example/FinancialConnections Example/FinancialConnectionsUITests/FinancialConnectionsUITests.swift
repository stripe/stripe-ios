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

        app.fc_playgroundCell.tap()
        app.fc_playgroundDataFlowButton.tap()
        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        if (enableTestModeSwitch.value as? String) == "0" {
            enableTestModeSwitch.tap()
        }

        app.fc_playgroundShowAuthFlowButton.tap()
        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.collectionViews.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()
        app.fc_nativeAccountPickerLinkAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testPaymentTestModeLegacyNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.fc_playgroundCell.tap()
        app.fc_playgroundPaymentFlowButton.tap()
        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        if (enableTestModeSwitch.value as? String) == "0" {
            enableTestModeSwitch.tap()
        }

        app.fc_playgroundShowAuthFlowButton.tap()
        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.collectionViews.staticTexts["Test Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        let successAccountRow = app.scrollViews.staticTexts["Success"]
        XCTAssertTrue(successAccountRow.waitForExistence(timeout: 60.0))
        successAccountRow.tap()

        app.fc_nativeAccountPickerLinkAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testPaymentTestModeManualEntryNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.fc_playgroundCell.tap()
        app.fc_playgroundPaymentFlowButton.tap()
        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        if (enableTestModeSwitch.value as? String) == "0" {
            enableTestModeSwitch.tap()
        }

        app.fc_playgroundShowAuthFlowButton.tap()

        let manuallyVerifyLabel = app.otherElements["consent_manually_verify_label"]
        XCTAssertTrue(manuallyVerifyLabel.waitForExistence(timeout: 120.0))
        manuallyVerifyLabel.tap()

        let manualEntryRoutingNumberTextField = app.textFields["manual_entry_routing_number_text_field"]
        XCTAssertTrue(manualEntryRoutingNumberTextField.waitForExistence(timeout: 60.0))
        manualEntryRoutingNumberTextField.tap()
        manualEntryRoutingNumberTextField.typeText("110000000")

        app.scrollViews.firstMatch.swipeUp() // dismiss keyboard

        let manualEntryAccountNumberTextField = app.textFields["manual_entry_account_number_text_field"]
        XCTAssertTrue(manualEntryAccountNumberTextField.waitForExistence(timeout: 60.0))
        manualEntryAccountNumberTextField.tap()
        manualEntryAccountNumberTextField.typeText("000123456789")

        app.scrollViews.firstMatch.swipeUp() // dismiss keyboard

        let manualEntryAccountNumberConfirmationTextField = app.textFields["manual_entry_account_number_confirmation_text_field"]
        XCTAssertTrue(manualEntryAccountNumberConfirmationTextField.waitForExistence(timeout: 60.0))
        manualEntryAccountNumberConfirmationTextField.tap()
        manualEntryAccountNumberConfirmationTextField.typeText("000123456789")

        app.scrollViews.firstMatch.swipeUp() // dismiss keyboard

        let manualEntryContinueButton = app.buttons["manual_entry_continue_button"]
        XCTAssertTrue(manualEntryContinueButton.waitForExistence(timeout: 120.0))
        manualEntryContinueButton.tap()

        let manualEntrySuccessDoneButton = app.buttons["manual_entry_success_done_button"]
        XCTAssertTrue(manualEntrySuccessDoneButton.waitForExistence(timeout: 120.0))
        manualEntrySuccessDoneButton.tap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    // note that this does NOT complete the Auth Flow, but its a decent check on
    // whether live mode is ~working
    func testDataLiveModeOAuthNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.fc_playgroundCell.tap()
        app.fc_playgroundDataFlowButton.tap()
        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        if (enableTestModeSwitch.value as? String) == "1" {
            enableTestModeSwitch.tap()
        }

        app.fc_playgroundShowAuthFlowButton.tap()
        app.fc_nativeConsentAgreeButton.tap()

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

        app.fc_nativePrepaneContinueButton.tap()

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

        app.fc_playgroundCell.tap()
        app.fc_playgroundDataFlowButton.tap()

        let webSegmentPickerButton = app.segmentedControls.buttons["Web"]
        XCTAssertTrue(webSegmentPickerButton.waitForExistence(timeout: 60.0))
        webSegmentPickerButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        if (enableTestModeSwitch.value as? String) == "1" {
            enableTestModeSwitch.tap()
        }

        app.fc_playgroundShowAuthFlowButton.tap()

        let consentAgreeButton = app.webViews
            .buttons
            .containing(NSPredicate(format: "label CONTAINS 'Agree'"))
            .firstMatch
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

    func testSearchInLiveModeNativeAuthFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.fc_playgroundCell.tap()
        app.fc_playgroundPaymentFlowButton.tap()
        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        if (enableTestModeSwitch.value as? String) == "1" {
            enableTestModeSwitch.tap()
        }

        app.fc_playgroundShowAuthFlowButton.tap()
        app.fc_nativeConsentAgreeButton.tap()

        let searchBarTextField = app.textFields["search_bar_text_field"]
        XCTAssertTrue(searchBarTextField.waitForExistence(timeout: 120.0))
        searchBarTextField.tap()
        searchBarTextField.typeText("Bank of America")

        let bankOfAmericaSearchRow = app.tables.staticTexts["Bank of America"]
        XCTAssertTrue(bankOfAmericaSearchRow.waitForExistence(timeout: 120.0))
        bankOfAmericaSearchRow.tap()

        XCTAssert(app.fc_nativePrepaneContinueButton.exists) // check that prepane was opened

        let backButton = app.navigationBars["fc_navigation_bar"].buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 60.0))
        backButton.tap()

        searchBarTextField.tap()
        searchBarTextField.typeText("testing123")

        let institutionSearchFooterView = app.otherElements["institution_search_footer_view"]
        XCTAssertTrue(institutionSearchFooterView.waitForExistence(timeout: 120.0))
        institutionSearchFooterView.tap()

        // check that manual entry screen is opened
        let manualEntryContinueButton = app.buttons["manual_entry_continue_button"]
        XCTAssertTrue(manualEntryContinueButton.waitForExistence(timeout: 60.0))
    }
}

extension XCTestCase {
    func wait(timeout: TimeInterval) {
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

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
        continueAfterFailure = false
    }

    func testDataTestModeOAuthNativeAuthFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"data","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()
        app.fc_nativeConnectAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testPaymentTestModeLegacyNativeAuthFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        // "Success" institution is automatically selected as the first one
        app.fc_nativeConnectAccountsButton.tap()

        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testPaymentTestModeManualEntryNativeAuthFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        let manuallyVerifyLabel = app
            .otherElements["consent_manually_verify_label"]
            .links
            .firstMatch
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

        app.fc_nativeSuccessDoneButton.tap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    func testPaymentTestModeManualEntryAutofill() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

        app.fc_nativeSuccessDoneButton.tap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    // note that this does NOT complete the Auth Flow, but its a decent check on
    // whether live mode is ~working
    func testDataLiveModeOAuthNativeAuthFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"data","experience":"financial_connections","sdk_type":"native","test_mode":false,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        // find + tap an institution; we add extra institutions in case
        // they don't get featured
        let institutionButton: XCUIElement?
        let institutionName: String?
        let chaseBankName = "Chase"
        let chaseInstitutionButton = app.tables.staticTexts[chaseBankName]
        if chaseInstitutionButton.waitForExistence(timeout: 10) {
            institutionButton = chaseInstitutionButton
            institutionName = chaseBankName
        } else {
            let bankOfAmericaBankName = "Bank of America"
            let bankOfAmericaInstitutionButton = app.tables.staticTexts[bankOfAmericaBankName]
            if bankOfAmericaInstitutionButton.waitForExistence(timeout: 10) {
                institutionButton = bankOfAmericaInstitutionButton
                institutionName = bankOfAmericaBankName
            } else {
                let wellsFargoBankName = "Wells Fargo"
                let wellsFargoInstitutionButton = app.tables.staticTexts[wellsFargoBankName]
                if wellsFargoInstitutionButton.waitForExistence(timeout: 10) {
                    institutionButton = wellsFargoInstitutionButton
                    institutionName = wellsFargoBankName
                } else {
                    institutionButton = nil
                    institutionName = nil
                }
            }
        }
        guard let institutionButton = institutionButton, let institutionName = institutionName else {
            XCTFail("Couldn't find a Live Mode institution.")
            return
        }
        institutionButton.tap()

        // ...at this point the bank is either:
        // 1. active, which means prepane is visible
        // 2. under maintenance, which means an 'error' screen is visible

        // (1) bank is NOT under maintenance
        if app.fc_nativePrepaneContinueButton_noWait.waitForExistence(timeout: 60) {
            app.fc_nativePrepaneContinueButton.tap()

            // check that the WebView loaded
            var predicateString = "label CONTAINS '\(institutionName)'"
            if institutionName == "Chase" {
                // Chase (usually) does not contain the word "Chase" on their log-in page
                predicateString = "label CONTAINS '\(institutionName)' OR label CONTAINS 'username' OR label CONTAINS 'password'"
            }
            let institutionWebViewText = app.webViews
                .staticTexts
                .containing(NSPredicate(format: predicateString))
                .firstMatch
            XCTAssertTrue(institutionWebViewText.waitForExistence(timeout: 120.0))

            app.fc_secureWebViewCancelButton.tap()

            app.fc_nativePrepaneCancelButton.tap()
        }
        // (2) bank IS under maintenance
        else {
            // check that we see a maintenance error
            let errorViewText = app
                .textViews
                .containing(NSPredicate(format: "label CONTAINS 'unavailable' OR label CONTAINS 'maintenance' OR label CONTAINS 'scheduled'"))
                .firstMatch
            XCTAssertTrue(errorViewText.waitForExistence(timeout: 10))
        }

        let navigationBarCloseButton = app.navigationBars.buttons["close"]
        XCTAssertTrue(navigationBarCloseButton.waitForExistence(timeout: 60.0))
        navigationBarCloseButton.tap()

        let exitConfirmationOKButton = app.buttons["close_confirmation_ok"]
        XCTAssertTrue(exitConfirmationOKButton.waitForExistence(timeout: 5))
        exitConfirmationOKButton.tap()

        let playgroundCancelAlert = app.alerts["Cancelled"]
        XCTAssertTrue(playgroundCancelAlert.waitForExistence(timeout: 60.0))
    }

    // note that this does NOT complete the Auth Flow, but its a decent check on
    // whether live mode is ~working
    func testDataLiveModeOAuthWebAuthFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"data","experience":"financial_connections","sdk_type":"web","test_mode":false,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
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
        let institutionName: String?
        let capitalOneBankName = "Capital One"
        let capitalOneInstitutionButton = app.webViews
            .buttons
            .containing(NSPredicate(format: "label CONTAINS '\(capitalOneBankName)'"))
            .firstMatch
        if capitalOneInstitutionButton.waitForExistence(timeout: 10) {
            institutionButton = capitalOneInstitutionButton
            institutionName = capitalOneBankName
        } else {
            let wellsFargoBankName = "Wells Fargo"
            let wellsFargoInstitutionButton = app.webViews
                .buttons
                .containing(NSPredicate(format: "label CONTAINS '\(wellsFargoBankName)'"))
                .firstMatch
            if wellsFargoInstitutionButton.waitForExistence(timeout: 10) {
                institutionButton = wellsFargoInstitutionButton
                institutionName = wellsFargoBankName
            } else {
                institutionButton = nil
                institutionName = nil
            }
        }
        guard let institutionButton = institutionButton, let institutionName = institutionName else {
            XCTFail("Couldn't find a Live Mode institution.")
            return
        }
        institutionButton.tap()

        // ...at this point the bank is either:
        // 1. active, which means prepane is visible
        // 2. under maintenance, which means an 'error' screen is visible

        let prepaneContinueButton = app.webViews
            .buttons
            .containing(NSPredicate(format: "label CONTAINS 'Continue'"))
            .firstMatch

        // (1) bank is NOT under maintenance
        if prepaneContinueButton.waitForExistence(timeout: 60.0) {
            prepaneContinueButton.tap()

            // check that the WebView loaded
            var predicateString = "label CONTAINS '\(institutionName)'"
            if institutionName == capitalOneBankName {
                // Capital One does not contain the word "Capital One" on their log-in page
                predicateString = "label CONTAINS 'Username' OR label CONTAINS 'Password'"
            }
            let institutionWebViewText = app.webViews
                .staticTexts
                .containing(NSPredicate(format: predicateString))
                .firstMatch
            XCTAssertTrue(institutionWebViewText.waitForExistence(timeout: 120.0))
        }
        // (2) bank IS under maintenance
        else {
            // check that we see a maintenance error
            let errorViewText = app.webViews
                .staticTexts
                .containing(NSPredicate(format: "label CONTAINS 'unavailable' OR label CONTAINS 'maintenance' OR label CONTAINS 'scheduled'"))
                .firstMatch
            XCTAssertTrue(errorViewText.waitForExistence(timeout: 10))
        }

        app.fc_secureWebViewCancelButton.tap()

        let playgroundCancelAlert = app.alerts["Cancelled"]
        XCTAssertTrue(playgroundCancelAlert.waitForExistence(timeout: 60.0))
    }

    func testPaymentSearchInLiveModeNativeAuthFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":false,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let searchBarTextField = app.fc_searchBarTextField
        searchBarTextField.tap()
        searchBarTextField.typeText("Bank of America")

        let bankOfAmericaSearchRow = app.tables.staticTexts["Bank of America"]
        XCTAssertTrue(bankOfAmericaSearchRow.waitForExistence(timeout: 120.0))
        bankOfAmericaSearchRow.tap()

        // ...at this point the bank is either:
        // 1. active, which means prepane is visible
        // 2. under maintenance, which means an 'error' screen is visible

        // (1) bank is NOT under maintenance
        if app.fc_nativePrepaneContinueButton_noWait.waitForExistence(timeout: 60) {
            // close prepane
            app.fc_nativePrepaneCancelButton.tap()

            searchBarTextField.tap()
            clear(textField: searchBarTextField)
            searchBarTextField.typeText("testing123")

            let institutionSearchNoResultsSubtitle = app
                .otherElements["institution_search_no_results_subtitle"]
                .links
                .firstMatch
            XCTAssertTrue(institutionSearchNoResultsSubtitle.waitForExistence(timeout: 120.0))
            institutionSearchNoResultsSubtitle.tap()

            // check that manual entry screen is opened
            let manualEntryContinueButton = app.buttons["manual_entry_continue_button"]
            XCTAssertTrue(manualEntryContinueButton.waitForExistence(timeout: 60.0))
        }
        // (2) bank IS under maintenance
        else {
            // check that we see a maintenance error
            let errorViewText = app
                .textViews
                .containing(NSPredicate(format: "label CONTAINS 'unavailable' OR label CONTAINS 'maintenance' OR label CONTAINS 'scheduled'"))
                .firstMatch
            XCTAssertTrue(errorViewText.waitForExistence(timeout: 10))

            // 'cancel' the test as the bank is under the maintenance
        }
    }

    func testWebInstantDebitsFlow() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"instant_debits","sdk_type":"web","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        let authFlowWebViewUrl = app
            .otherElements["TopBrowserBar"]
            .otherElements
            .containing(NSPredicate(format: "value CONTAINS 'auth.stripe.com'"))
            .firstMatch
        XCTAssertTrue(authFlowWebViewUrl.waitForExistence(timeout: 120.0)) // glitch app can take time to load

        app.fc_secureWebViewCancelButton.tap()

        let playgroundCancelAlert = app.alerts["Cancelled"]
        XCTAssertTrue(playgroundCancelAlert.waitForExistence(timeout: 10.0))
    }

    func testNativeOnEventClosureEvents() throws {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        app.fc_nativeBackButton().waitForExistenceAndTap()

        app.fc_nativeConsentAgreeButton.waitForExistenceAndTap()

        app.fc_nativeFeaturedInstitution(name: "Test Institution").waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.tap()

        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'events=open,manual_entry_initiated,consent_acquired,institution_selected,institution_authorized,accounts_selected,success'")).firstMatch
                .exists
        )
    }

    func testNativeCustomManualEntryHandoff() {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":false,"merchant":"platform_c","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.waitForExistenceAndTap()

        let searchBarTextField = app.fc_searchBarTextField
        searchBarTextField.waitForExistenceAndTap()
        searchBarTextField.typeText("show_no_results")

        app.otherElements["institution_search_no_results_subtitle"].links.firstMatch.waitForExistenceAndTap()

        // ...manual entry screen will be skipped...

        let failedAlert = app.alerts["Failed"]
        XCTAssertTrue(failedAlert.waitForExistence(timeout: 60))
        XCTAssert(
            failedAlert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'FinancialConnectionsCustomManualEntryRequiredError'")).firstMatch
                .exists
        )
    }

    func testNativeSkipSuccessPane() {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"platform_c","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.waitForExistenceAndTap()

        app.fc_nativeFeaturedInstitution(name: "Test Institution").waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.waitForExistenceAndTap()

        let notNowButton = app.buttons["Not now"]
        XCTAssert(notNowButton.waitForExistence(timeout: 60)) // wait for networking sign up to show
        app.fc_dismissKeyboard()
        notNowButton.waitForExistenceAndTap() // skip networking sign up

        // ...the success pane will be skipped...

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testNativeConnectMerchantForDataUseCase() {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"data","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"connect","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        app.fc_nativeFeaturedInstitution(name: "Test Institution").waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.tap()

        XCTAssert(app.fc_nativeNetworkingNotNowButton.waitForExistence(timeout: 60)) // wait for networking sign up to show
        app.fc_dismissKeyboard()
        app.fc_nativeNetworkingNotNowButton.waitForExistenceAndTap() // skip networking sign up

        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testNativeConnectMerchantForPaymentUseCase() {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"connect","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        app.fc_nativeFeaturedInstitution(name: "Test Institution").waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.tap()

        XCTAssert(app.fc_nativeNetworkingNotNowButton.waitForExistence(timeout: 60)) // wait for networking sign up to show
        app.fc_dismissKeyboard()
        app.fc_nativeNetworkingNotNowButton.waitForExistenceAndTap() // skip networking sign up

        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    func testNativeConnectMerchantForPaymentManualEntryUseCase() {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"connect","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

        // the not now button could appear if networking manual entry is enabled
        if app.fc_nativeNetworkingNotNowButton.waitForExistence(timeout: 5) {
            app.fc_dismissKeyboard()
            app.fc_nativeNetworkingNotNowButton.waitForExistenceAndTap() // skip networking sign up
        }

        app.fc_nativeSuccessDoneButton.tap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    func testNativeConnectMerchantForTokenCase() {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"token","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"connect","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        app.fc_nativeFeaturedInstitution(name: "Test Institution").waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.tap()

        XCTAssert(app.fc_nativeNetworkingNotNowButton.waitForExistence(timeout: 60)) // wait for networking sign up to show
        app.fc_dismissKeyboard()
        app.fc_nativeNetworkingNotNowButton.waitForExistenceAndTap() // skip networking sign up

        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    // this tests going through "ResetFlowViewController"
    func testNativeResetFlowWithErrorToSuccess() throws {
        throw XCTSkip("Skipping this test case until we edit this institution's name")

        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.waitForExistenceAndTap()

        app.fc_scrollDown()

        app.fc_nativeFeaturedInstitution(name: "Down Bank (Unscheduled)").waitForExistenceAndTap()

        // selecting another bank will activate "reset flow"
        app.buttons["select_another_bank_button"].waitForExistenceAndTap()

        app.fc_nativeFeaturedInstitution(name: "Test Institution").waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.waitForExistenceAndTap()

        app.fc_nativeSuccessDoneButton.waitForExistenceAndTap()

        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }
}

extension XCTestCase {
    func wait(timeout: TimeInterval) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "")], timeout: timeout)
    }
}

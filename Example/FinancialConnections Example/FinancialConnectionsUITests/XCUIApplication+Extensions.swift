//
//  XCUIApplication+Extensions.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/26/23.
//

import Foundation
import XCTest

extension XCUIApplication {

    static func fc_launch(playgroundConfigurationString: String? = nil) -> XCUIApplication {
        var launchEnvironment: [String: String] = ["UITesting": "true"]
        launchEnvironment["UITesting_playground_configuration_string"] = playgroundConfigurationString

        let app = XCUIApplication()
        app.launchEnvironment = launchEnvironment
        app.launch()
        return app
    }

    // MARK: - Example App Helpers

    var fc_playgroundCell: XCUIElement {
        let playgroundCell = tables.staticTexts["Playground"]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 10.0), "\(#function) waiting failed")
        return playgroundCell
    }

    var fc_playgroundDataFlowButton: XCUIElement {
        let playgroundDataFlowButton = segmentedControls.buttons["Data"]
        XCTAssertTrue(playgroundDataFlowButton.waitForExistence(timeout: 60.0), "\(#function) waiting failed")
        return playgroundDataFlowButton
    }

    var fc_playgroundPaymentFlowButton: XCUIElement {
        let playgroundPaymentFlowButton = segmentedControls.buttons["Payments"]
        XCTAssertTrue(playgroundPaymentFlowButton.waitForExistence(timeout: 60.0), "\(#function) waiting failed")
        return playgroundPaymentFlowButton
    }

    var fc_playgroundNativeButton: XCUIElement {
        let playgroundNativeButton = segmentedControls.buttons["Native"]
        XCTAssertTrue(playgroundNativeButton.waitForExistence(timeout: 60.0), "\(#function) waiting failed")
        return playgroundNativeButton
    }

    var fc_playgroundEnableTestModeSwitch: XCUIElement {
        let enableTestModeSwitch = switches["Enable Test Mode"].firstMatch
        XCTAssertTrue(enableTestModeSwitch.waitForExistence(timeout: 60.0), "\(#function) waiting failed")
        return enableTestModeSwitch
    }

    var fc_playgroundShowAuthFlowButton: XCUIElement {
        let showAuthFlowButton = buttons["Show Auth Flow"]
        XCTAssertTrue(showAuthFlowButton.waitForExistence(timeout: 60.0), "Failed to press Playground App show auth flow button - \(#function) waiting failed")
        return showAuthFlowButton
    }

    var fc_playgroundSuccessAlertView: XCUIElement {
        let playgroundSuccessAlertView = alerts["Success"]
        XCTAssertTrue(playgroundSuccessAlertView.waitForExistence(timeout: 60.0), "Failed to show Playground App success alert - \(#function) waiting failed")
        return playgroundSuccessAlertView
    }

    // MARK: - SDK Helpers

    var fc_nativeConsentAgreeButton: XCUIElement {
        let consentAgreeButton = buttons["consent_agree_button"]
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0), "Failed to open Consent pane - \(#function) waiting failed")  // glitch app can take time to lload
        return consentAgreeButton
    }

    var fc_nativeManuallyVerifyLabel: XCUIElement {
        let consentManuallyVerifyLabel = otherElements["consent_manually_verify_label"]
        // wait so `consentManuallyVerifyLabel.links` returns correct values
        _ = consentManuallyVerifyLabel.waitForExistence(timeout: 10.0)
        // we need to dig into "links" (instead of just accessing the label directly)
        // because the label is part-label, part a link, and we want to tap the link
        //
        // the `lastMatch` is important for token flows:
        // - for unknown reason, the "Token" flow label returns "2" links for UI tests (iOS 17.2),
        //   where only the second one is tappable
        return consentManuallyVerifyLabel.links.lastMatch
    }

    var fc_nativeNetworkingWarmupContinueButton: XCUIElement {
        return buttons["link_continue_button"]
    }

    var fc_nativeTestModeAutofillButton: XCUIElement {
        return buttons["test_mode_autofill_button"]
    }

    var fc_nativePrepaneContinueButton_noWait: XCUIElement {
        let prepaneContinueButton = buttons["prepane_continue_button"]
        return prepaneContinueButton
    }

    var fc_nativePrepaneContinueButton: XCUIElement {
        let prepaneContinueButton = fc_nativePrepaneContinueButton_noWait
        XCTAssertTrue(prepaneContinueButton.waitForExistence(timeout: 60.0), "Failed to open Partner Auth Prepane - \(#function) waiting failed")
        // sometimes the prepane cancel button could be
        // in a loading state
        XCTAssertTrue(prepaneContinueButton.wait(
            until: {
                $0.isHittable == true
                && $0.isEnabled == true
            },
            timeout: 60
        ), "Prepane continue button failed to be hittable")
        return prepaneContinueButton
    }

    var fc_nativePrepaneCancelButton: XCUIElement {
        let prepaneCancelButton = buttons["prepane_cancel_button"]
        XCTAssertTrue(prepaneCancelButton.waitForExistence(timeout: 5), "Failed to press/open Partner Auth Prepane cancel button - \(#function) waiting failed")
        // sometimes the prepane cancel button could be
        // in a loading state
        XCTAssertTrue(prepaneCancelButton.wait(
            until: {
                $0.isHittable == true
                && $0.isEnabled == true
            },
            timeout: 60
        ), "Prepane cancel button failed to be hittable")
        return prepaneCancelButton
    }

    var fc_nativeConnectAccountsButton: XCUIElement {
        let accountPickerLinkAccountsButton = buttons["connect_accounts_button"]
        XCTAssertTrue(accountPickerLinkAccountsButton.waitForExistence(timeout: 120.0), "Failed to open Account Picker pane - \(#function) waiting failed")  // wait for accounts to fetch
        XCTAssert(accountPickerLinkAccountsButton.isEnabled, "no account selected")
        return accountPickerLinkAccountsButton
    }

    var fc_nativeSaveToLinkButton: XCUIElement {
        return buttons["Save with Link"]
    }

    var fc_nativeNetworkingNotNowButton: XCUIElement {
        return buttons["Not now"]
    }

    var fc_nativeSuccessDoneButton: XCUIElement {
        let successDoneButton = buttons["success_done_button"]
        XCTAssertTrue(successDoneButton.waitForExistence(timeout: 120.0), "Failed to open Success pane - \(#function) waiting failed")  // wait for accounts to link
        return successDoneButton
    }

    var fc_secureWebViewCancelButton: XCUIElement {
        let secureWebViewCancelButton = otherElements["TopBrowserBar"].buttons["Cancel"]
        XCTAssertTrue(secureWebViewCancelButton.waitForExistence(timeout: 5.0), "Failed to close secure browser - \(#function) waiting failed")  // wait for accounts to link
        return secureWebViewCancelButton
    }

    var fc_searchBarTextField: XCUIElement {
        let searchBarTextField = tables
            .otherElements
            .textFields["search_bar_text_field"]
        XCTAssertTrue(searchBarTextField.waitForExistence(timeout: 120.0))
        return searchBarTextField
    }

    func fc_nativeFeaturedInstitution(name: String) -> XCUIElement {
        let featuredTestInstitution = tables.cells.staticTexts[name]
        XCTAssertTrue(featuredTestInstitution.waitForExistence(timeout: 60.0))
        return featuredTestInstitution
    }

    func fc_nativeBankAccount(name: String) -> XCUIElement {
        let bankAccount = scrollViews.staticTexts[name]
        XCTAssertTrue(bankAccount.waitForExistence(timeout: 120.0))
        return bankAccount
    }

    func fc_nativeBackButton() -> XCUIElement {
        return navigationBars["fc_navigation_bar"].buttons["Back"]
    }

    func fc_scrollDown() {
        swipeUp(velocity: .verySlow)
    }

    func fc_dismissKeyboard() {
        toolbars.buttons["Done"].waitForExistenceAndTap()
    }
}

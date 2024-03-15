//
//  XCUIApplication+Extensions.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/26/23.
//

import Foundation
import XCTest

extension XCUIApplication {

    static func fc_launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
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

    var fc_nativePrepaneContinueButton_noWait: XCUIElement {
        let prepaneContinueButton = buttons["prepane_continue_button"]
        return prepaneContinueButton
    }

    var fc_nativePrepaneContinueButton: XCUIElement {
        let prepaneContinueButton = fc_nativePrepaneContinueButton_noWait
        XCTAssertTrue(prepaneContinueButton.waitForExistence(timeout: 60.0), "Failed to open Partner Auth Prepane - \(#function) waiting failed")
        return prepaneContinueButton
    }

    var fc_nativePrepaneCancelButton: XCUIElement {
        let prepaneCancelButton = buttons["prepane_cancel_button"]
        XCTAssertTrue(prepaneCancelButton.waitForExistence(timeout: 5), "Failed to press/open Partner Auth Prepane cancel button - \(#function) waiting failed")
        return prepaneCancelButton
    }

    var fc_nativeAccountPickerLinkAccountsButton: XCUIElement {
        let accountPickerLinkAccountsButton = buttons["account_picker_link_accounts_button"]
        XCTAssertTrue(accountPickerLinkAccountsButton.waitForExistence(timeout: 120.0), "Failed to open Account Picker pane - \(#function) waiting failed")  // wait for accounts to fetch
        return accountPickerLinkAccountsButton
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

    func dismissKeyboard() {
        let returnKey = keyboards.buttons["return"]
        if returnKey.exists && returnKey.isHittable {
            returnKey.tap()
        }
    }
}

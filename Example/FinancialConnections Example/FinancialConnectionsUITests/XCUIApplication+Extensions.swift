//
//  XCUIApplication+Extensions.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/26/23.
//

import Foundation
import XCTest

extension XCUIApplication {
    
    // MARK: - Example App Helpers
    
    var fc_playgroundCell: XCUIElement {
        let playgroundCell = tables.staticTexts["Playground"]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 10.0))
        return playgroundCell
    }
    
    var fc_playgroundDataFlowButton: XCUIElement {
        let playgroundDataFlowButton = segmentedControls.buttons["Data"]
        XCTAssertTrue(playgroundDataFlowButton.waitForExistence(timeout: 60.0))
        return playgroundDataFlowButton
    }
    
    var fc_playgroundNativeButton: XCUIElement {
        let playgroundNativeButton = segmentedControls.buttons["Native"]
        XCTAssertTrue(playgroundNativeButton.waitForExistence(timeout: 60.0))
        return playgroundNativeButton
    }
    
    var fc_playgroundEnableTestModeSwitch: XCUIElement {
        let enableTestModeSwitch = switches["Enable Test Mode"].firstMatch
        XCTAssertTrue(enableTestModeSwitch.waitForExistence(timeout: 60.0))
        return enableTestModeSwitch
    }
    
    var fc_playgroundShowAuthFlowButton: XCUIElement {
        let showAuthFlowButton = buttons["Show Auth Flow"]
        XCTAssertTrue(showAuthFlowButton.waitForExistence(timeout: 60.0))
        return showAuthFlowButton
    }
    
    var fc_playgroundSuccessAlertView: XCUIElement {
        let playgroundSuccessAlertView = alerts["Success"]
        XCTAssertTrue(playgroundSuccessAlertView.waitForExistence(timeout: 60.0))
        return playgroundSuccessAlertView
    }
    
    // MARK: - SDK Helpers

    var fc_consentAgreeButton: XCUIElement {
        let consentAgreeButton = buttons["consent_agree_button"]
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0))  // glitch app can take time to lload
        return consentAgreeButton
    }
    
    var fc_prepaneContinueButton: XCUIElement {
        let prepaneContinueButton = buttons["prepane_continue_button"]
        XCTAssertTrue(prepaneContinueButton.waitForExistence(timeout: 60.0))
        return prepaneContinueButton
    }
    
    var fc_successDoneButton: XCUIElement {
        let successDoneButton = buttons["success_done_button"]
        XCTAssertTrue(successDoneButton.waitForExistence(timeout: 120.0))  // wait for accounts to link
        return successDoneButton
    }
    
    
        
    // ...
}

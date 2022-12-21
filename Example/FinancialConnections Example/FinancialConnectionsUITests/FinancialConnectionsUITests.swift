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
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDataTestModeNativeAuthFlow() throws {
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
        XCTAssertTrue(consentAgreeButton.waitForExistence(timeout: 120.0)) // glitch app can take time to lload
        consentAgreeButton.tap()
        
        let featuredLegacyTestInstitution = app.collectionViews.staticTexts["Test Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()
        
        let accountPickerLinkAccountsButton = app.buttons["Link accounts"]
        XCTAssertTrue(accountPickerLinkAccountsButton.waitForExistence(timeout: 120.0)) // wait for accounts to fetch
        accountPickerLinkAccountsButton.tap()
        
        let successPaneDoneButton = app.buttons["Done"]
        XCTAssertTrue(successPaneDoneButton.waitForExistence(timeout: 120.0)) // wait for accounts to link
        successPaneDoneButton.tap()
        
        let playgroundSuccessAlert = app.alerts["Success"]
        XCTAssertTrue(playgroundSuccessAlert.waitForExistence(timeout: 60.0))
        
        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(playgroundSuccessAlert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch.exists)
    }
}

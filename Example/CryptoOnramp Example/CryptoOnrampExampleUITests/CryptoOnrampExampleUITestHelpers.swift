//
//  CryptoOnrampExampleUITestHelpers.swift
//  CryptoOnrampExampleUITests
//
//  Created by Michael Liberatore on 7/30/26.
//

import Foundation
import XCTest

extension CryptoOnrampExampleUITests {
    func enterText(
        _ text: String,
        in element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: .animationTimeout), "Text field should exist", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Text field should be hittable", file: file, line: line)
        element.tap()
        element.typeText(text)
    }

    func waitForLoadingToFinish(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let loadingLabel = app.staticTexts["Loading…"].firstMatch
        XCTAssertTrue(
            loadingLabel.waitForNonExistence(timeout: .networkTimeout),
            "Loading indicator should disappear",
            file: file,
            line: line
        )
    }

    @MainActor
    func dismissSavePasswordPromptIfPresent() {
        // The prompt is owned by AuthenticationServicesAgent, so it must be handled as a system interruption.
        let interruptionMonitor = addUIInterruptionMonitor(withDescription: "Save Password") { alert in
            let notNowButton = alert.buttons["Not Now"].firstMatch
            guard notNowButton.exists else {
                return false
            }

            notNowButton.tap()
            return true
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        removeUIInterruptionMonitor(interruptionMonitor)
    }

    func dismissKeyboard() {
        let doneButton = app.toolbars.buttons["Done"].firstMatch
        if doneButton.waitForExistence(timeout: 1) {
            doneButton.tap()
        }
    }

    static func makeRandomUSPhoneNumber() -> String {
        "+1212555\(String(format: "%04d", Int.random(in: 0...9999)))"
    }
}

extension TimeInterval {

    /// Rough timeout value to use when awaiting an operation that relies on networking.
    static let networkTimeout: TimeInterval = 60

    /// Rough timeout value to use when awaiting an operation that performs an animation or transition.
    static let animationTimeout: TimeInterval = 5
}

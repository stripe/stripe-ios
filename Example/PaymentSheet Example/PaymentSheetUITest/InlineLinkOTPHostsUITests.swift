//
//  InlineLinkOTPHostsUITests.swift
//  PaymentSheetUITest
//

import XCTest

/// Checks where a returning Link customer types their code in different merchant layouts: in the Embedded card when the SDK
/// can keep it above the keyboard, and in the Link dialog when the keyboard would cover it and nothing can move it.
class InlineLinkOTPHostsUITests: PaymentSheetUITestCase {
    // MARK: UIKit

    func testUIKitScrollView_typesInTheCard() {
        verifyCodeEntry(in: "uiKitScrollView", expectsDialog: false)
    }

    func testUIKitScrollViewBelowTallContent_typesInTheCard() {
        verifyCodeEntry(in: "uiKitScrollViewBelowTallContent", expectsDialog: false, scrollsToCard: true)
    }

    func testUIKitNoScrollViewNearTheTop_typesInTheCard() {
        verifyCodeEntry(in: "uiKitNoScrollViewTop", expectsDialog: false)
    }

    func testUIKitNoScrollViewAtTheBottom_usesTheDialog() {
        verifyCodeEntry(in: "uiKitNoScrollViewBottom", expectsDialog: true, dialogReason: "no_scroll_view")
    }

    // MARK: SwiftUI

    func testSwiftUIScrollView_typesInTheCard() {
        verifyCodeEntry(in: "swiftUIScrollView", expectsDialog: false)
    }

    func testSwiftUINoScrollViewAtTheBottom_usesTheDialog() {
        verifyCodeEntry(in: "swiftUINoScrollViewBottom", expectsDialog: true, dialogReason: "no_scroll_view")
    }

    // MARK: Helpers

    private func verifyCodeEntry(in host: String, expectsDialog: Bool, dialogReason: String? = nil, scrollsToCard: Bool = false) {
        // Given a returning Link customer's element in the host layout
        app.launch()
        app.swipeUp() // scroll to make the list item available on screen
        XCTAssertTrue(app.staticTexts["EmbeddedPaymentElement inline Link OTP hosts"].waitForExistenceAndTap())
        app.buttons[host].waitForExistenceAndTap()

        let card = app.otherElements["embedded_link_inline_verification"]
        XCTAssertTrue(card.waitForExistence(timeout: 20), "The inline Link verification card didn't appear")
        if scrollsToCard {
            // The code is only sent once the card is on screen.
            for _ in 0..<5 where !card.isHittable {
                app.swipeUp()
            }
        }
        let codeButton = card.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Enter the code sent to")).firstMatch
        let isEnabled = expectation(for: NSPredicate(format: "exists == true AND isEnabled == true"), evaluatedWith: codeButton)
        wait(for: [isEnabled], timeout: 15)

        // When the customer taps the code
        codeButton.tap()

        // Then it's typed in the card, or in the Link dialog when the keyboard would cover the card
        let outcome = app.staticTexts["inline_link_otp_outcome"]
        let expectedOutcome = expectsDialog ? "Last tap: Link dialog (\(dialogReason ?? ""))" : "Last tap: Typed in the card"
        let outcomeMatches = expectation(for: NSPredicate(format: "label == %@", expectedOutcome), evaluatedWith: outcome)
        wait(for: [outcomeMatches], timeout: 10)

        let focusedCodeField = app.textViews.matching(NSPredicate(format: "label == %@ AND hasKeyboardFocus == true", "Code field")).firstMatch
        XCTAssertTrue(focusedCodeField.waitForExistence(timeout: 10), "No code field has keyboard focus")
        let focusedCardCodeField = card.textViews.matching(NSPredicate(format: "hasKeyboardFocus == true")).firstMatch
        if expectsDialog {
            XCTAssertFalse(focusedCardCodeField.exists, "The card's code field took focus instead of the dialog's")
        } else {
            XCTAssertTrue(focusedCardCodeField.exists, "The code wasn't typed in the card")
            XCTAssertTrue(focusedCardCodeField.isHittable, "The card's code field isn't visible above the keyboard")
        }

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = host
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}

//
//  ButtonExtensionsTests.swift
//  StripeFinancialConnectionsTests
//

import UIKit
import XCTest

@testable import StripeFinancialConnections
@_spi(STP) import StripeUICore

final class ButtonExtensionsTests: XCTestCase {

    func testLinkSecondaryButtonScalesWhilePressed() {
        // Given a Link secondary button with animations disabled for deterministic assertions
        let button = StripeUICore.Button.secondary(appearance: .link)
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }

        // When the button is pressed
        button.sendActions(for: .touchDown)

        // Then it subtly shrinks
        XCTAssertEqual(button.transform.a, 0.97)
        XCTAssertEqual(button.transform.d, 0.97)

        // When the press ends
        button.sendActions(for: .touchUpInside)

        // Then it returns to its original size
        XCTAssertEqual(button.transform, .identity)
    }

    func testStripeSecondaryButtonDoesNotScaleWhilePressed() {
        // Given a Stripe secondary button
        let button = StripeUICore.Button.secondary(appearance: .stripe)

        // When the button is pressed
        button.sendActions(for: .touchDown)

        // Then its size does not change
        XCTAssertEqual(button.transform, .identity)
    }

    func testHorizontalLinkSecondaryButtonUsesOnePhysicalPixelBorder() {
        // Given a horizontal Link footer
        let footer = PaneLayoutView.createFooterView(
            primaryButtonConfiguration: .init(title: "Primary", action: {}),
            secondaryButtonConfiguration: .init(title: "Secondary", action: {}),
            appearance: .link,
            preferHorizontalButtonsForLink: true
        )

        // Then the secondary button border aligns to the physical pixel grid
        XCTAssertEqual(footer.secondaryButton?.layer.borderWidth, 1 / stp_screenNativeScale)
    }
}

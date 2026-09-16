//
//  BottomSheetViewControllerTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeIdentity

final class BottomSheetViewControllerTest: XCTestCase {
    func testPresentationConfiguration() throws {
        // Given bottom sheet content
        let verificationPage = try VerificationPageMock.response200.make()
        let content = try XCTUnwrap(verificationPage.bottomsheet?["consent_identity"])

        // When the bottom sheet is configured for presentation
        let viewController = try BottomSheetViewController.makeForPresentation(content: content)

        // Then it fills the sheet background without a navigation bar close button
        XCTAssertEqual(
            viewController.view.backgroundColor,
            IdentityUI.identityElementsUITheme.colors.componentBackground
        )
        XCTAssertNil(viewController.navigationItem.rightBarButtonItem)

        // ...and it starts at its calculated content height and can expand to large
        if #available(iOS 16.0, *) {
            let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier(
                "StripeIdentity.content"
            )
            XCTAssertEqual(
                viewController.sheetPresentationController?.detents.map(\.identifier),
                [contentDetentIdentifier, .large]
            )
            XCTAssertEqual(
                viewController.sheetPresentationController?.selectedDetentIdentifier,
                contentDetentIdentifier
            )
        } else {
            XCTAssertEqual(viewController.sheetPresentationController?.detents.count, 2)
            XCTAssertEqual(
                viewController.sheetPresentationController?.selectedDetentIdentifier,
                .medium
            )
        }
    }
}

//
//  CardScanViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) @testable import StripeUICore

import XCTest

// @iOS26
final class CardScanViewControllerSnapshotTests: STPSnapshotTestCase {
    func testScanning() {
        // Given the card scan screen
        let sut = makeSUT()

        // Then it shows the viewfinder looking for a card
        STPSnapshotVerifyView(sut.view)
    }

    func testScanned() {
        // Given the card scan screen
        let sut = makeSUT()

        // When a card is scanned
        sut.viewfinderView.state = .scanned

        // Then it shows the success state
        STPSnapshotVerifyView(sut.view)
    }

    func testCameraError() {
        // Given the card scan screen
        let sut = makeSUT()

        // When the camera can't be used
        sut.viewfinderView.state = .error

        // Then it asks the customer to allow camera access
        STPSnapshotVerifyView(sut.view)
    }

    private func makeSUT() -> CardScanViewController {
        var appearance = PaymentSheet.Appearance.default
        appearance.applyLiquidGlassIfPossible()
        let sut = CardScanViewController(
            appearance: appearance,
            theme: appearance.asElementsTheme,
            underlyingContentViewController: nil
        )
        sut.view.autosizeHeight(width: 375)
        return sut
    }
}

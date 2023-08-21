//
//  SelfieWarmupViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 8/15/23.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class SelfieWarmupViewControllerTest: XCTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: SelfieWarmupViewController!
    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = try! SelfieWarmupViewController(
            sheetController: mockSheetController
        )
    }

    func testTapContinue() {
        // Tap continue button
        vc.flowViewModel.buttons.first?.didTap()

        // Verify transitioned to selfie capture
        XCTAssertTrue(mockSheetController.transitionedToSelfieCapture)
    }

}

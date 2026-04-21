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
        XCTAssertNil(mockSheetController.transitionedToSelfieCaptureTrainingConsent)
    }

    func testTapAllowCapturesTrainingConsent() {
        let vc = try! SelfieWarmupViewController(
            sheetController: mockSheetController,
            trainingConsentText: SelfieWarmupViewControllerTest.mockVerificationPage.selfie?
                .trainingConsentText
        )

        XCTAssertEqual(vc.flowViewModel.buttons.count, 2)

        vc.flowViewModel.buttons.first?.didTap()

        XCTAssertTrue(mockSheetController.transitionedToSelfieCapture)
        XCTAssertEqual(
            mockSheetController.transitionedToSelfieCaptureTrainingConsent,
            true
        )
    }

    func testTapDeclineCapturesTrainingConsent() {
        let vc = try! SelfieWarmupViewController(
            sheetController: mockSheetController,
            trainingConsentText: SelfieWarmupViewControllerTest.mockVerificationPage.selfie?
                .trainingConsentText
        )

        XCTAssertEqual(vc.flowViewModel.buttons.count, 2)

        vc.flowViewModel.buttons.last?.didTap()

        XCTAssertTrue(mockSheetController.transitionedToSelfieCapture)
        XCTAssertEqual(
            mockSheetController.transitionedToSelfieCaptureTrainingConsent,
            false
        )
    }

}

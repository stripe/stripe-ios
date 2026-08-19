//
//  SelfieWarmupViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 8/15/23.
//

import XCTest

@testable import StripeIdentity

final class SelfieWarmupViewControllerTest: XCTestCase {
    private static let mockVerificationPage = try! VerificationPageMock.response200.make()

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
        XCTAssertEqual(vc.flowViewModel.buttons.last?.text, "Decline")
        XCTAssertTrue(
            vc.flowViewModel.buttonTopContentViewModel?.text.contains(
                "Help us improve verifications"
            ) == true
        )

        vc.flowViewModel.buttons.last?.didTap()

        XCTAssertTrue(mockSheetController.transitionedToSelfieCapture)
        XCTAssertEqual(
            mockSheetController.transitionedToSelfieCaptureTrainingConsent,
            false
        )
    }

    func testBiometricConsentLayoutUsesServerCopy() throws {
        let trainingConsentText = try XCTUnwrap(
            SelfieWarmupViewControllerTest.mockVerificationPage.selfie?
                .trainingConsentText
        )
        let declineAndContinueButtonText = try XCTUnwrap(
            SelfieWarmupViewControllerTest.mockVerificationPage.selfie?
                .declineAndContinueButtonText
        )
        let vc = try SelfieWarmupViewController(
            sheetController: mockSheetController,
            usesBiometricConsentLayout: true,
            trainingConsentText: trainingConsentText,
            declineAndContinueButtonText: declineAndContinueButtonText
        )

        XCTAssertEqual(vc.flowViewModel.buttons.last?.text, "Decline and continue")
        XCTAssertEqual(vc.flowViewModel.buttonTopContentViewModel?.text, trainingConsentText)
    }

}

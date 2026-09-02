//
//  BiometricConsentViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class BiometricConsentViewControllerTest: XCTestCase {

    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: BiometricConsentViewController!
    private let mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = try! BiometricConsentViewController(
            brandLogo: UIImage(),
            showsStripeLogo: !BiometricConsentViewControllerTest.mockVerificationPage.isStripe,
            consentContent: BiometricConsentViewControllerTest.mockVerificationPage
                .biometricConsent,
            sheetController: mockSheetController
        )
    }

    func testAccept() {
        vc.scrolledToBottom = true
        // Tap accept button
        vc.flowViewModel.buttons.first?.didTap()

        // Verify biometricConsent is saved
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, true)
    }

    func testDeny() {
        // Tap accept button
        vc.flowViewModel.buttons.last?.didTap()

        // Verify biometricConsent is saved
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, false)
    }

    func testSubtitle() throws {
        // Given the verification page has a biometric consent subtitle
        let expectedSubtitle = "Complete a one-time identity check to enable withdrawals."

        // When the biometric consent view model is created
        let subtitle = vc.flowViewModel.headerViewModel?.subtitleText

        // Then it displays the API-provided subtitle
        XCTAssertEqual(subtitle, expectedSubtitle)
    }

    func testSubtitleIsOptional() throws {
        // Given the verification page has no biometric consent subtitle
        let verificationPage = try VerificationPageMock.response200NoConsentHeader.make()

        // When the response is decoded
        let subtitle = verificationPage.biometricConsent.subtitle

        // Then decoding succeeds without a subtitle
        XCTAssertNil(subtitle)
    }
}

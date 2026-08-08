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

@MainActor
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

    func testAccept() async {
        let saveExp = expectation(description: "Consent saved")
        mockSheetController.saveAndTransitionCallback = {
            saveExp.fulfill()
        }
        vc.scrolledToBottom = true
        // Tap accept button
        vc.flowViewModel.buttons.first?.didTap()

        await fulfillment(of: [saveExp], timeout: 1)

        // Verify biometricConsent is saved
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, true)
    }

    func testDeny() async {
        let saveExp = expectation(description: "Consent saved")
        mockSheetController.saveAndTransitionCallback = {
            saveExp.fulfill()
        }
        // Tap deny button
        vc.flowViewModel.buttons.last?.didTap()

        await fulfillment(of: [saveExp], timeout: 1)

        // Verify biometricConsent is saved
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, false)
    }
}

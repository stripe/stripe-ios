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
}

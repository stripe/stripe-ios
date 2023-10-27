//
//  BiometricConsentViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

final class BiometricConsentViewControllerSnapshotTest: STPSnapshotTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()
    static let mockVerificationPageNoConsentHeader = try! VerificationPageMock.response200NoConsentHeader.make()

    func testViewIsConfiguredFromAPI() throws {
        let vc = try BiometricConsentViewController(
            brandLogo: SnapshotTestMockData.uiImage(image: .headerIcon),
            consentContent: BiometricConsentViewControllerSnapshotTest.mockVerificationPage
                .biometricConsent,
            sheetController: VerificationSheetControllerMock()
        )

        STPSnapshotVerifyView(vc.view)
    }

    func testViewIsConfiguredFromAPINoConsentHeader() throws {
        let vc = try BiometricConsentViewController(
            brandLogo: SnapshotTestMockData.uiImage(image: .headerIcon),
            consentContent: BiometricConsentViewControllerSnapshotTest.mockVerificationPageNoConsentHeader
                .biometricConsent,
            sheetController: VerificationSheetControllerMock()
        )

        STPSnapshotVerifyView(vc.view)
    }
}

//
//  BiometricConsentViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/14/22.
//

import Foundation
import FBSnapshotTestCase
@testable import StripeIdentity

@available(iOS 13, *)
final class BiometricConsentViewControllerSnapshotTest: FBSnapshotTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testViewIsConfiguredFromAPI() throws {
        let vc = try BiometricConsentViewController(
            brandLogo: SnapshotTestMockData.uiImage(image: .headerIcon),
            consentContent: BiometricConsentViewControllerSnapshotTest.mockVerificationPage.biometricConsent,
            sheetController: VerificationSheetControllerMock()
        )

        FBSnapshotVerifyView(vc.view)
    }
}

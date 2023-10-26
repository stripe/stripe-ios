//
//  IndividualWelcomeViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 2/15/23.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

final class IndividualWelcomeViewControllerSnapshotTest: STPSnapshotTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    func testViewIsConfiguredFromAPI() throws {
        let vc = try IndividualWelcomeViewController(
            brandLogo: SnapshotTestMockData.uiImage(image: .headerIcon),
            welcomeContent: IndividualWelcomeViewControllerSnapshotTest.mockVerificationPage
                .individualWelcome,
            sheetController: VerificationSheetControllerMock()
        )

        STPSnapshotVerifyView(vc.view)
    }
}

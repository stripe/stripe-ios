//
//  IndividualWelcomeViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 2/15/23.
//

import Foundation
import iOSSnapshotTestCase

@testable import StripeIdentity

final class IndividualWelcomeViewControllerSnapshotTest: FBSnapshotTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

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

//
//  SuccessViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable import StripeIdentity

final class SuccessViewControllerSnapshotTest: STPSnapshotTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    func testViewIsConfiguredFromAPI() {
        let vc = SuccessViewController(
            successContent: SuccessViewControllerSnapshotTest.mockVerificationPage.success,
            sheetController: VerificationSheetControllerMock()
        )

        STPSnapshotVerifyView(vc.view)

        // Verify tint color updates icon background
        vc.view.tintColor = .systemPink
        STPSnapshotVerifyView(vc.view, identifier: "change_tint")
    }
}

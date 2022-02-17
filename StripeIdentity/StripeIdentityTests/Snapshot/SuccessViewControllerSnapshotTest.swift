//
//  SuccessViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/15/22.
//

import Foundation
import FBSnapshotTestCase
@testable import StripeIdentity

final class SuccessViewControllerSnapshotTest: FBSnapshotTestCase {
    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testViewIsConfiguredFromAPI() {
        let vc = SuccessViewController(
            successContent: SuccessViewControllerSnapshotTest.mockVerificationPage.success,
            sheetController: VerificationSheetControllerMock()
        )

        FBSnapshotVerifyView(vc.view)

        // Verify tint color updates icon background
        vc.view.tintColor = .systemPink
        FBSnapshotVerifyView(vc.view, identifier: "change_tint")
    }
}

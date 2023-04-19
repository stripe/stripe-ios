//
//  DebugViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 4/19/23.
//

import Foundation

@testable import StripeIdentity
import iOSSnapshotTestCase

final class DebugViewControllerSnapshotTest: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testViewIsConfigured() {
        let vc = DebugViewController(sheetController: VerificationSheetControllerMock())

        STPSnapshotVerifyView(vc.view)
    }
}

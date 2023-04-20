//
//  DebugViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 4/19/23.
//

import Foundation

import iOSSnapshotTestCase
@testable import StripeIdentity

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

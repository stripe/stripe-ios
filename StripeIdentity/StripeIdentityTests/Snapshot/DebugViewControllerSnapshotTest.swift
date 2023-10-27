//
//  DebugViewControllerSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 4/19/23.
//

import Foundation

import iOSSnapshotTestCase
import StripeCoreTestUtils
@testable import StripeIdentity

final class DebugViewControllerSnapshotTest: STPSnapshotTestCase {
    func testViewIsConfigured() {
        let vc = DebugViewController(sheetController: VerificationSheetControllerMock())

        STPSnapshotVerifyView(vc.view)
    }
}

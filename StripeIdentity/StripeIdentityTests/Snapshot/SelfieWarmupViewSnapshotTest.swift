//
//  SelfieWarmupViewSnapshotTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 8/15/23.
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable import StripeIdentity
@_spi(STP) import StripeUICore

class SelfieWarmupViewSnapshotTest: STPSnapshotTestCase {

    func testSelfieWarmupView() {
        let view = SelfieWarmupView()
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: #filePath, line: #line)
    }

}

//
//  SelfieWarmupViewSnapshotTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 8/15/23.
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
@testable import StripeIdentity
@_spi(STP) import StripeUICore

class SelfieWarmupViewSnapshotTest: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testSelfieWarmupView() {
        let view = SelfieWarmupView()
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: #filePath, line: #line)
    }

}

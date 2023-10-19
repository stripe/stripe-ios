//
//  File.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 9/29/23.
//

import Foundation

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@testable import StripeIdentity

class BottomSheetViewSnapshotTest: FBSnapshotTestCase {
    let bottomSheetView = try! BottomSheetView(
        content: .init(bottomsheetId: "bottomsheet_id", title: "bottomsheet title", lines: [
            .init(icon: .camera, title: "camera line title", content: "camera line content"),
            .init(icon: nil, title: "nil icon line title", content: "nil icon line content"),
        ]),
        didTapClose: {},
        didOpenURL: { _ in }
    )

    override func setUp() {
        super.setUp()
//                recordMode = true
    }

    func testBottomSheetView () {
        bottomSheetView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(bottomSheetView)
    }
}

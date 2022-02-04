//
//  HeaderIconViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Jaime Park on 2/1/22.
//

import FBSnapshotTestCase
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@testable import StripeIdentity

class HeaderIconViewSnapshotTest: FBSnapshotTestCase {
    let iconView = HeaderIconView()
    let iconImage = SnapshotTestMockData.uiImage(image: .headerIcon)

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testBrandIconView() {
        verifyView(with: .init(iconType: .brand, iconImage: iconImage))
    }

    func testPlainIconView() {
        verifyView(with: .init(iconType: .plain, iconImage: iconImage))
    }
}

private extension HeaderIconViewSnapshotTest {
    func verifyView(
        with viewModel: HeaderIconView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        iconView.configure(with: viewModel)
        iconView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(iconView, file: file, line: line)
    }
}

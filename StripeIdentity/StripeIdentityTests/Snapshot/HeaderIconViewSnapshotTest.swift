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

    override func tearDown() {
        iconView.tintColor = nil
        super.tearDown()
    }

    func testBrandIconView() {
        verifyView(with: .init(
            iconType: .brand,
            iconImage: iconImage,
            iconImageContentMode: .scaleAspectFill
        ))
    }

    func testPlainIconView() {
        verifyView(with: .init(
            iconType: .plain,
            iconImage: iconImage,
            iconImageContentMode: .scaleAspectFill
        ))
    }

    func testPlainIconViewWithBackground() {
        verifyView(with: .init(
            iconType: .plain,
            iconImage: StripeIdentity.Image.iconClock.makeImage(template: true),
            iconImageContentMode: .center,
            iconTintColor: .white,
            shouldIconBackgroundMatchTintColor: true
        ))

        // Change the tint color and verify it updates
        iconView.tintColor = .systemPink
        FBSnapshotVerifyView(iconView, identifier: "change_tint")
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

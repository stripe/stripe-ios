//
//  HeaderViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Jaime Park on 1/26/22.
//

import FBSnapshotTestCase
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@testable import StripeIdentity

class HeaderViewSnapshotTest: FBSnapshotTestCase {
    typealias IconViewModel = HeaderIconView.ViewModel

    let headerView = HeaderView()
    let iconImage = SnapshotTestMockData.uiImage(image: .headerIcon)

    let shortTitleText = "Short Title"
    let longTitleText = "A Very Long Title. This Title is Sometimes a Question?"

    let plainHeaderBackgroundColor: UIColor = .white
    let bannerHeaderBackgroundColor: UIColor = .lightGray

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testPlainHeaderShortTitle() {
        verifyView(with: .init(backgroundColor: plainHeaderBackgroundColor,
                               headerType: .plain,
                               titleText: shortTitleText))
    }

    func testPlainHeaderLongTitle() {
        verifyView(with: .init(backgroundColor: plainHeaderBackgroundColor,
                               headerType: .plain,
                               titleText: longTitleText))
    }

    func testBannerHeaderShortTitle_NoIcons() {
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconViewModel: nil),
                               titleText: shortTitleText))
    }

    func testBannerHeaderLongTitle_NoIcons() {
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconViewModel: nil),
                               titleText: longTitleText))
    }

    func testBannerHeaderShortTitle_PlainIcon() {
        let viewModel = IconViewModel(iconType: .plain, iconImage: iconImage, iconImageContentMode: .scaleAspectFill)
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconViewModel: viewModel),
                               titleText: shortTitleText))
    }

    func testBannerHeaderLongTitle_BrandIcon() {
        let viewModel = IconViewModel(iconType: .brand, iconImage: iconImage, iconImageContentMode: .scaleAspectFill)
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconViewModel: viewModel),
                               titleText: longTitleText))
    }

    func testHeaderReconfigure() {
        let headerView = HeaderView()
        let viewModel = IconViewModel(iconType: .brand, iconImage: iconImage, iconImageContentMode: .scaleAspectFill)

        let firstConfigurationVersion: HeaderView.ViewModel = .init(backgroundColor: .red,
                                                                   headerType: .plain,
                                                                   titleText: "First Configured Header Title")
        let secondConfigurationVersion: HeaderView.ViewModel = .init(backgroundColor: .blue,
                                                                     headerType: .banner(iconViewModel: viewModel),
                                                                     titleText: "Second Configured Header Title")

        // Configure the header view multiple times to check if the view updates properly
        headerView.configure(with: firstConfigurationVersion)
        headerView.configure(with: secondConfigurationVersion)
        verifyView(with: secondConfigurationVersion)
    }
}

private extension HeaderViewSnapshotTest {
    func verifyView(
        with viewModel: HeaderView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        headerView.configure(with: viewModel)
        headerView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(headerView, file: file, line: line)
    }
}

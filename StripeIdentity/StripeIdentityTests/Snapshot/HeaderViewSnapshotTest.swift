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
    let headerView = HeaderView()
    let iconView: UIView = {
        let view = UIView()
        let iconView = UIView()

        iconView.layer.cornerRadius = 8.0
        iconView.layer.masksToBounds = true
        iconView.backgroundColor = .green
        iconView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.heightAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            iconView.widthAnchor.constraint(equalToConstant: 32),
        ])

        return view
    }()

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
                               headerType: .banner(iconView: nil),
                               titleText: shortTitleText))
    }

    func testBannerHeaderLongTitle_NoIcons() {
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconView: nil),
                               titleText: longTitleText))
    }

    func testBannerHeaderShortTitle() {
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconView: iconView),
                               titleText: shortTitleText))
    }

    func testBannerHeaderLongTitle() {
        verifyView(with: .init(backgroundColor: bannerHeaderBackgroundColor,
                               headerType: .banner(iconView: iconView),
                               titleText: longTitleText))
    }

    func testHeaderReconfigure() {
        let headerView = HeaderView()
        let firstConfigurationVersion: HeaderView.ViewModel = .init(backgroundColor: .red,
                                                                   headerType: .plain,
                                                                   titleText: "First Configured Header Title")
        let secondConfigurationVersion: HeaderView.ViewModel = .init(backgroundColor: .blue,
                                                                     headerType: .banner(iconView: iconView),
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

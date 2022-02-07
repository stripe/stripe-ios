//
//  ListItemViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 1/11/22.
//

import FBSnapshotTestCase
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@testable import StripeIdentity

final class ListItemViewSnapshotTest: FBSnapshotTestCase {

    let listItemView = ListItemView()

    let longText = "Some very long text that should wrap to multiple lines"
    let shortText = "Short text"

    let buttonText = "Select"

    override func setUp() {
        super.setUp()

        UIActivityIndicatorView.stp_isAnimationEnabled = false

//        recordMode = true
    }

    override func tearDown() {
        UIActivityIndicatorView.stp_isAnimationEnabled = true
        super.tearDown()
    }

    func testShortTextNoAccessory() {
        verifyView(with: .init(text: shortText, accessory: nil, onTap: nil))
    }

    func testShortTextButtonAccessory() {
        verifyView(with: .init(text: shortText, accessory: .button(title: buttonText, onTap: {}), onTap: nil))
    }

    func testShortTextActivityIndicatorAccessory() {
        verifyView(with: .init(text: shortText, accessory: .activityIndicator, onTap: nil))
    }

    func testShortTextIconAccessoryWithTint() {
        verifyView(with: .init(
            text: shortText,
            accessory: .icon(
                Image.icon_chevron_down.makeImage(template: true),
                tintColor: .purple
            ), onTap: nil
        ))
    }

    func testLongTextNoAccessory() {
        verifyView(with: .init(text: longText, accessory: nil, onTap: nil))
    }

    func testLongTextButtonAccessory() {
        verifyView(with: .init(text: longText, accessory: .button(title: buttonText, onTap: {}), onTap: nil))
    }

    func testLongTextActivityIndicatorAccessory() {
        verifyView(with: .init(text: longText, accessory: .activityIndicator, onTap: nil))
    }

    func testLongTextIconAccessoryNoTint() {
        verifyView(with: .init(
            text: longText,
            accessory: .icon(
                Image.icon_chevron_down.makeImage(),
                tintColor: nil
            ), onTap: nil
        ))
    }
}

private extension ListItemViewSnapshotTest {
    func verifyView(
        with viewModel: ListItemView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        listItemView.configure(with: viewModel)
        listItemView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(listItemView, file: file, line: line)
    }
}

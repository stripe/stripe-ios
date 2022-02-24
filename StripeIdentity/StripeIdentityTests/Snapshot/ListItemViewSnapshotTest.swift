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

        ActivityIndicator.isAnimationEnabled = false

//        recordMode = true
    }

    override func tearDown() {
        ActivityIndicator.isAnimationEnabled = true
        super.tearDown()
    }

    func testShortTextNoAccessory() {
        verifyView(
            with: .init(text: shortText, accessibilityLabel: nil, accessory: nil, onTap: nil),
            tintColor: .systemBlue
        )
    }

    func testShortTextButtonAccessory() {
        verifyView(
            with: .init(
                text: shortText,
                accessibilityLabel: nil,
                accessory: .button(
                    title: buttonText,
                    onTap: {}
                ),
                onTap: nil
            ),
            tintColor: .systemPink
        )
    }

    func testShortTextActivityIndicatorAccessory() {
        verifyView(
            with: .init(
                text: shortText,
                accessibilityLabel: nil,
                accessory: .activityIndicator,
                onTap: nil
            ),
            tintColor: .systemRed
        )
    }

    func testShortTextIconAccessoryWithTint() {
        verifyView(
            with: .init(
                text: shortText,
                accessibilityLabel: nil,
                accessory: .icon(
                    Image.icon_chevron_down.makeImage(template: true)
                ), onTap: nil
            ),
            tintColor: .purple
        )
    }

    func testLongTextNoAccessory() {
        verifyView(
            with: .init(text: longText, accessibilityLabel: nil, accessory: nil, onTap: nil),
            tintColor: .systemBlue
        )
    }

    func testLongTextButtonAccessory() {
        verifyView(
            with: .init(
                text: longText,
                accessibilityLabel: nil,
                accessory: .button(
                    title: buttonText,
                    onTap: {}
                ),
                onTap: nil
            ),
            tintColor: .systemBlue
        )
    }

    func testLongTextActivityIndicatorAccessory() {
        verifyView(
            with: .init(
                text: longText,
                accessibilityLabel: nil,
                accessory: .activityIndicator,
                onTap: nil
            ),
            tintColor: .systemBlue
        )
    }

    func testLongTextIconAccessoryNoTint() {
        verifyView(
            with: .init(
                text: longText,
                accessibilityLabel: nil,
                accessory: .icon(
                    Image.icon_chevron_down.makeImage()
                ), onTap: nil
            ),
            tintColor: .systemBlue
        )
    }
}

private extension ListItemViewSnapshotTest {
    func verifyView(
        with viewModel: ListItemView.ViewModel,
        tintColor: UIColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        listItemView.tintColor = tintColor
        listItemView.configure(with: viewModel)
        listItemView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(listItemView, file: file, line: line)
    }
}

//
//  ListViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 1/11/22.
//

import FBSnapshotTestCase
@_spi(STP) import StripeUICore
@testable import StripeIdentity

final class ListViewSnapshotTest: FBSnapshotTestCase {
    let listView = ListView()

    static let longText = "Some very long text that should wrap to multiple lines"
    static let shortText = "Short text"
    static let buttonText = "Select"
    static let iconImage = Image.icon_chevron_down.makeImage()

    static let oneItemViewModel = ListView.ViewModel(items: [
        .init(
            text: shortText,
            accessibilityLabel: nil,
            accessory: .activityIndicator,
            onTap: nil
        )
    ])

    static let manyItemViewModel = ListView.ViewModel(items: [
        .init(
            text: shortText,
            accessibilityLabel: nil,
            accessory: .activityIndicator,
            onTap: nil
        ),
        .init(
            text: longText,
            accessibilityLabel: nil,
            accessory: .icon(
                iconImage
            ),
            onTap: nil
        ),
        .init(
            text: shortText,
            accessibilityLabel: nil,
            accessory: .button(
                title: buttonText,
                onTap: {}
            ),
            onTap: nil
        ),
        .init(text: longText, accessibilityLabel: nil, accessory: nil, onTap: nil),
    ])

    override func setUp() {
        super.setUp()

        listView.tintColor = .systemBlue

//        recordMode = true
    }

    func testNoItems() {
        // We can't take a snapshot of an empty view, but we can test that it's
        // visually empty by checking its height
        listView.configure(with: .init(items: []))
        listView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        XCTAssertEqual(listView.frame.height, 0)
    }

    func testOneItem() {
        verifyView(with: ListViewSnapshotTest.oneItemViewModel)
    }

    func testManyItems() {
        verifyView(with: ListViewSnapshotTest.manyItemViewModel)
    }

    func testReconfigureFewerItems() {
        listView.configure(with: ListViewSnapshotTest.oneItemViewModel)
        verifyView(with: ListViewSnapshotTest.manyItemViewModel)
    }

    func testReconfigureMoreItems() {
        listView.configure(with: ListViewSnapshotTest.manyItemViewModel)
        verifyView(with: ListViewSnapshotTest.oneItemViewModel)
    }
}

private extension ListViewSnapshotTest {
    func verifyView(
        with viewModel: ListView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        listView.configure(with: viewModel)
        listView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(listView, file: file, line: line)
    }
}

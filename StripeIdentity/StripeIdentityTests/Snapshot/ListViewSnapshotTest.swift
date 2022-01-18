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

    // Use a width of 375 to simulate common device width
    let mockDeviceWidth: CGFloat = 375

    let longText = "Some very long text that should wrap to multiple lines"
    let shortText = "Short text"

    let buttonText = "Select"
    let iconImage = Image.icon_chevron_down.makeImage()


    private lazy var oneItemViewModel = ListView.ViewModel(items: [
        .init(text: shortText, accessory: .activityIndicator)
    ])

    private lazy var manyItemViewModel = ListView.ViewModel(items: [
        .init(text: shortText, accessory: .activityIndicator),
        .init(text: longText, accessory: .icon(iconImage, tintColor: nil)),
        .init(text: shortText, accessory: .button(title: buttonText, onTap: {})),
        .init(text: longText, accessory: nil),
    ])

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testNoItems() {
        // We can't take a snapshot of an empty view, but we can test that it's
        // visually empty by checking its height
        listView.configure(with: .init(items: []))
        listView.autosizeHeight(width: mockDeviceWidth)
        XCTAssertEqual(listView.frame.height, 0)
    }

    func testOneItem() {
        verifyView(with: oneItemViewModel)
    }

    func testManyItems() {
        verifyView(with: manyItemViewModel)
    }

    func testReconfigureFewerItems() {
        listView.configure(with: oneItemViewModel)
        verifyView(with: manyItemViewModel)
    }

    func testReconfigureMoreItems() {
        listView.configure(with: manyItemViewModel)
        verifyView(with: oneItemViewModel)
    }
}

private extension ListViewSnapshotTest {
    func verifyView(
        with viewModel: ListView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        listView.configure(with: viewModel)
        listView.autosizeHeight(width: mockDeviceWidth)
        FBSnapshotVerifyView(listView, file: file, line: line)
    }
}

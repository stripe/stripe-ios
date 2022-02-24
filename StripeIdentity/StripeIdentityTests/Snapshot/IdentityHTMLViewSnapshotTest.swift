//
//  IdentityHTMLViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/12/22.
//

import Foundation
import FBSnapshotTestCase
@_spi(STP) import StripeUICore
@testable import StripeIdentity

final class IdentityHTMLViewSnapshotTest: FBSnapshotTestCase {

    let view = IdentityHTMLView()

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testWithIconShortText() throws {
        try verifyView(with: .init(
            iconText: .init(
                image: StripeIdentity.Image.iconCheckmark.makeImage(),
                text: "One line of text"
            ),
            htmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
            didOpenURL: { _ in }
        ))
    }

    func testWithIconLongText() throws {
        try verifyView(with: .init(
            iconText: .init(
                image: StripeIdentity.Image.iconClock.makeImage(),
                text: "Some text that is really long and wraps to multiple lines"
            ),
            htmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
            didOpenURL: { _ in }
        ))
    }

    func testWithoutIconText() throws {
        try verifyView(with: .init(
            iconText: nil,
            htmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
            didOpenURL: { _ in }
        ))
    }
}


private extension IdentityHTMLViewSnapshotTest {
    func verifyView(
        with viewModel: IdentityHTMLView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try view.configure(with: viewModel)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(view, file: file, line: line)
    }

}

//
//  IdentityHTMLViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
@_spi(STP) import StripeUICore

@testable @_spi(STP) import StripeIdentity

final class IdentityHTMLViewSnapshotTest: FBSnapshotTestCase {

    let view = HTMLViewWithIconLabels()

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testWithIconShortText() throws {
        try verifyView(
            with: .init(
                iconText: [
                    .init(
                        image: StripeIdentity.Image.iconCheckmark.makeImage(),
                        text: "One line of text",
                        isTextHTML: false
                    ),
                ],
                bodyHtmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
                didOpenURL: { _ in }
            )
        )
    }

    func testWithIconLongText() throws {
        try verifyView(
            with: .init(
                iconText: [
                    .init(
                        image: StripeIdentity.Image.iconClock.makeImage(),
                        text: "Some text that is really long and wraps to multiple lines",
                        isTextHTML: false
                    ),
                ],
                bodyHtmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
                didOpenURL: { _ in }
            )
        )
    }

    func testWithMultipleIconTexts() throws {
        try verifyView(
            with: .init(
                iconText: [
                    .init(
                        image: StripeIdentity.Image.iconClock.makeImage(),
                        text: "<b>Plain text</b>",
                        isTextHTML: false
                    ),
                    .init(
                        image: StripeIdentity.Image.iconInfo.makeImage(),
                        text: "<b>Bold</b> and <i>italic</i> HTML text",
                        isTextHTML: true
                    ),
                ],
                bodyHtmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
                didOpenURL: { _ in }
            )
        )
    }

    func testWithoutIconText() throws {
        try verifyView(
            with: .init(
                iconText: [],
                bodyHtmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
                didOpenURL: { _ in }
            )
        )
    }
}

extension IdentityHTMLViewSnapshotTest {
    fileprivate func verifyView(
        with viewModel: HTMLViewWithIconLabels.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try view.configure(with: viewModel)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }

}

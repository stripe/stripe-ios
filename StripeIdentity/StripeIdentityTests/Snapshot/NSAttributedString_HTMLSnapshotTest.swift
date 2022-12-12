//
//  NSAttributedString_HTMLSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase

@testable import StripeIdentity

final class NSAttributedString_HTMLSnapshotTest: FBSnapshotTestCase {
    static let htmlText = """
        <h1>header 1</h1>
        <h2>header 2</h2>
        <h3>header 3</h3>
        <h4>header 4</h4>
        <h5>header 5</h5>
        <h6>header 6</h6>
        <p>
        Lorem ipsum dolor sit amet, <b>consectetur adipiscing elit</b>. Suspendisse
        hendrerit diam id <i>risus accumsan</i>, <em>tempus rutrum</em> nibh varius.
        Aenean id congue nunc. <strong>Sed tellus et ligula luctus aliquam.</strong>
        <u>Nulla facilisis sit amet metus eu lacinia.</u> In et libero quam.
        <a href="https://stripe.com>">Phasellus lobortis eros enim</a>, eu pretium
        purus euismod fringilla. Maecenas eget dictum sapien.
        </p>
        <p>
            <a href="https://stripe.com">Stand alone link</a>
        </p>
        <ul>
          <li>List Item</li>
          <li>List Item</li>
        </ul>
        <ol>
          <li>List Item</li>
          <li>List Item</li>
        </ol>
        """

    let textView = UITextView()

    // Pick a font that supports italic
    let customFont = UIFont(name: "Avenir", size: 13)!

    override func setUp() {
        super.setUp()

        // Disable scrolling or else view is too big to snapshot
        textView.isScrollEnabled = false

        // Test that link color matches tint color
        textView.tintColor = .systemPink

        //        recordMode = true
    }

    func testDefaultStyle() throws {
        try verifyView(
            htmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
            style: .default
        )
    }

    func testCustomStyle() throws {
        try verifyView(
            htmlString: NSAttributedString_HTMLSnapshotTest.htmlText,
            style: .init(
                bodyFont: customFont,
                bodyColor: UIColor.systemPurple,
                h1Color: UIColor.systemYellow,
                h2Color: UIColor.systemOrange,
                h3Color: UIColor.systemRed,
                h4Color: UIColor.systemBlue,
                h5Color: UIColor.systemGreen,
                h6Color: UIColor.cyan,
                isLinkUnderlined: true
            )
        )
    }
}

extension NSAttributedString_HTMLSnapshotTest {
    fileprivate func verifyView(
        htmlString: String,
        style: HTMLStyle,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let attributedText = try NSAttributedString(htmlText: htmlString, style: style)
        textView.attributedText = attributedText
        textView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(textView, file: file, line: line)
    }
}

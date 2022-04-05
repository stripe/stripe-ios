//
//  ButtonLinkSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 2/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeUICore

class ButtonLinkSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testPrimary() {
        let sut = makeSUT(configuration: .linkPrimary(), title: "Primary Button")
        verify(sut)
    }

    func testSecondary() {
        let sut = makeSUT(configuration: .linkSecondary(), title: "Secondary Button")
        verify(sut)
    }

    func testBordered() {
        let sut = makeSUT(configuration: .linkBordered(), title: "Bordered Button")
        verify(sut)
    }

    func testPlain() {
        let sut = makeSUT(configuration: .linkPlain(), title: "Plain Button")
        verify(sut)
    }

    func verify(
        _ sut: Button,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = sut.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        sut.bounds = CGRect(origin: .zero, size: size)
        FBSnapshotVerifyView(sut, file: file, line: line)

        sut.isHighlighted = true
        FBSnapshotVerifyView(sut, identifier: "Highlighted", file: file, line: line)

        sut.isHighlighted = false
        sut.isEnabled = false
        FBSnapshotVerifyView(sut, identifier: "Disabled", file: file, line: line)

        sut.isHighlighted = false
        sut.isEnabled = true
        sut.isLoading = true
        FBSnapshotVerifyView(sut, identifier: "Loading", file: file, line: line)
    }

}

extension ButtonLinkSnapshotTests {

    func makeSUT(
        configuration: Button.Configuration,
        title: String
    ) -> Button {
        return Button(configuration: configuration, title: title)
    }

}

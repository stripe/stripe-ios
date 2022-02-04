//
//  LinkLegalTermsViewSnapshotTests.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase

@testable import Stripe
@_spi(STP) import StripeUICore

class LinkLegalTermsViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testDefault() {
        let sut = LinkLegalTermsView()
        verify(sut)
    }

    func testCentered() {
        let sut = LinkLegalTermsView(textAlignment: .center)
        verify(sut)
    }

    func testColorCustomization() {
        let sut = LinkLegalTermsView()
        sut.textColor = .black
        sut.tintColor = .orange
        verify(sut)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 250)
        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

}

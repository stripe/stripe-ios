//
//  OneTimeCodeTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class OneTimeCodeTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }

    func testEmpty() {
        let field = OneTimeCodeTextField(numberOfDigits: 6)
        verify(field)
    }

    func testFilled() {
        let field = OneTimeCodeTextField(numberOfDigits: 6)
        field.value = "123456"
        verify(field)
    }

    func verify(
        _ view: UIView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        FBSnapshotVerifyView(view, file: file, line: line)
    }
}

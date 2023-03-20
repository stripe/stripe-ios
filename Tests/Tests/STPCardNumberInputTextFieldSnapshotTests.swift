//
//  STPCardNumberInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPCardNumberInputTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmpty() {
        let field = STPCardNumberInputTextField()
        field.sizeToFit()
        field.frame.size.width = 300

        STPSnapshotVerifyView(field)
    }

    func testIncomplete() {
        let field = STPCardNumberInputTextField()
        field.sizeToFit()
        field.frame.size.width = 300
        field.text = "42"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testValid() {
        let field = STPCardNumberInputTextField()
        field.sizeToFit()
        field.frame.size.width = 300
        field.text = "4242424242424242"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testInvalid() {
        let field = STPCardNumberInputTextField()
        field.sizeToFit()
        field.frame.size.width = 300
        field.text = "4242424242424241"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }
}

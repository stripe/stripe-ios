//
//  STPCardCVCInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPCardCVCInputTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmpty() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200

        FBSnapshotVerifyView(field)
    }

    func testIncomplete() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "1"
        field.textDidChange()

        FBSnapshotVerifyView(field)
    }

    func testValid() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "123"
        field.textDidChange()

        FBSnapshotVerifyView(field)
    }

    func testInvalid() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "12345"
        field.textDidChange()

        FBSnapshotVerifyView(field)
    }
}

//
//  STPGenericInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 12/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPGenericInputTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmpty() {
        let field = STPGenericInputTextField(placeholder: "Empty")
        field.sizeToFit()
        field.frame.size.width = 200

        STPSnapshotVerifyView(field)
    }

    func testWithContent() {
        let field = STPGenericInputTextField(placeholder: "Has Content")
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "Hello"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

}

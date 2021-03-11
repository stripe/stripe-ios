//
//  STPiDEALFormViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 2/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

final class STPiDEALFormViewSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmpty() {
        let formView = STPiDEALFormView()
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        FBSnapshotVerifyView(formView)
    }
}

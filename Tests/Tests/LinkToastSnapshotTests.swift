//
//  LinkToastSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase

@testable import Stripe

class LinkToastSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testSuccess() {
        let toast = LinkToast(type: .success, text: "Success message!")
        verify(toast)
    }

    func verify(
        _ toast: LinkToast,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = toast.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        toast.bounds = CGRect(origin: .zero, size: size)
        FBSnapshotVerifyView(toast, identifier: identifier, file: file, line: line)
    }

}

//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSTPViewWithSeparatorSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCaseCore

class STPSTPViewWithSeparatorSnapshotTests: FBSnapshotTestCase {
    //- (void)setUp {
    //    [super setUp];
    //
    //    self.recordMode = YES;
    //}

    func testDefaultAppearance() {
        let view = STPViewWithSeparator(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 44.0))
        view.backgroundColor = UIColor.white
        STPSnapshotVerifyView(view, "STPViewWithSeparator.defaultAppearance")
    }

    func testHiddenTopSeparator() {
        let view = STPViewWithSeparator(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 44.0))
        view.backgroundColor = UIColor.white
        view.topSeparatorHidden = true
        STPSnapshotVerifyView(view, "STPViewWithSeparator.hiddenTopSeparator")
    }
}
//
//  ErrorViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Jaime Park on 2/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@testable import StripeIdentity

class ErrorViewSnapshotTest: FBSnapshotTestCase {
    let errorView = ErrorView()

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testErrorView() {
        verifyView(
            with: .init(
                titleText: "Error",
                bodyText: "Oh no! Something bad happened."
            )
        )
    }

    func testErrorView_Reconfigured() {
        let preConfiguredViewModel: ErrorView.ViewModel = .init(
            titleText: "Wrong Error",
            bodyText: "This error is the pre-configured body. This shouldn't be shown."
        )
        errorView.configure(with: preConfiguredViewModel)

        verifyView(
            with: .init(
                titleText: "Correct Error",
                bodyText: "This error is the post-configured body. This should be shown."
            )
        )
    }
}

extension ErrorViewSnapshotTest {
    fileprivate func verifyView(
        with viewModel: ErrorView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        errorView.configure(with: viewModel)
        errorView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(errorView, file: file, line: line)
    }
}

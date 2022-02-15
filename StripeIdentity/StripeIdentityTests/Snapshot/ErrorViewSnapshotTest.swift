//
//  ErrorViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Jaime Park on 2/10/22.
//

import FBSnapshotTestCase
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@testable import StripeIdentity


class ErrorViewSnapshotTest: FBSnapshotTestCase {
    let errorView = ErrorView()

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testErrorView() {
        verifyView(with: .init(
            titleText: "Error",
            bodyText: "Oh no! Something bad happened.")
        )
    }

    func testErrorView_Reconfigured() {
        let preConfiguredViewModel: ErrorView.ViewModel = .init(
            titleText: "Wrong Error",
            bodyText: "This error is the pre-configured body. This shouldn't be shown.")
        errorView.configure(with: preConfiguredViewModel)

        verifyView(with: .init(
            titleText: "Correct Error",
            bodyText: "This error is the post-configured body. This should be shown.")
        )
    }
}

private extension ErrorViewSnapshotTest {
    func verifyView(
        with viewModel: ErrorView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        errorView.configure(with: viewModel)
        errorView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(errorView, file: file, line: line)
    }
}

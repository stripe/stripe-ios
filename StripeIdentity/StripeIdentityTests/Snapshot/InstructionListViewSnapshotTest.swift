//
//  InstructionListViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
@_spi(STP) import StripeUICore

@testable import StripeIdentity

final class InstructionListViewSnapshotTest: FBSnapshotTestCase {

    let multiLineText =
        "Here's a string that spans multiple lines of text\nAnother line!\nAnother line!"

    let view = InstructionListView()

    override func setUp() {
        super.setUp()
        ActivityIndicator.isAnimationEnabled = false

        //        recordMode = true
    }

    override func tearDown() {
        ActivityIndicator.isAnimationEnabled = true
        super.tearDown()
    }

    func testTextOnly() {
        verifyView(
            with: .init(
                instructionText: multiLineText,
                listViewModel: nil
            )
        )
    }

    func testListOnly() {
        verifyView(
            with: .init(
                instructionText: nil,
                listViewModel: ListViewSnapshotTest.manyItemViewModel
            )
        )
    }

    func testTextAndList() {
        verifyView(
            with: .init(
                instructionText: multiLineText,
                listViewModel: ListViewSnapshotTest.manyItemViewModel
            )
        )
    }
}

extension InstructionListViewSnapshotTest {
    fileprivate func verifyView(
        with viewModel: InstructionListView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

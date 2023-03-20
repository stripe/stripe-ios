//
//  InstructionalDocumentScanningViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/8/22.
//

import Foundation
import FBSnapshotTestCase
@testable import StripeIdentity

final class InstructionalDocumentScanningViewSnapshotTest: FBSnapshotTestCase {
    let view = InstructionalDocumentScanningView()

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testOneLineText() {
        // NOTE: This image should be the same height as `testMaxLinesText`
        verifyView(with: .init(
            scanningViewModel: .blank,
            instructionalText: makeText(withNumberOfLines: 1)
        ))
    }

    func testMaxLinesText() {
        verifyView(with: .init(
            scanningViewModel: .blank,
            instructionalText: makeText(withNumberOfLines: InstructionalDocumentScanningView.Styling.labelMinHeightNumberOfLines)
        ))
    }

    func testExceedMaxLinesText() {
        verifyView(with: .init(
            scanningViewModel: .blank,
            instructionalText: makeText(withNumberOfLines: InstructionalDocumentScanningView.Styling.labelMinHeightNumberOfLines * 2)
        ))
    }
}

private extension InstructionalDocumentScanningViewSnapshotTest {
    func verifyView(
        with viewModel: InstructionalDocumentScanningView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }

    func makeText(withNumberOfLines numberOfLines: Int) -> String {
        return Array(repeating: "A line of text", count: numberOfLines).joined(separator: "\n")
    }
}

//
//  SelfieCaptureViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/5/22.
//

import Foundation

import Foundation
import FBSnapshotTestCase
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCameraCoreTestUtils
@testable import StripeIdentity

final class SelfieCaptureViewSnapshotTest: FBSnapshotTestCase {

    let view = SelfieCaptureView()

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testError() {
        verifyView(with: .error(.init(
            titleText: "Error title",
            bodyText: "Error message"
        )))
    }

    func testBlank() {
        verifyView(with: .scan(.init(
            state: .blank,
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        )))
    }

    func testScannedImages() {
        verifyView(with: .scan(.init(
            state: .scanned(Array(repeating: SelfieScanningViewSnapshotTest.mockImage, count: 3),
                            consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                            consentHandler: {_ in },
                            openURLHandler: {_ in }
                           ),
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        )))
    }
}

private extension SelfieCaptureViewSnapshotTest {
    func verifyView(
        with viewModel: SelfieCaptureView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel, analyticsClient: nil)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

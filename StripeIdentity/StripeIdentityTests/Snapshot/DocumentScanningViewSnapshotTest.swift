//
//  DocumentScanningViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCameraCoreTestUtils

@testable import StripeIdentity

final class DocumentScanningViewSnapshotTest: FBSnapshotTestCase {
    // NOTE(mludowise): Snapshot tests don't seem to respect setting the overlay
    // layer's `compositingFilter` to "multiplyBlendMode". The result is the
    // resulting snapshot images all have a solid-opaque color for the overlay.

    let scanningView = DocumentScanningView()
    let mockImage = CapturedImageMock.frontDriversLicense.image
    let mockCameraSession: MockTestCameraSession = {
        let mockCameraSession = MockTestCameraSession()
        mockCameraSession.mockImage = CapturedImageMock.backDriversLicense.image
        return mockCameraSession
    }()

    override func setUp() {
        super.setUp()

        // Set tint color to test scanned image icon tinting
        scanningView.tintColor = .systemPink

        AnimatedBorderView.isAnimationEnabled = false
        //        recordMode = true
    }

    override func tearDown() {
        AnimatedBorderView.isAnimationEnabled = true
        super.tearDown()
    }

    func testBlank() {
        verifyView(with: .blank)
    }

    func testCameraSession() {
        verifyView(with: .videoPreview(mockCameraSession, animateBorder: false))
    }

    func testCameraSessionAnimated() {
        verifyView(with: .videoPreview(mockCameraSession, animateBorder: true))
    }

    func testScannedImage() {
        verifyView(with: .scanned(mockImage))
    }
}

extension DocumentScanningViewSnapshotTest {
    fileprivate func verifyView(
        with viewModel: DocumentScanningView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        scanningView.configure(with: viewModel)
        scanningView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(scanningView, file: file, line: line)
    }
}

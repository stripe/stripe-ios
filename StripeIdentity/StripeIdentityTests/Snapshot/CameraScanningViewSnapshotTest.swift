//
//  CameraScanningViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/8/22.
//

import Foundation
import FBSnapshotTestCase
@_spi(STP) import StripeCameraCore
@testable import StripeIdentity
@_spi(STP) import StripeCameraCoreTestUtils

final class CameraScanningViewSnapshotTest: FBSnapshotTestCase {
    /*
     NOTE(mludowise): Snapshot tests don't seem to respect setting the overlay
     layer's `compositingFilter` to "multiplyBlendMode". The result is the
     resulting snapshot images all have a solid-opaque color for the overlay.
     */

    let scanningView = CameraScanningView()
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

private extension CameraScanningViewSnapshotTest {
    func verifyView(
        with viewModel: CameraScanningView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        scanningView.configure(with: viewModel)
        scanningView.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        FBSnapshotVerifyView(scanningView, file: file, line: line)
    }
}

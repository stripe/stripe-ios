//
//  SelfieScanningViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 4/26/22.
//

import Foundation
import FBSnapshotTestCase
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCameraCoreTestUtils
@testable import StripeIdentity

final class SelfieScanningViewSnapshotTest: FBSnapshotTestCase {
    static let mockText = "A long line of text that should wrap to multiple lines"
    static let consentText = "Allow Stripe to use your images to improve our biometric verification technology. You can remove Stripe's permissions at any time by contacting Stripe. <a href='https://stripe.com'>Learn how Stripe uses data</a>"
    static let mockImage = CapturedImageMock.frontDriversLicense.image

    let view = SelfieScanningView()
    let mockCameraSession: MockTestCameraSession = {
        let mockCameraSession = MockTestCameraSession()
        mockCameraSession.mockImage = CapturedImageMock.backDriversLicense.image
        return mockCameraSession
    }()

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testBlank() {
        verifyView(with: .init(
            state: .blank,
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        ))
    }

    func testCameraSession() {
        verifyView(with: .init(
            state: .videoPreview(mockCameraSession, showFlashAnimation: false),
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        ))
    }

    func testMultipleScannedImages() {
        verifyView(with: .init(
            state: .scanned(Array(repeating: SelfieScanningViewSnapshotTest.mockImage, count: 3),
                            consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                            consentHandler: {_ in },
                            openURLHandler: {_ in }
                           ),
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        ))
    }

    func testOneScannedImage() {
        verifyView(with: .init(
            state: .scanned([SelfieScanningViewSnapshotTest.mockImage],
                            consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                            consentHandler: {_ in },
                            openURLHandler: {_ in }
                           ),
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        ))
    }

    func testCustomTintColor() {
        // Set custom tint color
        view.tintColor = .systemPink
        // Mock that checkbox is selected
        view.consentCheckboxButton.isSelected = true
        verifyView(with: .init(
            state: .scanned(Array(repeating: SelfieScanningViewSnapshotTest.mockImage, count: 3),
                            consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                            consentHandler: {_ in },
                            openURLHandler: {_ in }
                           ),
            instructionalText: SelfieScanningViewSnapshotTest.mockText
        ))
    }
}

private extension SelfieScanningViewSnapshotTest {
    func verifyView(
        with viewModel: SelfieScanningView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel, analyticsClient: nil)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

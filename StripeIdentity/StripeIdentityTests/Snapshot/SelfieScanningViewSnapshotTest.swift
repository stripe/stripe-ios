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
    let mockText = "A long line of text that should wrap to multiple lines"
    let consentText = "Allow Stripe to use your images to improve our biometric verification technology. You can remove Stripe's permissions at any time by contacting Stripe. <a href='https://stripe.com'>Learn how Stripe uses data</a>"

    let view = SelfieScanningView()
    let mockImage = CapturedImageMock.frontDriversLicense.image
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
            instructionalText: mockText
        ))
    }

    func testCameraSession() {
        verifyView(with: .init(
            state: .videoPreview(mockCameraSession),
            instructionalText: mockText
        ))
    }

    func testMultipleScannedImages() {
        verifyView(with: .init(
            state: .scanned(Array(repeating: mockImage, count: 3),
                            consentHTMLText: consentText,
                            consentHandler: {_ in },
                            openURLHandler: {_ in }
                           ),
            instructionalText: mockText
        ))
    }

    func testOneScannedImage() {
        verifyView(with: .init(
            state: .scanned([mockImage],
                            consentHTMLText: consentText,
                            consentHandler: {_ in },
                            openURLHandler: {_ in }
                           ),
            instructionalText: mockText
        ))
    }
}

private extension SelfieScanningViewSnapshotTest {
    func verifyView(
        with viewModel: SelfieScanningView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

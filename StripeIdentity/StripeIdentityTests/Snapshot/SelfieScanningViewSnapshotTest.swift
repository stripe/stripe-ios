//
//  SelfieScanningViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 4/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCameraCoreTestUtils
@_spi(STP) import StripeUICore
import UIKit

import StripeCoreTestUtils
@testable import StripeIdentity

final class SelfieScanningViewSnapshotTest: STPSnapshotTestCase {
    static let mockText = "A long line of text that should wrap to multiple lines"
    static let consentText =
        "Allow Stripe to use your images to improve our biometric verification technology. You can remove Stripe's permissions at any time by contacting Stripe. <a href='https://stripe.com'>Learn how Stripe uses data</a>"
    static let mockImage = CapturedImageMock.frontDriversLicense.image

    let view = SelfieScanningView()
    let mockCameraSession: MockTestCameraSession = {
        let mockCameraSession = MockTestCameraSession()
        mockCameraSession.mockImage = CapturedImageMock.backDriversLicense.image
        return mockCameraSession
    }()
    let mockSelfieCameraSession: MockTestCameraSession = {
        let mockCameraSession = MockTestCameraSession()
        mockCameraSession.mockImage = SelfieScanningViewSnapshotTest.mockSelfieImage
        return mockCameraSession
    }()

    override func setUp() {
        super.setUp()
        ActivityIndicator.isAnimationEnabled = false
    }

    override func tearDown() {
        ActivityIndicator.isAnimationEnabled = true
        super.tearDown()
    }

    func testBlank() {
        verifyView(
            with: .init(
                state: .blank,
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }

    func testCameraSession() {
        verifyView(
            with: .init(
                state: .videoPreview(
                    mockCameraSession,
                    showFlashAnimation: false,
                    statusText: nil,
                    captureGuideHighlight: .none
                ),
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }

    func testCameraSessionHoldStill() {
        verifyView(
            with: .init(
                state: .videoPreview(
                    mockSelfieCameraSession,
                    showFlashAnimation: false,
                    statusText: .holdStill,
                    captureGuideHighlight: .front
                ),
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }

    func testMultipleScannedImages() {
        verifyView(
            with: .init(
                state: .scanned(
                    Array(repeating: SelfieScanningViewSnapshotTest.mockImage, count: 3),
                    consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                    consentHandler: { _ in },
                    openURLHandler: { _ in },
                    retakeSelfieHandler: {}
                ),
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }

    func testOneScannedImage() {
        verifyView(
            with: .init(
                state: .scanned(
                    [SelfieScanningViewSnapshotTest.mockImage],
                    consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                    consentHandler: { _ in },
                    openURLHandler: { _ in },
                    retakeSelfieHandler: {}
                ),
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }

    func testSaving() {
        verifyView(
            with: .init(
                state: .saving(
                    SelfieScanningViewSnapshotTest.mockImage,
                    statusText: .uploading
                ),
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }

    func testCustomTintColor() {
        // Set custom tint color
        view.tintColor = .systemPink
        // Mock that checkbox is selected
        view.consentCheckboxButton.isSelected = true
        verifyView(
            with: .init(
                state: .scanned(
                    Array(repeating: SelfieScanningViewSnapshotTest.mockImage, count: 3),
                    consentHTMLText: SelfieScanningViewSnapshotTest.consentText,
                    consentHandler: { _ in },
                    openURLHandler: { _ in },
                    retakeSelfieHandler: {}
                ),
                instructionalText: SelfieScanningViewSnapshotTest.mockText
            )
        )
    }
}

extension SelfieScanningViewSnapshotTest {
    static let mockSelfieImage: UIImage = {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            UIColor(red: 0.78, green: 0.80, blue: 0.76, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor(red: 0.67, green: 0.62, blue: 0.56, alpha: 1).setFill()
            context.fill(CGRect(x: 168, y: 0, width: 132, height: 400))

            UIColor(red: 0.83, green: 0.86, blue: 0.88, alpha: 1).setFill()
            UIBezierPath(
                roundedRect: CGRect(x: 48, y: 310, width: 204, height: 112),
                cornerRadius: 64
            ).fill()

            UIColor(red: 0.68, green: 0.50, blue: 0.42, alpha: 1).setFill()
            UIBezierPath(
                roundedRect: CGRect(x: 128, y: 242, width: 44, height: 86),
                cornerRadius: 18
            ).fill()

            UIColor(red: 0.75, green: 0.56, blue: 0.47, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 82, y: 130, width: 26, height: 52)).fill()
            UIBezierPath(ovalIn: CGRect(x: 192, y: 130, width: 26, height: 52)).fill()

            UIColor(red: 0.78, green: 0.58, blue: 0.49, alpha: 1).setFill()
            UIBezierPath(
                roundedRect: CGRect(x: 90, y: 84, width: 120, height: 180),
                cornerRadius: 58
            ).fill()

            UIColor(red: 0.05, green: 0.06, blue: 0.07, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 82, y: 58, width: 136, height: 88)).fill()
            context.fill(CGRect(x: 90, y: 116, width: 120, height: 34))

            UIColor(red: 0.06, green: 0.07, blue: 0.08, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 116, y: 166, width: 10, height: 8)).fill()
            UIBezierPath(ovalIn: CGRect(x: 174, y: 166, width: 10, height: 8)).fill()

            UIColor(red: 0.62, green: 0.43, blue: 0.38, alpha: 1).setStroke()
            let nosePath = UIBezierPath()
            nosePath.lineWidth = 2
            nosePath.move(to: CGPoint(x: 150, y: 178))
            nosePath.addLine(to: CGPoint(x: 144, y: 212))
            nosePath.addLine(to: CGPoint(x: 155, y: 212))
            nosePath.stroke()

            UIColor(red: 0.35, green: 0.18, blue: 0.17, alpha: 1).setStroke()
            let mouthPath = UIBezierPath()
            mouthPath.lineWidth = 2
            mouthPath.move(to: CGPoint(x: 132, y: 232))
            mouthPath.addLine(to: CGPoint(x: 168, y: 232))
            mouthPath.stroke()
        }
    }()

    fileprivate func verifyView(
        with viewModel: SelfieScanningView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel, sheetController: nil)
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}

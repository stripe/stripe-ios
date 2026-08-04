//
//  SelfieUploaderTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCoreTestUtils
import XCTest

// swift-format-ignore
@testable @_spi(STP) import StripeCore

@testable import StripeIdentity

final class SelfieUploaderTest: XCTestCase {
    var mockAPIClient: IdentityAPIClientTestMock!
    var uploader: SelfieUploader!

    override func setUp() {
        super.setUp()
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: "VS_123",
            ephemeralKeySecret: "EAK_123"
        )
        uploader = SelfieUploader(
            imageUploader: IdentityImageUploader(
                configuration: IdentityImageUploaderTest.mockConfig,
                sheetController: VerificationSheetControllerMock(
                    apiClient: mockAPIClient,
                    analyticsClient: .init(verificationSessionId: "")
                )
            ),
            isTestMode: true
        )
    }

    func testUploadImagesInTestModeUsesPlaceholderImage() {
        // Given a captured selfie
        let capturedImage = FaceScannerInputOutput(
            image: CapturedImageMock.frontDriversLicense.image.cgImage!,
            scannerOutput: FaceScannerOutput(
                faceDetectorOutput: .init(
                    predictions: [
                        .init(
                            rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
                            score: 1
                        ),
                    ]
                ),
                cameraProperties: nil,
                motionBlurResult: nil,
                isValid: true
            ),
            cameraExifMetadata: nil
        )
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)

        // When the image is uploaded in test mode
        uploader.uploadImages(capturedImage, ofType: .best).observe { _ in }
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then both requests use the bundled selfie placeholder
        let placeholderSize = UIImage(cgImage: try! TestModeImage.selfie.makeCGImage()).size
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 2)
        XCTAssertTrue(
            mockAPIClient.imageUpload.requestHistory.allSatisfy {
                $0.image.size == placeholderSize
            }
        )
        XCTAssertNotEqual(placeholderSize, UIImage(cgImage: capturedImage.image).size)
    }
}

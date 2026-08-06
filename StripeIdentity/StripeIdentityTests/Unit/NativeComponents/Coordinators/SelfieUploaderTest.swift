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
        uploader = makeUploader(isTestMode: true)
    }

    func testUploadImagesInTestModeUsesPlaceholderImage() {
        // Given a captured selfie
        let capturedImage = makeCapturedImage()
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

    func testUploadImagesInLiveModeUsesCapturedImage() {
        // Given a live mode uploader and captured selfie
        uploader = makeUploader(isTestMode: false)
        let capturedImage = makeCapturedImage()
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)

        // When the image is uploaded
        uploader.uploadImages(capturedImage, ofType: .best).observe { _ in }
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then the upload requests use the captured image instead of the placeholder
        let requestsByFileName = Dictionary(
            uniqueKeysWithValues: mockAPIClient.imageUpload.requestHistory.map {
                ($0.fileName, $0)
            }
        )
        let highResRequest = requestsByFileName["VS_123_face"]
        let lowResRequest = requestsByFileName["VS_123_face_full_frame"]
        let placeholder = try! TestModeImage.selfie.makeCGImage()

        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 2)
        XCTAssertEqual(
            lowResRequest?.image.pngData(),
            resizedPNGData(
                for: capturedImage.image,
                maxDimension: IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension
            )
        )
        XCTAssertNotEqual(
            highResRequest?.image.pngData(),
            resizedPNGData(
                for: placeholder,
                maxDimension: IdentityImageUploaderTest.mockConfig.highResImageMaxDimension
            )
        )
        XCTAssertNotEqual(
            lowResRequest?.image.pngData(),
            resizedPNGData(
                for: placeholder,
                maxDimension: IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension
            )
        )
    }
}

private extension SelfieUploaderTest {
    func makeUploader(isTestMode: Bool) -> SelfieUploader {
        return SelfieUploader(
            imageUploader: IdentityImageUploader(
                configuration: IdentityImageUploaderTest.mockConfig,
                sheetController: VerificationSheetControllerMock(
                    apiClient: mockAPIClient,
                    analyticsClient: .init(verificationSessionId: "")
                )
            ),
            isTestMode: isTestMode
        )
    }

    func makeCapturedImage() -> FaceScannerInputOutput {
        return FaceScannerInputOutput(
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
    }

    func resizedPNGData(for image: CGImage, maxDimension: Int) -> Data {
        let resizedImage = try! image.scaledDown(
            toMaxPixelDimension: CGSize(width: maxDimension, height: maxDimension)
        )
        return UIImage(cgImage: resizedImage).pngData()!
    }
}

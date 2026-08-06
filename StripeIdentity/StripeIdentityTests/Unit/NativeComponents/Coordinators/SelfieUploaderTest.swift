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
    private var mockAPIClient: IdentityAPIClientTestMock!
    private var uploader: SelfieUploader!

    override func setUp() {
        super.setUp()
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: "VS_123",
            ephemeralKeySecret: "EAK_123"
        )
        uploader = makeUploader(isTestMode: true)
    }

    func testUploadImagesInTestModeUsesPlaceholderImage() throws {
        // Given a captured selfie
        let capturedImage = try makeCapturedImage()
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)

        // When the image is uploaded in test mode
        _ = uploader.uploadImages(capturedImage, ofType: .best)
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then both requests use the bundled selfie placeholder
        let placeholder = try TestModeImage.selfie.makeCGImage()
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 2)
        XCTAssertEqual(
            uploadRequest(named: "VS_123_face")?.image.pngData(),
            try resizedPNGData(
                for: placeholder,
                maxDimension: IdentityImageUploaderTest.mockConfig.highResImageMaxDimension
            )
        )
        XCTAssertEqual(
            uploadRequest(named: "VS_123_face_full_frame")?.image.pngData(),
            try resizedPNGData(
                for: placeholder,
                maxDimension: IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension
            )
        )
    }

    func testUploadImagesInLiveModeUsesCapturedImage() throws {
        // Given a live mode uploader and captured selfie
        uploader = makeUploader(isTestMode: false)
        let capturedImage = try makeCapturedImage()
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)

        // When the image is uploaded
        _ = uploader.uploadImages(capturedImage, ofType: .best)
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then the upload requests use the captured image instead of the placeholder
        let highResRequest = uploadRequest(named: "VS_123_face")
        let lowResRequest = uploadRequest(named: "VS_123_face_full_frame")
        let placeholder = try TestModeImage.selfie.makeCGImage()

        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 2)
        XCTAssertEqual(
            lowResRequest?.image.pngData(),
            try resizedPNGData(
                for: capturedImage.image,
                maxDimension: IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension
            )
        )
        XCTAssertNotEqual(
            highResRequest?.image.pngData(),
            try resizedPNGData(
                for: placeholder,
                maxDimension: IdentityImageUploaderTest.mockConfig.highResImageMaxDimension
            )
        )
        XCTAssertNotEqual(
            lowResRequest?.image.pngData(),
            try resizedPNGData(
                for: placeholder,
                maxDimension: IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension
            )
        )
    }
}

private extension SelfieUploaderTest {
    func uploadRequest(
        named fileName: String
    ) -> IdentityAPIClientTestMock.ImageUploadRequestParams? {
        return mockAPIClient.imageUpload.requestHistory.first { $0.fileName == fileName }
    }

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

    func makeCapturedImage() throws -> FaceScannerInputOutput {
        return FaceScannerInputOutput(
            image: try XCTUnwrap(CapturedImageMock.frontDriversLicense.image.cgImage),
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

    func resizedPNGData(for image: CGImage, maxDimension: Int) throws -> Data {
        let resizedImage = try image.scaledDown(
            toMaxPixelDimension: CGSize(width: maxDimension, height: maxDimension)
        )
        return try XCTUnwrap(UIImage(cgImage: resizedImage).pngData())
    }
}

//
//  SelfieUploaderTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import XCTest

// swift-format-ignore
@testable @_spi(InternalOnlyAPI) import StripeCore

@testable import StripeIdentity

final class SelfieUploaderTest: XCTestCase {
    private var mockAPIClient: IdentityAPIClientTestMock!
    private var uploader: SelfieUploader!
    private let mockUploadMetrics = STPAPIClient.ImageUploadMetrics(timeToUpload: 0, fileSizeBytes: 0)

    override func setUp() {
        super.setUp()
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: "VS_123",
            ephemeralKeySecret: "EAK_123"
        )
        uploader = makeUploader(isTestMode: true)
    }

    func testUploadImagesInTestModeUsesPlaceholderImage() async throws {
        // Given a captured selfie
        let capturedImages = try makeFaceCaptureData()
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 6)

        // When the images are uploaded in test mode
        uploader.uploadImages(capturedImages)
        await fulfillment(of: uploadRequestExpectations, timeout: 1)

        // Then the requests use the bundled selfie placeholder
        let placeholder = try TestModeImage.selfie.makeCGImage()
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 6)
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

    func testUploadImagesInLiveModeUsesCapturedImage() async throws {
        // Given a live mode uploader and captured selfie
        uploader = makeUploader(isTestMode: false)
        let capturedImages = try makeFaceCaptureData()
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 6)

        // When the images are uploaded
        uploader.uploadImages(capturedImages)
        await fulfillment(of: uploadRequestExpectations, timeout: 1)

        // Then the upload requests use the captured image instead of the placeholder
        let highResRequest = uploadRequest(named: "VS_123_face")
        let lowResRequest = uploadRequest(named: "VS_123_face_full_frame")
        let placeholder = try TestModeImage.selfie.makeCGImage()

        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 6)
        XCTAssertEqual(
            lowResRequest?.image.pngData(),
            try resizedPNGData(
                for: capturedImages.bestMiddle.image,
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

    func testRetryFailedUploadsUploadsOnlyFailedFile() async throws {
        // Given a selfie upload where one file failed and the others succeeded
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let failedFileName = "VS_123_face_first_crop_frame"
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 7)
        uploader.uploadImages(try makeFaceCaptureData())
        await fulfillment(of: Array(uploadRequestExpectations.prefix(6)), timeout: 1)
        mockAPIClient.imageUpload.respondToRequests { request in
            guard request.fileName != failedFileName,
                let file = try? StripeFile.mock(id: request.fileName)
            else {
                return .failure(mockError)
            }
            return .success((file: file, metrics: mockUploadMetrics))
        }
        let failedResult = await uploader.uploadResult()
        XCTAssertThrowsError(try XCTUnwrap(failedResult).get())

        // When the failed uploads are retried
        await uploader.retryFailedUploads()
        await fulfillment(of: [uploadRequestExpectations[6]], timeout: 1)
        let retriedFile = try StripeFile.mock(id: "retried")
        mockAPIClient.imageUpload.respondToRequests(
            with: .success((file: retriedFile, metrics: mockUploadMetrics))
        )

        // Then only the failed file is uploaded again, and the other files are kept
        let result = await uploader.uploadResult()
        let fileData = try XCTUnwrap(result).get()
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.last?.fileName, failedFileName)
        XCTAssertEqual(fileData.firstHighResFile.id, "retried")
        XCTAssertEqual(fileData.bestHighResFile.id, "VS_123_face")
        XCTAssertEqual(fileData.firstLowResFile.id, "VS_123_face_first_full_frame")
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

    func makeFaceCaptureData() throws -> FaceCaptureData {
        let image = try XCTUnwrap(CapturedImageMock.frontDriversLicense.image.cgImage)
        let samples = [0.7, 0.8, 0.9].map { score in
            FaceScannerInputOutput(
                image: image,
                scannerOutput: FaceScannerOutput(
                    faceDetectorOutput: .init(
                        predictions: [
                            .init(
                                rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
                                score: score
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
        return try XCTUnwrap(FaceCaptureData(samples: samples))
    }

    func resizedPNGData(for image: CGImage, maxDimension: Int) throws -> Data {
        let resizedImage = try image.scaledDown(
            toMaxPixelDimension: CGSize(width: maxDimension, height: maxDimension)
        )
        return try XCTUnwrap(UIImage(cgImage: resizedImage).pngData())
    }
}

//
//  DocumentUploaderTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 1/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreMedia
@_spi(STP) import StripeCoreTestUtils
import XCTest

// swift-format-ignore
@testable @_spi(STP) import StripeCameraCore

// swift-format-ignore
@testable @_spi(STP) import StripeCore

@testable import StripeIdentity

final class DocumentUploaderTest: XCTestCase {

    var uploader: DocumentUploader!
    private var mockDelegate: MockDocumentUploaderDelegate!
    var mockAPIClient: IdentityAPIClientTestMock!
    static var mockStripeFile: StripeFile!
    static var mockUploadMetrics = STPAPIClient.ImageUploadMetrics(
        timeToUpload: 0,
        fileSizeBytes: 0
    )

    let mockVS = "VS_123"
    let mockEAK = "EAK_123"
    let mockConfig = IdentityImageUploaderTest.mockConfig
    let mockExifData = CameraExifMetadata(exifDictionary: [
        kCGImagePropertyExifBrightnessValue: Double(0.5),
        kCGImagePropertyExifLensModel: "mock_model",
        kCGImagePropertyExifFocalLength: Double(33),
    ])
    let mockImage = CapturedImageMock.frontDriversLicense.image.cgImage!

    // This is the bounds of the document in the mock photo in image-coordinates
    // This must be a landscape region for the test to work
    static let mockRegionOfInterest = CGRect(
        x: 0.03042328042,
        y: 0.3115079365,
        width: 0.8908730159,
        height: 0.4164186508
    )

    static let mockDocumentScannerOutputLegacy = DocumentScannerOutput.legacy(
        .init(
            classification: .idCardFront,
            documentBounds: mockRegionOfInterest,
            allClassificationScores: [
                .idCardFront: 0.9,
                .idCardBack: 0.8,
                .passport: 0.7,
                .invalid: 0.6,
            ]
        ),
        .init(
            hasBarcode: true,
            isTimedOut: false,
            symbology: .pdf417,
            timeTryingToFindBarcode: 1
        ),
        .init(
            hasMotionBlur: false,
            iou: nil,
            frameCount: 0,
            duration: 0
        ),
        .init(
            .init(
                exposureDuration: CMTime(value: 250, timescale: 1000),
                cameraDeviceType: .builtInDualCamera,
                isVirtualDevice: true,
                lensPosition: 0.3,
                exposureISO: 0.4,
                isAdjustingFocus: false
            )
        ),
        .init(isBlurry: false, variance: 0.1)
    )

    // swiftlint:disable:next static_over_final_class
    override class func setUp() {
        super.setUp()
        mockStripeFile = try! FileMock.identityDocument.make()
    }

    override func setUp() {
        super.setUp()
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: mockVS,
            ephemeralKeySecret: mockEAK
        )
        uploader = makeUploader()
        mockDelegate = MockDocumentUploaderDelegate()
        uploader.delegate = mockDelegate
    }

    func testUploadImagesInTestModeUsesPlaceholderImages() throws {
        // Given a test mode uploader
        uploader = makeUploader(isTestMode: true)
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 4)

        // When real front and back document images are provided
        for side in [DocumentSide.front, .back] {
            uploader.uploadImages(
                for: side,
                originalImage: mockImage,
                documentScannerOutput: DocumentUploaderTest.mockDocumentScannerOutputLegacy,
                exifMetadata: mockExifData,
                method: .autoCapture
            )
        }
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then every request uses the correct bundled placeholder without cropping
        let frontPlaceholder = try TestModeImage.documentFront.makeCGImage()
        let backPlaceholder = try TestModeImage.documentBack.makeCGImage()
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 4)
        XCTAssertEqual(
            uploadRequest(named: "\(mockVS)_front")?.image.pngData(),
            try resizedPNGData(
                for: frontPlaceholder,
                maxDimension: mockConfig.highResImageMaxDimension
            )
        )
        XCTAssertEqual(
            uploadRequest(named: "\(mockVS)_front_full_frame")?.image.pngData(),
            try resizedPNGData(
                for: frontPlaceholder,
                maxDimension: mockConfig.lowResImageMaxDimension
            )
        )
        XCTAssertEqual(
            uploadRequest(named: "\(mockVS)_back")?.image.pngData(),
            try resizedPNGData(
                for: backPlaceholder,
                maxDimension: mockConfig.highResImageMaxDimension
            )
        )
        XCTAssertEqual(
            uploadRequest(named: "\(mockVS)_back_full_frame")?.image.pngData(),
            try resizedPNGData(
                for: backPlaceholder,
                maxDimension: mockConfig.lowResImageMaxDimension
            )
        )

        mockAPIClient.imageUpload.respondToRequests(
            with: .success(
                (
                    file: DocumentUploaderTest.mockStripeFile,
                    metrics: DocumentUploaderTest.mockUploadMetrics
                )
            )
        )
    }

    func testUploadImagesInTestModeWithoutROIUsesPlaceholderImage() throws {
        // Given a test mode uploader and no document scanner output
        uploader = makeUploader(isTestMode: true)
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)

        // When a real front document image is provided
        uploader.uploadImages(
            for: .front,
            originalImage: mockImage,
            documentScannerOutput: nil,
            exifMetadata: nil,
            method: .fileUpload
        )
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then only the bundled front placeholder is uploaded at high resolution
        let frontPlaceholder = try TestModeImage.documentFront.makeCGImage()
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.first?.fileName, "\(mockVS)_front")
        XCTAssertEqual(
            mockAPIClient.imageUpload.requestHistory.first?.image.pngData(),
            try resizedPNGData(
                for: frontPlaceholder,
                maxDimension: mockConfig.highResImageMaxDimension
            )
        )

        mockAPIClient.imageUpload.respondToRequests(
            with: .success(
                (
                    file: DocumentUploaderTest.mockStripeFile,
                    metrics: DocumentUploaderTest.mockUploadMetrics
                )
            )
        )
    }

    // Tests the happy path where both images are uploaded successfully
    func testUploadImagesWithROISuccess() {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)
        let uploadResponseExp = expectation(description: "Upload completed")
        let method = StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod.autoCapture
        let prefix = "img-prefix"

        // Upload images
        uploader.uploadImages(
            mockImage,
            documentScannerOutput: DocumentUploaderTest.mockDocumentScannerOutputLegacy,
            exifMetadata: mockExifData,
            method: method,
            fileNamePrefix: prefix
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with \(error)")
            case .success(let data):
                DocumentUploaderTest.verifyFileData(
                    data,
                    expectedHighResImage: DocumentUploaderTest.mockStripeFile.id,
                    expectedLowResImage: DocumentUploaderTest.mockStripeFile.id,
                    expectedUploadMethod: method
                )
            }
            uploadResponseExp.fulfill()
        }

        // Verify a request is made for each of the high & low res uploads
        wait(for: uploadRequestExpectations, timeout: 1)

        // Sort requests by fileName since order of requests isn't determinate
        let uploadRequests = mockAPIClient.imageUpload.requestHistory.sorted(by: {
            $0.fileName < $1.fileName
        })
        let highResRequest = uploadRequests[0]
        let lowResRequest = uploadRequests[1]

        XCTAssertEqual(uploadRequests.count, 2)

        XCTAssertEqual(highResRequest.fileName, prefix)
        XCTAssertEqual(lowResRequest.fileName, "\(prefix)_full_frame")

        // Verify high res image was cropped & low res wasn't based on which is
        // in portrait mode
        XCTAssertLessThan(
            highResRequest.image.size.height,
            CGFloat(mockConfig.highResImageMaxDimension)
        )
        XCTAssertEqual(
            highResRequest.image.size.width,
            CGFloat(mockConfig.highResImageMaxDimension)
        )
        XCTAssertEqual(lowResRequest.image.size.height, CGFloat(mockConfig.lowResImageMaxDimension))
        XCTAssertLessThan(
            lowResRequest.image.size.width,
            CGFloat(mockConfig.lowResImageMaxDimension)
        )

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(
            with: .success(
                (
                    file: DocumentUploaderTest.mockStripeFile,
                    metrics: DocumentUploaderTest.mockUploadMetrics
                )
            )
        )
        wait(for: [uploadResponseExp], timeout: 1)
    }

    // Tests the happy path where one uncropped image is uploaded successfully
    // because there is no ROI
    func testUploadImagesNoROISuccess() {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)

        // Upload images

        let uploadResponseExp = expectation(description: "Upload completed")
        let method = StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod.fileUpload
        let prefix = "img-prefix"

        uploader.uploadImages(
            mockImage,
            documentScannerOutput: nil,
            exifMetadata: nil,
            method: method,
            fileNamePrefix: prefix
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with \(error)")
            case .success(let data):
                XCTAssertEqual(data.highResImage, DocumentUploaderTest.mockStripeFile.id)
                XCTAssertNil(data.lowResImage)
                XCTAssertEqual(data.uploadMethod, method)
            }
            uploadResponseExp.fulfill()
        }

        // Verify a request is made for the high res upload
        wait(for: uploadRequestExpectations, timeout: 1)
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        XCTAssertEqual(uploadRequest.fileName, prefix)
        XCTAssertEqual(
            uploadRequest.image.size.height,
            CGFloat(mockConfig.highResImageMaxDimension)
        )
        XCTAssertLessThan(
            uploadRequest.image.size.width,
            CGFloat(mockConfig.highResImageMaxDimension)
        )

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(
            with: .success(
                (
                    file: DocumentUploaderTest.mockStripeFile,
                    metrics: DocumentUploaderTest.mockUploadMetrics
                )
            )
        )
        wait(for: [uploadResponseExp], timeout: 1)
    }

    // Tests when the image upload errors
    func testUploadImagesError() {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 1)
        let uploadResponseExp = expectation(description: "Upload completed")
        let method = StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod.fileUpload
        let prefix = "img-prefix"

        uploader.uploadImages(
            mockImage,
            documentScannerOutput: nil,
            exifMetadata: mockExifData,
            method: method,
            fileNamePrefix: prefix
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTAssert((error as NSError) === mockError)
            case .success:
                XCTFail("Expected an error")
            }
            uploadResponseExp.fulfill()
        }

        // Verify a request is made for the high res upload
        wait(for: uploadRequestExpectations, timeout: 1)

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(with: .failure(mockError))
        wait(for: [uploadResponseExp], timeout: 1)
    }

    // Test that both images for the front side of the doc are uploaded
    func testUploadImagesForFrontSide() {
        verifyUploadSide(
            .front,
            getThisSideUploadFuture: { uploader.frontUploadFuture },
            getOtherSideUploadFuture: { uploader.backUploadFuture },
            getThisSideUploadStatus: { uploader.frontUploadStatus }
        )
    }

    // Test that both images for the back side of the doc are uploaded
    func testUploadImagesForBackSide() {
        verifyUploadSide(
            .back,
            getThisSideUploadFuture: { uploader.backUploadFuture },
            getOtherSideUploadFuture: { uploader.frontUploadFuture },
            getThisSideUploadStatus: { uploader.backUploadStatus }
        )
    }

    // Start to upload some images and reset them before they've completed upload
    func testResetFromInProgress() {
        let uploadRequestExpectations = uploadMockFrontAndBack()

        // Upload state should be "in progress"
        XCTAssertEqual(uploader.frontUploadStatus, .inProgress)
        XCTAssertEqual(uploader.backUploadStatus, .inProgress)

        // Reset
        uploader.reset()

        // Verify status is reset
        XCTAssertEqual(uploader.frontUploadStatus, .notStarted)
        XCTAssertEqual(uploader.backUploadStatus, .notStarted)
        XCTAssertNil(uploader.frontUploadFuture)
        XCTAssertNil(uploader.backUploadFuture)

        // Ensure status doesn't update when uploads complete
        wait(for: uploadRequestExpectations, timeout: 1)

        XCTAssertEqual(uploader.frontUploadStatus, .notStarted)
        XCTAssertEqual(uploader.backUploadStatus, .notStarted)
        XCTAssertNil(uploader.frontUploadFuture)
        XCTAssertNil(uploader.backUploadFuture)
    }

    func testResetFromComplete() {
        let uploadRequestExpectations = uploadMockFrontAndBack()

        // Wait for uploads to complete
        wait(for: uploadRequestExpectations, timeout: 1)

        // Reset
        uploader.reset()

        // Verify status is reset
        XCTAssertEqual(uploader.frontUploadStatus, .notStarted)
        XCTAssertEqual(uploader.backUploadStatus, .notStarted)
        XCTAssertNil(uploader.frontUploadFuture)
        XCTAssertNil(uploader.backUploadFuture)
    }
}

private extension DocumentUploaderTest {
    func uploadRequest(
        named fileName: String
    ) -> IdentityAPIClientTestMock.ImageUploadRequestParams? {
        return mockAPIClient.imageUpload.requestHistory.first { $0.fileName == fileName }
    }

    func makeUploader(isTestMode: Bool = false) -> DocumentUploader {
        return DocumentUploader(
            imageUploader: IdentityImageUploader(
                configuration: mockConfig,
                sheetController: VerificationSheetControllerMock(
                    apiClient: mockAPIClient,
                    analyticsClient: .init(verificationSessionId: "")
                )
            ),
            isTestMode: isTestMode
        )
    }

    func resizedPNGData(for image: CGImage, maxDimension: Int) throws -> Data {
        let resizedImage = try image.scaledDown(
            toMaxPixelDimension: CGSize(width: maxDimension, height: maxDimension)
        )
        return try XCTUnwrap(UIImage(cgImage: resizedImage).pngData())
    }

    func uploadMockFrontAndBack() -> [XCTestExpectation] {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 4)

        uploader.uploadImages(
            for: .front,
            originalImage: mockImage,
            documentScannerOutput: DocumentUploaderTest.mockDocumentScannerOutputLegacy,
            exifMetadata: mockExifData,
            method: .autoCapture
        )
        uploader.uploadImages(
            for: .back,
            originalImage: mockImage,
            documentScannerOutput: DocumentUploaderTest.mockDocumentScannerOutputLegacy,
            exifMetadata: mockExifData,
            method: .autoCapture
        )

        return uploadRequestExpectations
    }

    static func verifyFileData(
        _ data: StripeAPI.VerificationPageDataDocumentFileData,
        expectedHighResImage: String,
        expectedLowResImage: String?,
        expectedUploadMethod: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(data.backScore?.value, 0.8, "backScore", file: file, line: line)
        XCTAssertEqual(data.brightnessValue?.value, 0.5, "brightnessValue", file: file, line: line)
        XCTAssertEqual(
            data.cameraLensModel,
            "mock_model",
            "cameraLensModel",
            file: file,
            line: line
        )
        XCTAssertEqual(data.exposureDuration, 250, "exposureDuration", file: file, line: line)
        XCTAssertEqual(data.exposureIso?.value, 0.4, "exposureIso", file: file, line: line)
        XCTAssertEqual(data.focalLength?.value, 33, "focalLength", file: file, line: line)
        XCTAssertEqual(data.frontCardScore?.value, 0.9, "frontCardScore", file: file, line: line)
        XCTAssertEqual(
            data.highResImage,
            expectedHighResImage,
            "highResImage",
            file: file,
            line: line
        )
        XCTAssertEqual(data.invalidScore?.value, 0.6, "invalidScore", file: file, line: line)
        XCTAssertEqual(data.iosBarcodeDecoded, true, "iosBarcodeDecoded", file: file, line: line)
        XCTAssertEqual(
            data.iosBarcodeSymbology,
            "pdf417",
            "iosBarcodeSymbology",
            file: file,
            line: line
        )
        XCTAssertEqual(
            data.iosTimeToFindBarcode,
            1000,
            "iosTimeToFindBarcode",
            file: file,
            line: line
        )
        XCTAssertEqual(data.isVirtualCamera, true, "isVirtualCamera", file: file, line: line)
        XCTAssertEqual(data.lowResImage, expectedLowResImage, "lowResImage", file: file, line: line)
        XCTAssertEqual(data.passportScore?.value, 0.7, "passportScore", file: file, line: line)
        XCTAssertEqual(
            data.uploadMethod,
            expectedUploadMethod,
            "uploadMethod",
            file: file,
            line: line
        )
    }

    func verifyUploadSide(
        _ side: DocumentSide,
        getThisSideUploadFuture: () -> Future<StripeAPI.VerificationPageDataDocumentFileData>?,
        getOtherSideUploadFuture: () -> Future<StripeAPI.VerificationPageDataDocumentFileData>?,
        getThisSideUploadStatus: () -> DocumentUploader.UploadStatus
    ) {
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)
        let uploadResponseExp = expectation(description: "Upload completed")
        var delegateCallCount = 0

        mockDelegate.callback = {
            delegateCallCount += 1
        }

        XCTAssertEqual(getThisSideUploadStatus(), .notStarted)
        XCTAssertEqual(delegateCallCount, 0)

        // Upload images
        uploader.uploadImages(
            for: side,
            originalImage: mockImage,
            documentScannerOutput: DocumentUploaderTest.mockDocumentScannerOutputLegacy,
            exifMetadata: mockExifData,
            method: .autoCapture
        )

        XCTAssertEqual(getThisSideUploadStatus(), .inProgress)
        XCTAssertEqual(delegateCallCount, 1)

        // Verify a request is made for each of the high & low res uploads
        wait(for: uploadRequestExpectations, timeout: 1)

        XCTAssertEqual(getThisSideUploadStatus(), .inProgress)
        XCTAssertEqual(delegateCallCount, 1)

        // Sort requests by fileName since order of requests isn't determinate
        let uploadRequests = mockAPIClient.imageUpload.requestHistory.sorted(by: {
            $0.fileName < $1.fileName
        })
        let highResRequest = uploadRequests[0]
        let lowResRequest = uploadRequests[1]

        XCTAssertEqual(uploadRequests.count, 2)

        XCTAssertEqual(highResRequest.fileName, "\(mockVS)_\(side.rawValue)")
        XCTAssertEqual(lowResRequest.fileName, "\(mockVS)_\(side.rawValue)_full_frame")

        // Verify only front is uploading
        guard let thisSideUploadFuture = getThisSideUploadFuture() else {
            return XCTFail("Expected non-nil \(side.rawValue)UploadFuture")
        }
        XCTAssertNil(getOtherSideUploadFuture())

        // Verify promise is observed after API responds to request
        thisSideUploadFuture.observe { result in
            defer {
                uploadResponseExp.fulfill()
            }

            guard case .success(let fileData) = result else {
                return XCTFail("Expected success")
            }

            DocumentUploaderTest.verifyFileData(
                fileData,
                expectedHighResImage: DocumentUploaderTest.mockStripeFile.id,
                expectedLowResImage: DocumentUploaderTest.mockStripeFile.id,
                expectedUploadMethod: .autoCapture
            )
        }
        mockAPIClient.imageUpload.respondToRequests(
            with: .success(
                (
                    file: DocumentUploaderTest.mockStripeFile,
                    metrics: DocumentUploaderTest.mockUploadMetrics
                )
            )
        )
        wait(for: [uploadResponseExp], timeout: 1)

        XCTAssertEqual(getThisSideUploadStatus(), .complete)
        XCTAssertEqual(delegateCallCount, 2)
    }
}

private class MockDocumentUploaderDelegate: DocumentUploaderDelegate {
    func documentUploaderDidUploadFront(_ documentUploader: DocumentUploaderProtocol) {}

    func documentUploaderDidUploadBack(_ documentUploader: DocumentUploaderProtocol) {}

    var callback: () -> Void = {}

    func documentUploaderDidUpdateStatus(_ documentUploader: DocumentUploader) {
        callback()
    }
}

extension DocumentUploader.UploadStatus: Equatable {
    public static func == (
        lhs: DocumentUploader.UploadStatus,
        rhs: DocumentUploader.UploadStatus
    ) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.inProgress, .inProgress),
            (.complete, .complete):
            return true
        case (.error(let leftError), .error(let rightError)):
            return (leftError as NSError).isEqual(rightError as NSError)
        default:
            return false
        }
    }
}

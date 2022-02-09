//
//  DocumentUploaderTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 1/7/22.
//

import XCTest
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity

final class DocumentUploaderTest: XCTestCase {

    var uploader: DocumentUploader!
    fileprivate var mockDelegate: MockDocumentUploaderDelegate!
    var mockAPIClient: IdentityAPIClientTestMock!
    static var mockStripeFile: StripeFile!

    let mockVS = "VS_123"
    let mockEAK = "EAK_123"
    let mockConfig = DocumentUploader.Configuration(
        filePurpose: "mock_purpose",
        highResImageCompressionQuality: 0.9,
        highResImageCropPadding: 0,
        highResImageMaxDimension: 600,
        lowResImageCompressionQuality: 0.8,
        lowResImageMaxDimension: 200
    )

    let mockImage = CIImage(contentsOf: CapturedImageMock.frontDriversLicense.url)!

    // This is the bounds of the document in the mock photo in image-coordinates
    // This must be a landscape region for the test to work
    let mockRegionOfInterest = CGRect(
        x: 0.03042328042,
        y: 0.3115079365,
        width: 0.8908730159,
        height: 0.4164186508
    )

    override class func setUp() {
        super.setUp()
        mockStripeFile = try! FileMock.identityDocument.make()
    }

    override func setUp() {
        super.setUp()
        mockAPIClient = IdentityAPIClientTestMock()
        uploader = DocumentUploader(
            configuration: mockConfig,
            apiClient: mockAPIClient,
            verificationSessionId: mockVS,
            ephemeralKeySecret: mockEAK
        )
        mockDelegate = MockDocumentUploaderDelegate()
        uploader.delegate = mockDelegate
    }

    func testSetup() {
        // The config max dimensions must be smaller than the image size for
        // this test to be valid
        XCTAssertLessThan(CGFloat(mockConfig.lowResImageMaxDimension), mockImage.extent.width)
        XCTAssertLessThan(CGFloat(mockConfig.lowResImageMaxDimension), mockImage.extent.height)
        XCTAssertLessThan(CGFloat(mockConfig.highResImageMaxDimension), mockImage.extent.width)
        XCTAssertLessThan(CGFloat(mockConfig.highResImageMaxDimension), mockImage.extent.height)

        // This test also assumes that the test image is in portrait
        XCTAssertLessThan(mockImage.extent.width, mockImage.extent.height)
    }

    // Tests that JPEG is uploaded at the specified
    func testUploadJPEG() {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 1)
        let uploadResponseExp = expectation(description: "Upload completed")
        let fileName = "test_name"
        let compressionQuality: CGFloat = 0.1

        uploader.uploadJPEG(
            image: mockImage,
            fileName: fileName,
            jpegCompressionQuality: compressionQuality
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with \(error)")
            case .success(let stripeFile):
                XCTAssertEqual(stripeFile, DocumentUploaderTest.mockStripeFile)
            }
            uploadResponseExp.fulfill()
        }

        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        // Verify request params match expected values
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 1)

        let uploadRequest = mockAPIClient.imageUpload.requestHistory.first
        XCTAssertNotNil(uploadRequest?.image)
        XCTAssertEqual(uploadRequest?.compressionQuality, compressionQuality)
        XCTAssertEqual(uploadRequest?.purpose, mockConfig.filePurpose)
        XCTAssertEqual(uploadRequest?.fileName, fileName)
        XCTAssertEqual(uploadRequest?.ownedBy, mockVS)
        XCTAssertEqual(uploadRequest?.ephemeralKeySecret, mockEAK)

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(with: .success(DocumentUploaderTest.mockStripeFile))
        wait(for: [uploadResponseExp], timeout: 1)
    }

    func testUploadLowResImage() {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 1)
        let prefix = "low-res-prefix"

        uploader.uploadLowResImage(
            mockImage,
            fileNamePrefix: prefix
        ).observe { _ in
            // no-op
        }


        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        // Verify image has been resized correctly
        // (assumes original image is in portrait)
        XCTAssertEqual(uploadRequest.image.size.height, CGFloat(mockConfig.lowResImageMaxDimension), accuracy: 1)
        XCTAssertLessThan(uploadRequest.image.size.width, CGFloat(mockConfig.lowResImageMaxDimension))
        XCTAssertEqual(uploadRequest.compressionQuality, CGFloat(mockConfig.lowResImageCompressionQuality))
        XCTAssertEqual(uploadRequest.fileName, "\(prefix)_full_frame")
    }

    func testUploadHighResImageUncropped() {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 1)
        let prefix = "high-res-prefix"

        uploader.uploadHighResImage(
            mockImage,
            regionOfInterest: nil,
            fileNamePrefix: prefix
        ).observe { _ in
            // no-op
        }

        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        // Verify image has been resized correctly
        // (assumes original image is in portrait)
        XCTAssertEqual(uploadRequest.image.size.height, CGFloat(mockConfig.highResImageMaxDimension), accuracy: 1)
        XCTAssertLessThan(uploadRequest.image.size.width, CGFloat(mockConfig.highResImageMaxDimension))
        XCTAssertEqual(uploadRequest.compressionQuality, mockConfig.highResImageCompressionQuality)
        XCTAssertEqual(uploadRequest.fileName, prefix)
    }

    func testUploadHighResImageCropped() {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 1)
        let prefix = "high-res-prefix"

        uploader.uploadHighResImage(
            mockImage,
            regionOfInterest: mockRegionOfInterest,
            fileNamePrefix: prefix
        ).observe { _ in
            // no-op
        }

        // Wait until request is made
        wait(for: uploadRequestExpectations, timeout: 1)

        guard let uploadRequest = mockAPIClient.imageUpload.requestHistory.first else {
            return XCTFail("Expected an upload request")
        }
        // Verify image has been resized correctly
        // (assumes ROI is in landscape)
        XCTAssertLessThan(uploadRequest.image.size.height, CGFloat(mockConfig.highResImageMaxDimension))
        XCTAssertEqual(uploadRequest.image.size.width, CGFloat(mockConfig.highResImageMaxDimension), accuracy: 1)
        XCTAssertEqual(uploadRequest.compressionQuality, mockConfig.highResImageCompressionQuality)
        XCTAssertEqual(uploadRequest.fileName, prefix)
    }

    // Tests the happy path where both images are uploaded successfully
    func testUploadImagesWithROISuccess() {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 2)
        let uploadResponseExp = expectation(description: "Upload completed")
        let method = VerificationPageDataDocumentFileData.FileUploadMethod.autoCapture
        let prefix = "img-prefix"

        // Upload images
        uploader.uploadImages(
            mockImage,
            documentBounds: mockRegionOfInterest,
            method: method,
            fileNamePrefix: prefix
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with \(error)")
            case .success(let data):
                // TODO(mludowise|IDPROD-2482): Test ML scores to API model
                XCTAssertEqual(data.highResImage, DocumentUploaderTest.mockStripeFile.id)
                XCTAssertEqual(data.lowResImage, DocumentUploaderTest.mockStripeFile.id)
                XCTAssertEqual(data.uploadMethod, method)
            }
            uploadResponseExp.fulfill()
        }

        // Verify a request is made for each of the high & low res uploads
        wait(for: uploadRequestExpectations, timeout: 1)

        // Sort requests by fileName since order of requests isn't determinate
        let uploadRequests = mockAPIClient.imageUpload.requestHistory.sorted(by: { $0.fileName < $1.fileName })
        let highResRequest = uploadRequests[0]
        let lowResRequest = uploadRequests[1]

        XCTAssertEqual(uploadRequests.count, 2)

        XCTAssertEqual(highResRequest.fileName, prefix)
        XCTAssertEqual(lowResRequest.fileName, "\(prefix)_full_frame")

        // Verify high res image was cropped & low res wasn't based on which is
        // in portrait mode
        XCTAssertLessThan(highResRequest.image.size.height, CGFloat(mockConfig.highResImageMaxDimension))
        XCTAssertEqual(highResRequest.image.size.width, CGFloat(mockConfig.highResImageMaxDimension), accuracy: 1)
        XCTAssertEqual(lowResRequest.image.size.height, CGFloat(mockConfig.lowResImageMaxDimension), accuracy: 1)
        XCTAssertLessThan(lowResRequest.image.size.width, CGFloat(mockConfig.lowResImageMaxDimension))

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(with: .success(DocumentUploaderTest.mockStripeFile))
        wait(for: [uploadResponseExp], timeout: 1)
    }

    // Tests the happy path where one uncropped image is uploaded successfully
    // because there is no ROI
    func testUploadImagesNoROISuccess() {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 1)

        // Upload images

        let uploadResponseExp = expectation(description: "Upload completed")
        let method = VerificationPageDataDocumentFileData.FileUploadMethod.fileUpload
        let prefix = "img-prefix"

        uploader.uploadImages(
            mockImage,
            documentBounds: nil,
            method: method,
            fileNamePrefix: prefix
        ).observe { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed with \(error)")
            case .success(let data):
                // TODO(mludowise|IDPROD-2482): Test ML scores to API model
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
        XCTAssertEqual(uploadRequest.image.size.height, CGFloat(mockConfig.highResImageMaxDimension), accuracy: 1)
        XCTAssertLessThan(uploadRequest.image.size.width, CGFloat(mockConfig.highResImageMaxDimension))

        // Verify promise is observed after API responds to request
        mockAPIClient.imageUpload.respondToRequests(with: .success(DocumentUploaderTest.mockStripeFile))
        wait(for: [uploadResponseExp], timeout: 1)
    }

    // Tests when the image upload errors
    func testUploadImagesError() {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 1)
        let uploadResponseExp = expectation(description: "Upload completed")
        let method = VerificationPageDataDocumentFileData.FileUploadMethod.fileUpload
        let prefix = "img-prefix"

        uploader.uploadImages(
            mockImage,
            documentBounds: nil,
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
        verifyUploadSide(.front,
                         getThisSideUploadFuture: { uploader.frontUploadFuture },
                         getOtherSideUploadFuture: { uploader.backUploadFuture },
                         getThisSideUploadStatus: { uploader.frontUploadStatus }
        )
    }

    // Test that both images for the back side of the doc are uploaded
    func testUploadImagesForBackSide() {
        verifyUploadSide(.back,
                         getThisSideUploadFuture: { uploader.backUploadFuture },
                         getOtherSideUploadFuture: { uploader.frontUploadFuture },
                         getThisSideUploadStatus: { uploader.backUploadStatus }
        )
    }

    func testCombinedUploadFuture() {
        let mockFileData = VerificationPageDataUpdateMock.default.collectedData.idDocument.map { (front: $0.front!, back: $0.back!) }!
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 4)

        uploader.uploadImages(
            for: .front,
            originalImage: mockImage,
            documentBounds: mockRegionOfInterest,
            method: .autoCapture
        )
        uploader.uploadImages(
            for: .back,
            originalImage: mockImage,
            documentBounds: mockRegionOfInterest,
            method: .autoCapture
        )

        // Verify 4 images upload requests are made
        wait(for: uploadRequestExpectations, timeout: 1)

        var frontBackUploadFutureObserved = false
        uploader.frontBackUploadFuture.observe { _ in
            frontBackUploadFutureObserved = true
        }

        XCTAssertFalse(frontBackUploadFutureObserved)

        // Mock that front finishes uploading
        (uploader.frontUploadFuture as! Promise).resolve(with: mockFileData.front)

        // Combined future should not be fulfilled yet
        XCTAssertFalse(frontBackUploadFutureObserved)

        // Mock that back finishes uploading
        (uploader.backUploadFuture as! Promise).resolve(with: mockFileData.back)

        XCTAssertTrue(frontBackUploadFutureObserved)
    }
}

private extension DocumentUploaderTest {
    // Ensures `count` number of files are uploaded
    func makeUploadRequestExpectations(
        count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [XCTestExpectation] {
        var expectations: [XCTestExpectation] = []
        expectations.reserveCapacity(count)
        (1...count).forEach { expectations.append(.init(description: "Uploaded image \($0)")) }

        var uploadCount = 0

        mockAPIClient.imageUpload.callBackOnRequest {
            // Increment uploadCount last
            defer {
                uploadCount += 1
            }
            guard uploadCount < count else {
                return XCTFail("Images were uploaded \(uploadCount+1) times. Only expected \(count) times.", file: file, line: line)
            }
            expectations[uploadCount].fulfill()
        }

        return expectations
    }

    func verifyUploadSide(
        _ side: DocumentSide,
        getThisSideUploadFuture: () -> Future<VerificationPageDataDocumentFileData>?,
        getOtherSideUploadFuture: () -> Future<VerificationPageDataDocumentFileData>?,
        getThisSideUploadStatus: () -> DocumentUploader.UploadStatus
    ) {
        let uploadRequestExpectations = makeUploadRequestExpectations(count: 2)
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
            documentBounds: mockRegionOfInterest,
            method: .autoCapture
        )

        XCTAssertEqual(getThisSideUploadStatus(), .inProgress)
        XCTAssertEqual(delegateCallCount, 1)

        // Verify a request is made for each of the high & low res uploads
        wait(for: uploadRequestExpectations, timeout: 1)

        XCTAssertEqual(getThisSideUploadStatus(), .inProgress)
        XCTAssertEqual(delegateCallCount, 1)

        // Sort requests by fileName since order of requests isn't determinate
        let uploadRequests = mockAPIClient.imageUpload.requestHistory.sorted(by: { $0.fileName < $1.fileName })
        let highResRequest = uploadRequests[0]
        let lowResRequest = uploadRequests[1]

        XCTAssertEqual(uploadRequests.count, 2)

        XCTAssertEqual(highResRequest.fileName, "\(mockVS)_\(side.rawValue)")
        XCTAssertEqual(lowResRequest.fileName, "\(mockVS)_\(side.rawValue)_full_frame")

        // Verify only front is uploading
        guard let frontUploadFuture = getThisSideUploadFuture() else {
            return XCTFail("Expected non-nil \(side.rawValue)UploadFuture")
        }
        XCTAssertNil(getOtherSideUploadFuture())

        // Verify promise is observed after API responds to request
        frontUploadFuture.observe { _ in
            uploadResponseExp.fulfill()
        }
        mockAPIClient.imageUpload.respondToRequests(with: .success(DocumentUploaderTest.mockStripeFile))
        wait(for: [uploadResponseExp], timeout: 1)

        XCTAssertEqual(getThisSideUploadStatus(), .complete)
        XCTAssertEqual(delegateCallCount, 2)
    }
}

private class MockDocumentUploaderDelegate: DocumentUploaderDelegate {
    var callback: () -> Void = {}

    func documentUploaderDidUpdateStatus(_ documentUploader: DocumentUploader) {
        callback()
    }
}

extension DocumentUploader.UploadStatus: Equatable {
    public static func == (lhs: DocumentUploader.UploadStatus, rhs: DocumentUploader.UploadStatus) -> Bool {
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

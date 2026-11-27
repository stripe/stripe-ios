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

    func testMediaPipeDefaultsExpandAllFrontCropsAndPreserveFullFrames() throws {
        // Given distinct front and side images with an 80-by-160-pixel face at (120, 200)
        // ...and a legacy crop padding that MediaPipe crops don't use
        uploader = makeUploader(isTestMode: false, legacyCropPadding: 0.125)
        let first = makePatternedCapture(colorOffset: 0)
        let best = makePatternedCapture(colorOffset: 1)
        let last = makePatternedCapture(colorOffset: 2)
        let left = makePatternedCapture(colorOffset: 3)
        let right = makePatternedCapture(colorOffset: 4)
        let captures = try XCTUnwrap(
            FaceCaptureData(samples: [first, best, last], leftSide: left, rightSide: right)
        )
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 8)

        // When all captures are uploaded with the default MediaPipe padding
        uploader.uploadImages(captures)
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then each front crop expands the face box and pads it as web does
        let expectedCrop = CGRect(x: 74, y: 65, width: 173, height: 420)
        for (capture, name) in [
            (best, "VS_123_face"),
            (first, "VS_123_face_first_crop_frame"),
            (last, "VS_123_face_last_crop_frame"),
        ] {
            try assertUploadedImage(named: name, matches: capture.image, croppedTo: expectedCrop)
        }

        // ...and all front and side full-frame images retain the complete image
        for (capture, name) in [
            (best, "VS_123_face_full_frame"),
            (first, "VS_123_face_first_full_frame"),
            (last, "VS_123_face_last_full_frame"),
            (left, "VS_123_face_left_full_frame"),
            (right, "VS_123_face_right_full_frame"),
        ] {
            try assertUploadedImage(named: name, matches: capture.image)
        }
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 8)
    }

    func testMediaPipeOverridesDoNotChangeLegacyCropForTheSameImage() throws {
        // Given the same image and face rect from each detector, with distinct padding settings
        uploader = makeUploader(
            isTestMode: false,
            legacyCropPadding: 0.125,
            mediaPipeCropSidePadding: 0.25,
            mediaPipeCropTopPadding: 0.5,
            mediaPipeCropBottomPadding: 0.125
        )
        let mediaPipeCapture = makePatternedCapture()
        let legacyCapture = makePatternedCapture(isFromMediaPipe: false)
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 4)

        // When both are uploaded by the same uploader
        _ = uploader.uploadImages(mediaPipeCapture, ofType: .best)
        _ = uploader.uploadImages(legacyCapture, ofType: .first)
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then MediaPipe pads the expanded face box with the configured fractions
        try assertUploadedImage(
            named: "VS_123_face",
            matches: mediaPipeCapture.image,
            croppedTo: CGRect(x: 96, y: 34, width: 130, height: 383)
        )

        // ...and legacy retains its configured 10 pixels of padding on every side
        try assertUploadedImage(
            named: "VS_123_face_first_crop_frame",
            matches: legacyCapture.image,
            croppedTo: CGRect(x: 110, y: 190, width: 100, height: 180)
        )
        try assertUploadedImage(named: "VS_123_face_full_frame", matches: mediaPipeCapture.image)
        try assertUploadedImage(named: "VS_123_face_first_full_frame", matches: legacyCapture.image)
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 4)
    }

    func testMediaPipeZeroPaddingCropsToTheExpandedFaceBox() throws {
        // Given explicit zero MediaPipe padding and nonzero legacy padding
        uploader = makeUploader(
            isTestMode: false,
            legacyCropPadding: 0.5,
            mediaPipeCropSidePadding: 0,
            mediaPipeCropTopPadding: 0,
            mediaPipeCropBottomPadding: 0
        )
        let capture = makePatternedCapture()
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 2)

        // When the MediaPipe image is uploaded
        _ = uploader.uploadImages(capture, ofType: .best)
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then the crop still contains the fixed face box expansion
        try assertUploadedImage(
            named: "VS_123_face",
            matches: capture.image,
            croppedTo: CGRect(x: 118, y: 160, width: 86, height: 209)
        )
    }

    func testMediaPipeCropsStayInsideImageEdges() throws {
        // Given faces whose padded crops extend beyond opposite image corners
        uploader = makeUploader(isTestMode: false)
        let topLeft = makePatternedCapture(
            faceRect: CGRect(x: 0.0625, y: 0.0625, width: 0.25, height: 0.25)
        )
        let bottomRight = makePatternedCapture(
            faceRect: CGRect(x: 0.6875, y: 0.6875, width: 0.25, height: 0.25)
        )
        let uploadRequestExpectations = mockAPIClient.makeUploadRequestExpectations(count: 4)

        // When both images are uploaded
        _ = uploader.uploadImages(topLeft, ofType: .first)
        _ = uploader.uploadImages(bottomRight, ofType: .last)
        wait(for: uploadRequestExpectations, timeout: 1)

        // Then the crops contain only image pixels, without a border
        try assertUploadedImage(
            named: "VS_123_face_first_crop_frame",
            matches: topLeft.image,
            croppedTo: CGRect(x: 0, y: 0, width: 165, height: 359)
        )
        try assertUploadedImage(
            named: "VS_123_face_last_crop_frame",
            matches: bottomRight.image,
            croppedTo: CGRect(x: 170, y: 241, width: 150, height: 399)
        )
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 4)
    }
}

private extension SelfieUploaderTest {
    func uploadRequest(
        named fileName: String
    ) -> IdentityAPIClientTestMock.ImageUploadRequestParams? {
        return mockAPIClient.imageUpload.requestHistory.first { $0.fileName == fileName }
    }

    func makeUploader(
        isTestMode: Bool,
        legacyCropPadding: CGFloat = 0.5,
        mediaPipeCropSidePadding: CGFloat? = nil,
        mediaPipeCropTopPadding: CGFloat? = nil,
        mediaPipeCropBottomPadding: CGFloat? = nil
    ) -> SelfieUploader {
        let config = IdentityImageUploaderTest.mockConfig
        return SelfieUploader(
            imageUploader: IdentityImageUploader(
                configuration: .init(
                    filePurpose: config.filePurpose,
                    highResImageCompressionQuality: config.highResImageCompressionQuality,
                    highResImageCropPadding: legacyCropPadding,
                    highResImageMaxDimension: config.highResImageMaxDimension,
                    lowResImageCompressionQuality: config.lowResImageCompressionQuality,
                    lowResImageMaxDimension: config.lowResImageMaxDimension
                ),
                sheetController: VerificationSheetControllerMock(
                    apiClient: mockAPIClient,
                    analyticsClient: .init(verificationSessionId: "")
                )
            ),
            isTestMode: isTestMode,
            mediaPipeCropSidePadding: mediaPipeCropSidePadding,
            mediaPipeCropTopPadding: mediaPipeCropTopPadding,
            mediaPipeCropBottomPadding: mediaPipeCropBottomPadding
        )
    }

    func makePatternedCapture(
        colorOffset: Int = 0,
        faceRect: CGRect = CGRect(x: 0.375, y: 0.3125, width: 0.25, height: 0.25),
        isFromMediaPipe: Bool = true
    ) -> FaceScannerInputOutput {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 640), format: format).image { context in
            for y in stride(from: 0, to: 640, by: 16) {
                for x in stride(from: 0, to: 320, by: 16) {
                    UIColor(
                        red: CGFloat(x) / 320,
                        green: CGFloat(y) / 640,
                        blue: CGFloat(colorOffset) / 4,
                        alpha: 1
                    ).setFill()
                    context.fill(CGRect(x: x, y: y, width: 16, height: 16))
                }
            }
        }
        return FaceScannerInputOutput(
            image: image.cgImage!,
            scannerOutput: FaceScannerOutput(
                faceDetectorOutput: .init(predictions: [.init(rect: faceRect, score: 1)]),
                cameraProperties: nil,
                motionBlurResult: nil,
                isFromMediaPipe: isFromMediaPipe,
                isValid: true
            ),
            cameraExifMetadata: nil
        )
    }

    func assertUploadedImage(
        named fileName: String,
        matches image: CGImage,
        croppedTo crop: CGRect? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let request = try XCTUnwrap(uploadRequest(named: fileName), file: file, line: line)
        let expectedImage: CGImage
        let maxDimension: Int
        if let crop {
            expectedImage = try XCTUnwrap(image.cropping(to: crop), file: file, line: line)
            maxDimension = IdentityImageUploaderTest.mockConfig.highResImageMaxDimension
        } else {
            expectedImage = image
            maxDimension = IdentityImageUploaderTest.mockConfig.lowResImageMaxDimension
        }
        XCTAssertEqual(
            request.image.pngData(),
            try resizedPNGData(for: expectedImage, maxDimension: maxDimension),
            fileName,
            file: file,
            line: line
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

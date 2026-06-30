//
//  SelfieUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit

/// Dependency-injectable protocol for SelfieUploader
protocol SelfieUploaderProtocol: AnyObject {
    var uploadFuture: Future<SelfieUploader.FileData>? { get }

    func uploadImages(
        _ capturedImages: FaceCaptureData
    )

    func reset()
}

final class SelfieUploader: SelfieUploaderProtocol {

    struct FileData {
        let bestHighResFile: StripeFile
        let bestLowResFile: StripeFile
        let firstHighResFile: StripeFile
        let firstLowResFile: StripeFile
        let lastHighResFile: StripeFile
        let lastLowResFile: StripeFile
        let leftFullFrameFile: StripeFile?
        let rightFullFrameFile: StripeFile?

        init(
            bestHighResFile: StripeFile,
            bestLowResFile: StripeFile,
            firstHighResFile: StripeFile,
            firstLowResFile: StripeFile,
            lastHighResFile: StripeFile,
            lastLowResFile: StripeFile,
            leftFullFrameFile: StripeFile? = nil,
            rightFullFrameFile: StripeFile? = nil
        ) {
            self.bestHighResFile = bestHighResFile
            self.bestLowResFile = bestLowResFile
            self.firstHighResFile = firstHighResFile
            self.firstLowResFile = firstLowResFile
            self.lastHighResFile = lastHighResFile
            self.lastLowResFile = lastLowResFile
            self.leftFullFrameFile = leftFullFrameFile
            self.rightFullFrameFile = rightFullFrameFile
        }
    }

    let imageUploader: IdentityImageUploader

    private(set) var uploadFuture: Future<FileData>?

    init(
        imageUploader: IdentityImageUploader
    ) {
        self.imageUploader = imageUploader
    }

    /// Uploads a high and low resolution image for each of the captured images.
    /// - Parameters:
    ///   - capturedImages: The original images and scanner output for each captured selfie image.
    func uploadImages(
        _ capturedImages: FaceCaptureData
    ) {
        let bestUploadFuture = uploadImages(capturedImages.bestMiddle, ofType: .best)
        let firstUploadFuture = uploadImages(capturedImages.first, ofType: .first)
        let lastUploadFuture = uploadImages(capturedImages.last, ofType: .last)
        let leftUploadFuture = capturedImages.leftSide.map { uploadFullFrameImage($0, ofType: .left) }
        let rightUploadFuture = capturedImages.rightSide.map { uploadFullFrameImage($0, ofType: .right) }

        uploadFuture = bestUploadFuture.chained { bestFiles in
            return firstUploadFuture.chained { firstFiles in
                return lastUploadFuture.chained { lastFiles in
                    return Self.uploadedOptionalFile(from: leftUploadFuture).chained { leftFile in
                        return Self.uploadedOptionalFile(from: rightUploadFuture).chained { rightFile in
                            return Promise(
                                value: FileData(
                                    bestHighResFile: bestFiles.highRes,
                                    bestLowResFile: bestFiles.lowRes,
                                    firstHighResFile: firstFiles.highRes,
                                    firstLowResFile: firstFiles.lowRes,
                                    lastHighResFile: lastFiles.highRes,
                                    lastLowResFile: lastFiles.lowRes,
                                    leftFullFrameFile: leftFile,
                                    rightFullFrameFile: rightFile
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    static func uploadedOptionalFile(
        from future: Future<StripeFile>?
    ) -> Future<StripeFile?> {
        guard let future else {
            return Promise(value: nil)
        }

        return future.chained { file in
            return Promise(value: file)
        }
    }

    func uploadImages(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) -> Future<IdentityImageUploader.LowHighResFiles> {
        return imageUploader.uploadLowAndHighResImages(
            capturedImage.image,
            highResRegionOfInterest: capturedImage.scannerOutput.faceRect,
            cropPaddingComputationMethod: .regionWidth,
            lowResFileName: SelfieUploader.fileName(
                with: imageUploader.apiClient.verificationSessionId,
                for: type,
                resolution: .low
            ),
            highResFileName: SelfieUploader.fileName(
                with: imageUploader.apiClient.verificationSessionId,
                for: type,
                resolution: .high
            )
        )
    }

    func uploadFullFrameImage(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) -> Future<StripeFile> {
        return imageUploader.uploadLowResImage(
            capturedImage.image,
            fileName: SelfieUploader.fileName(
                with: imageUploader.apiClient.verificationSessionId,
                for: type,
                resolution: .low
            )
        )
    }

    func reset() {
        uploadFuture = nil
    }
}

// MARK: - File Name Helpers

extension SelfieUploader {
    enum ImageType {
        case first, last, best, left, right
    }

    enum Resolution {
        case high, low
    }

    static func fileName(
        with identifier: String,
        for type: ImageType,
        resolution: Resolution
    ) -> String {
        let suffix = fileNameSuffix(for: type, resolution: resolution)
        return "\(identifier)_\(suffix)"
    }

    static func fileNameSuffix(for type: ImageType, resolution: Resolution) -> String {
        switch (type, resolution) {
        case (.best, .high):
            return "face"
        case (.best, .low):
            return "face_full_frame"
        case (.first, .high):
            return "face_first_crop_frame"
        case (.first, .low):
            return "face_first_full_frame"
        case (.last, .high):
            return "face_last_crop_frame"
        case (.last, .low):
            return "face_last_full_frame"
        case (.left, .high):
            return "face_left_crop_frame"
        case (.left, .low):
            return "face_left_full_frame"
        case (.right, .high):
            return "face_right_crop_frame"
        case (.right, .low):
            return "face_right_full_frame"
        }
    }
}

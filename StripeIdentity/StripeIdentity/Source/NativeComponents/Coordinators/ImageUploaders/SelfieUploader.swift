//
//  SelfieUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/31/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

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
    }

    let imageUploader: IdentityImageUploader

    private(set) var uploadFuture: Future<FileData>?

    init(imageUploader: IdentityImageUploader) {
        self.imageUploader = imageUploader
    }

    /**
     Uploads a high and low resolution image for each of the captured images.
     - Parameters:
       - capturedImages: The original images and scanner output for each of the 3 captured images.
     */
    func uploadImages(
        _ capturedImages: FaceCaptureData
    ) {
        // Start uploading all 3 images in parallel
        let bestUploadFuture = uploadImages(capturedImages.bestMiddle, ofType: .best)
        let firstUploadFuture = uploadImages(capturedImages.first, ofType: .first)
        let lastUploadFuture = uploadImages(capturedImages.last, ofType: .last)

        // Combine results when all 3 images are done uploading
        uploadFuture = bestUploadFuture.chained { bestFiles in
            return firstUploadFuture.chained { firstFiles in
                return lastUploadFuture.chained { lastFiles in
                    return Promise(
                        value: FileData(
                            bestHighResFile: bestFiles.highRes,
                            bestLowResFile: bestFiles.lowRes,
                            firstHighResFile: firstFiles.highRes,
                            firstLowResFile: firstFiles.lowRes,
                            lastHighResFile: lastFiles.highRes,
                            lastLowResFile: lastFiles.lowRes
                        )
                    )
                }
            }
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

    func reset() {
        uploadFuture = nil
    }
}

// MARK: - File Name Helpers

extension SelfieUploader {
    enum ImageType {
        case first, last, best
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
        }
    }
}

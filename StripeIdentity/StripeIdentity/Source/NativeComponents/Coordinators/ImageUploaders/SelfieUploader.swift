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

// TODO(mludowise): This is a temporary API object placeholder until the API changes are made
struct VerificationPageDataSelfieFileData {
    init(
        bestMiddleImageFiles: IdentityImageUploader.LowHighResFiles,
        firstImageFiles: IdentityImageUploader.LowHighResFiles,
        lastImageFiles: IdentityImageUploader.LowHighResFiles
    ) {
        // TODO(mludowise): Save image files to API object
        #if DEBUG
        print("best high res: \(bestMiddleImageFiles.highRes.id)")
        print("best low res: \(String(describing: bestMiddleImageFiles.lowRes?.id))")
        print("first high res: \(firstImageFiles.highRes.id)")
        print("first low res: \(String(describing: firstImageFiles.lowRes?.id))")
        print("last high res: \(lastImageFiles.highRes.id)")
        print("last low res: \(String(describing: lastImageFiles.lowRes?.id))")
        #endif
    }
}

/// Dependency-injectable protocol for SelfieUploader
protocol SelfieUploaderProtocol: AnyObject {
    var uploadFuture: Future<VerificationPageDataSelfieFileData>? { get }

    func uploadImages(
        _ capturedImages: FaceCaptureData
    )

    func reset()
}


final class SelfieUploader: SelfieUploaderProtocol {

    let imageUploader: IdentityImageUploader

    private(set) var uploadFuture: Future<VerificationPageDataSelfieFileData>?

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
                        value: VerificationPageDataSelfieFileData(
                            bestMiddleImageFiles: bestFiles,
                            firstImageFiles: firstFiles,
                            lastImageFiles: lastFiles
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

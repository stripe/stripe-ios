//
//  IdentityImageUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit

final class IdentityImageUploader {
    typealias LowHighResFiles = (lowRes: StripeFile, highRes: StripeFile)

    struct Configuration {
        /// The `purpose` to use when uploading the files
        let filePurpose: String
        /// JPEG compression quality of the high-res image uploaded to the server
        let highResImageCompressionQuality: CGFloat
        /// Value between 0–1 that determines how much padding to crop around a region of interest in an image
        let highResImageCropPadding: CGFloat
        /// Maximum width and height of the high-res image uploaded to the server
        let highResImageMaxDimension: Int
        /// JPEG compression quality of the low-res image uploaded to the server
        let lowResImageCompressionQuality: CGFloat
        /// Maximum width and height of the low-res image uploaded to the server
        let lowResImageMaxDimension: Int
    }

    /// Determines padding, compression, and scaling of images uploaded to the server
    let configuration: Configuration

    let apiClient: IdentityAPIClient
    let analyticsClient: IdentityAnalyticsClient
    let sheetController: VerificationSheetControllerProtocol

    init(
        configuration: Configuration,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.configuration = configuration
        self.apiClient = sheetController.apiClient
        self.analyticsClient = sheetController.analyticsClient
        self.sheetController = sheetController
    }

    func uploadLowAndHighResImagesNoCropping(
        highResImage: CGImage,
        lowResImage: CGImage,
        highResFileName: String,
        lowResFileName: String
    ) async throws -> LowHighResFiles {
        let lowResTask = Task {
            try await uploadLowResImage(
                lowResImage,
                fileName: lowResFileName
            )
        }

        let highResTask = Task {
            try await uploadJPEGResize(
                image: highResImage,
                fileName: highResFileName,
                jpegCompressionQuality: configuration.highResImageCompressionQuality,
                newSize: CGSize(
                    width: configuration.highResImageMaxDimension,
                    height: configuration.highResImageMaxDimension
                )
            )
        }

        return try await (
            lowRes: lowResTask.value,
            highRes: highResTask.value
        )
    }

    func uploadLowAndHighResImages(
        _ image: CGImage,
        highResRegionOfInterest: CGRect,
        cropPaddingComputationMethod: CGImage.CropPaddingComputationMethod,
        lowResFileName: String,
        highResFileName: String
    ) async throws -> LowHighResFiles {
        let lowResTask = Task {
            try await uploadLowResImage(
                image,
                fileName: lowResFileName
            )
        }

        let highResTask = Task {
            try await uploadHighResImage(
                image,
                regionOfInterest: highResRegionOfInterest,
                cropPaddingComputationMethod: cropPaddingComputationMethod,
                fileName: highResFileName
            )
        }

        return try await (
            lowRes: lowResTask.value,
            highRes: highResTask.value
        )
    }

    /// Crops, resizes, and uploads the high resolution image to the server
    func uploadHighResImage(
        _ image: CGImage,
        regionOfInterest: CGRect?,
        cropPaddingComputationMethod: CGImage.CropPaddingComputationMethod,
        fileName: String
    ) async throws -> StripeFile {
        do {
            // Crop image if there's a region of interest
            var imageToResize = image
            if let regionOfInterest = regionOfInterest {
                imageToResize = try image.cropping(
                    toNormalizedRegion: regionOfInterest,
                    withPadding: configuration.highResImageCropPadding,
                    computationMethod: cropPaddingComputationMethod
                )
            }

            return try await uploadJPEGResize(
                image: imageToResize,
                fileName: fileName,
                jpegCompressionQuality: configuration.highResImageCompressionQuality,
                newSize: CGSize(
                    width: configuration.highResImageMaxDimension,
                    height: configuration.highResImageMaxDimension
                )
            )
        } catch {
            await logUploadError(error, stage: .highResCrop, fileName: fileName)
            throw error
        }
    }

    /// Resizes and uploads the low resolution image to the server
    func uploadLowResImage(
        _ image: CGImage,
        fileName: String
    ) async throws -> StripeFile {
        try await uploadJPEGResize(
            image: image,
            fileName: fileName,
            jpegCompressionQuality: configuration.lowResImageCompressionQuality,
            newSize: CGSize(
                width: configuration.lowResImageMaxDimension,
                height: configuration.lowResImageMaxDimension
            )
        )
    }

    func uploadJPEGResize(
        image: CGImage,
        fileName: String,
        jpegCompressionQuality: CGFloat,
        newSize: CGSize
    ) async throws -> StripeFile {
        do {
            let resizedImage = try image.scaledDown(toMaxPixelDimension: newSize)

            return try await uploadJPEG(
                image: resizedImage,
                fileName: fileName,
                jpegCompressionQuality: jpegCompressionQuality
            )
        } catch {
            await logUploadError(error, stage: .imageResize, fileName: fileName)
            throw error
        }
    }

    /// Converts image to JPEG data and uploads it to the server on a worker thread
    func uploadJPEG(
        image: CGImage,
        fileName: String,
        jpegCompressionQuality: CGFloat
    ) async throws -> StripeFile {
        do {
            let uiImage = UIImage(cgImage: image)
            let (file, metrics) = try await self.apiClient.uploadImage(
                uiImage,
                compressionQuality: jpegCompressionQuality,
                purpose: self.configuration.filePurpose,
                fileName: fileName
            )

            await self.analyticsClient.logImageUpload(
                timeToUpload: metrics.timeToUpload,
                compressionQuality: jpegCompressionQuality,
                fileId: file.id,
                fileName: fileName,
                fileSizeBytes: metrics.fileSizeBytes,
                sheetController: self.sheetController
            )

            return file
        } catch {
            await self.logUploadError(error, stage: .imageUpload, fileName: fileName)
            throw error
        }
    }
}

private extension IdentityImageUploader {
    enum UploadErrorStage: String {
        case highResCrop
        case imageResize
        case imageUpload
    }

    @MainActor
    func logUploadError(
        _ error: Error,
        stage: UploadErrorStage,
        fileName: String,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        analyticsClient.logGenericError(
            error: error,
            additionalMetadata: [
                "error_context": "image_upload",
                "image_upload_stage": stage.rawValue,
                "file_name": fileName,
                "file_purpose": configuration.filePurpose,
            ],
            filePath: filePath,
            line: line,
            sheetController: sheetController
        )
    }
}

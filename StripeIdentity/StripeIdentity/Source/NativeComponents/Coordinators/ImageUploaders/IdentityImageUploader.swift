//
//  IdentityImageUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/31/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

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
    let idDocumentType: DocumentType?

    /// Worker queue to encode the image to jpeg
    let imageEncodingQueue = DispatchQueue(label: "com.stripe.identity.image-encoding")

    init(
        configuration: Configuration,
        apiClient: IdentityAPIClient,
        analyticsClient: IdentityAnalyticsClient,
        idDocumentType: DocumentType?
    ) {
        self.configuration = configuration
        self.apiClient = apiClient
        self.analyticsClient = analyticsClient
        self.idDocumentType = idDocumentType
    }

    func uploadLowAndHighResImages(
        _ image: CGImage,
        highResRegionOfInterest: CGRect,
        cropPaddingComputationMethod: CGImage.CropPaddingComputationMethod,
        lowResFileName: String,
        highResFileName: String
    ) -> Future<LowHighResFiles> {
        let lowResUploadFuture = uploadLowResImage(
            image,
            fileName: lowResFileName
        )

        return uploadHighResImage(
            image,
            regionOfInterest: highResRegionOfInterest,
            cropPaddingComputationMethod: cropPaddingComputationMethod,
            fileName: highResFileName
        ).chained { highResFile in
            return lowResUploadFuture.chained { lowResFile in
                // Convert promise to a tuple of file IDs
                return Promise(value: (
                    lowRes: lowResFile,
                    highRes: highResFile
                ))
            }
        }
    }

    /// Crops, resizes, and uploads the high resolution image to the server
    func uploadHighResImage(
        _ image: CGImage,
        regionOfInterest: CGRect?,
        cropPaddingComputationMethod: CGImage.CropPaddingComputationMethod,
        fileName: String
    ) -> Future<StripeFile> {
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

            let resizedImage = try imageToResize.scaledDown(toMaxPixelDimension: CGSize(
                width: configuration.highResImageMaxDimension,
                height: configuration.highResImageMaxDimension
            ))

            return uploadJPEG(
                image: resizedImage,
                fileName: fileName,
                jpegCompressionQuality: configuration.highResImageCompressionQuality
            )
        } catch {
            return Promise(error: error)
        }
    }

    /// Resizes and uploads the low resolution image to the server
    func uploadLowResImage(
        _ image: CGImage,
        fileName: String
    ) -> Future<StripeFile> {
        do {
            let resizedImage = try image.scaledDown(toMaxPixelDimension: CGSize(
                width: configuration.lowResImageMaxDimension,
                height: configuration.lowResImageMaxDimension
            ))

            return uploadJPEG(
                image: resizedImage,
                fileName: fileName,
                jpegCompressionQuality: configuration.lowResImageCompressionQuality
            )
        } catch {
            return Promise(error: error)
        }
    }

    /// Converts image to JPEG data and uploads it to the server on a worker thread
    func uploadJPEG(
        image: CGImage,
        fileName: String,
        jpegCompressionQuality: CGFloat
    ) -> Future<StripeFile> {
        let promise = Promise<StripeFile>()
        imageEncodingQueue.async { [weak self] in
            guard let self = self else { return }

            let uiImage = UIImage(cgImage: image)
            self.apiClient.uploadImage(
                uiImage,
                compressionQuality: jpegCompressionQuality,
                purpose: self.configuration.filePurpose,
                fileName: fileName
            ).observe { [weak self] result in
                promise.fullfill(with: result.map { $0.file })

                if let self = self,
                   case let .success((file, metrics)) = result {
                    self.analyticsClient.logImageUpload(
                        idDocumentType: self.idDocumentType,
                        timeToUpload: metrics.timeToUpload,
                        compressionQuality: jpegCompressionQuality,
                        fileId: file.id,
                        fileName: fileName,
                        fileSizeBytes: metrics.fileSizeBytes
                    )
                }
            }
        }
        return promise
    }
}

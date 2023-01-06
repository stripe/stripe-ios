//
//  STPAPIClient+FileUpload.swift
//  StripeCore
//
//  Created by Mel Ludowise on 11/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension StripeFile.Purpose {
    /// See max purpose sizes https://stripe.com/docs/file-upload.
    var maxBytes: Int? {
        switch self {
        case .identityDocument,
            .identityPrivate:
            return 16_000_000
        case .disputeEvidence:
            return 5_000_000
        case .unparsable:
            return nil
        }
    }
}

/// STPAPIClient extensions to upload files.
extension STPAPIClient {
    @_spi(STP) public typealias FileAndUploadMetrics = (
        file: StripeFile,
        metrics: ImageUploadMetrics
    )

    /// Metrics returned in callback after image is uploaded to track performance.
    @_spi(STP) public struct ImageUploadMetrics {
        public let timeToUpload: TimeInterval
        public let fileSizeBytes: Int
    }

    @_spi(STP) public static let defaultImageFileName = "image"

    func data(
        forUploadedImage image: UIImage,
        compressionQuality: CGFloat,
        purpose: String
    ) -> Data {
        // Get maxBytes if file purpose is known to the client
        let maxBytes = StripeFile.Purpose(rawValue: purpose)?.maxBytes
        return image.jpegDataAndDimensions(
            maxBytes: maxBytes,
            compressionQuality: compressionQuality
        ).imageData
    }

    /// Uses the Stripe file upload API to upload a JPEG encoded image.
    ///
    /// The image will be automatically resized down if:
    /// 1. The given purpose is recognized by the client.
    /// 2. It's larger than the maximum allowed file size for the given purpose.
    ///
    /// - Parameters:
    ///   - image: The image to be uploaded.
    ///   - compressionQuality: The compression quality to use when encoding the jpeg.
    ///   - purpose: The purpose of this file.
    ///   - fileName: The name of the uploaded file. The "jpeg" extension will
    ///     automatically be appended to this name.
    ///   - ownedBy: A Stripe-internal property that sets the owner of the file.
    ///   - ephemeralKeySecret: Authorization key, if applicable.
    ///   - completion: The callback to run with the returned Stripe file (and any
    ///     errors that may have occurred).
    ///
    /// - Note:
    ///   The provided `purpose` must match a supported Purpose by Stripe's File
    ///   Upload API, or the API will respond with an error. Generally, this should
    ///   match a value in `StripeFile.Purpose`, but can be specified by any string
    ///   when forwarding the value from a Stripe server response in situations
    ///   where the purpose is not yet encoded in the client SDK.
    @_spi(STP) public func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat = UIImage.defaultCompressionQuality,
        purpose: String,
        fileName: String = defaultImageFileName,
        ownedBy: String? = nil,
        ephemeralKeySecret: String? = nil,
        completion: @escaping (Result<StripeFile, Error>) -> Void
    ) {
        uploadImageAndGetMetrics(
            image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: ownedBy,
            ephemeralKeySecret: ephemeralKeySecret
        ) { result in
            completion(result.map { $0.file })
        }
    }

    @_spi(STP) public func uploadImageAndGetMetrics(
        _ image: UIImage,
        compressionQuality: CGFloat = UIImage.defaultCompressionQuality,
        purpose: String,
        fileName: String = defaultImageFileName,
        ownedBy: String? = nil,
        ephemeralKeySecret: String? = nil,
        completion: @escaping (Result<FileAndUploadMetrics, Error>) -> Void
    ) {
        let purposePart = STPMultipartFormDataPart()
        purposePart.name = "purpose"
        // `unparsable` is not a valid purpose
        if purpose != StripeFile.Purpose.unparsable.rawValue,
            let purposeData = purpose.data(using: .utf8)
        {
            purposePart.data = purposeData
        }

        let imagePart = STPMultipartFormDataPart()
        imagePart.name = "file"
        imagePart.filename = "\(fileName).jpg"
        imagePart.contentType = "image/jpeg"
        imagePart.data = self.data(
            forUploadedImage: image,
            compressionQuality: compressionQuality,
            purpose: purpose
        )

        let ownedByPart: STPMultipartFormDataPart? = ownedBy?.data(using: .utf8).map { ownedByData in
            let part = STPMultipartFormDataPart()
            part.name = "owned_by"
            part.data = ownedByData
            return part
        }

        let boundary = STPMultipartFormDataEncoder.generateBoundary()
        let parts = [purposePart, ownedByPart, imagePart].compactMap { $0 }
        let data = STPMultipartFormDataEncoder.multipartFormData(
            for: parts,
            boundary: boundary
        )

        var request = configuredRequest(
            for: URL(string: FileUploadURL)!,
            using: ephemeralKeySecret
        )
        request.httpMethod = HTTPMethod.post.rawValue
        request.stp_setMultipartForm(data, boundary: boundary)

        let requestStartTime = Date()
        sendRequest(
            request: request,
            completion: { (result: Result<StripeFile, Error>) in
                let timeToUpload = Date().timeIntervalSince(requestStartTime)
                completion(
                    result.map {
                        (
                            file: $0,
                            metrics: .init(
                                timeToUpload: timeToUpload,
                                fileSizeBytes: imagePart.data?.count ?? 0
                            )
                        )
                    }
                )
            }
        )
    }

    /// Uses the Stripe file upload API to upload a JPEG encoded image.
    ///
    /// The image will be automatically resized down if:
    /// 1. The given purpose is recognized by the client.
    /// 2. It's larger than the maximum allowed file size for the given purpose.
    ///
    /// - Parameters:
    ///   - image: The image to be uploaded.
    ///   - compressionQuality: The compression quality to use when encoding the jpeg.
    ///   - purpose: The purpose of this file.
    ///   - fileName: The name of the uploaded file. The "jpeg" extension will
    ///     automatically be appended to this name.
    ///   - ownedBy: A Stripe-internal property that sets the owner of the file.
    ///   - ephemeralKeySecret: Authorization key, if applicable.
    ///
    /// - Returns: A promise that resolves to a Stripe file, if successful, or an
    ///   error that may have occurred.
    ///
    /// - Note:
    ///   The provided `purpose` must match a supported Purpose by our API or the
    ///   API will return an error. Generally, this should match a value in
    ///   `StripeFile.Purpose`, but can be specified by any string for instances
    ///   where a Stripe endpoint needs to specify a newer purpose that the client
    ///   SDK does not recognize.
    @_spi(STP) public func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat = UIImage.defaultCompressionQuality,
        purpose: String,
        fileName: String = defaultImageFileName,
        ownedBy: String? = nil,
        ephemeralKeySecret: String? = nil
    ) -> Future<StripeFile> {
        return uploadImageAndGetMetrics(
            image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: ownedBy,
            ephemeralKeySecret: ephemeralKeySecret
        ).chained { Promise(value: $0.file) }
    }

    @_spi(STP) public func uploadImageAndGetMetrics(
        _ image: UIImage,
        compressionQuality: CGFloat = UIImage.defaultCompressionQuality,
        purpose: String,
        fileName: String = defaultImageFileName,
        ownedBy: String? = nil,
        ephemeralKeySecret: String? = nil
    ) -> Future<FileAndUploadMetrics> {
        let promise = Promise<FileAndUploadMetrics>()
        uploadImageAndGetMetrics(
            image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: ownedBy,
            ephemeralKeySecret: ephemeralKeySecret
        ) { result in
            promise.fullfill(with: result)
        }
        return promise
    }

}

private let FileUploadURL = "https://uploads.stripe.com/v1/files"

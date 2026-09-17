//
//  STPAPIClient+FileUpload.swift
//  StripeCore
//
//  Created by Mel Ludowise on 11/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

extension StripeFile.Purpose {
    /// See max purpose sizes https://stripe.com/docs/file-upload.
    var maxBytes: Int? {
        switch self {
        case .identityDocument,
            .identityPrivate:
            return 16_000_000
        case .disputeEvidence:
            return 5_000_000
        case .cryptoOnrampKYCDocument,
             .unparsable:
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
    /// - Returns: A promise that resolves to a Stripe file and upload metrics, if successful, or an
    ///   error that may have occurred.
    ///
    /// - Note:
    ///   The provided `purpose` must match a supported Purpose by our API or the
    ///   API will return an error. Generally, this should match a value in
    ///   `StripeFile.Purpose`, but can be specified by any string for instances
    ///   where a Stripe endpoint needs to specify a newer purpose that the client
    ///   SDK does not recognize.
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

    /// Errors returned by `uploadFile`.
    @_spi(STP) public enum FileUploadError: Error {

        /// The authorization secret is empty.
        case missingAuthorizationSecret

        /// The URL does not reference a local file.
        case invalidFileURL

        /// The filename could not be encoded for the multipart header.
        case invalidFilename

        /// Reading the local file failed.
        case fileReadFailed(underlying: Error)

        /// The upload was canceled.
        case cancelled

        /// The upload failed before receiving a response.
        case networkFailed(underlying: Error)

        /// Stripe returned an API error.
        case apiError(StripeAPIError)

        /// The response could not be decoded as a file or Stripe API error.
        case invalidResponse(statusCode: Int?, underlying: Error)
    }

    /// Uploads an unchanged local file, inferring its MIME type from the filename.
    /// - Parameters:
    ///   - fileURL: A local file that remains available until this operation completes.
    ///   - purpose: The Files API purpose.
    ///   - authorizationSecret: The credential authorizing ownership of the uploaded file.
    ///   - progress: Upload progress from zero to one, delivered on the session's delegate queue.
    /// - Returns: The uploaded Stripe file. Canceling the calling task cancels the upload.
    /// - Throws: `FileUploadError` for all failures, including cancellation.
    @_spi(STP) public func uploadFile(
        at fileURL: URL,
        purpose: String,
        authorizationSecret: String,
        progress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws -> StripeFile {
        guard !authorizationSecret.isEmpty else {
            throw FileUploadError.missingAuthorizationSecret
        }
        guard fileURL.isFileURL else { throw FileUploadError.invalidFileURL }
        guard !Task.isCancelled else { throw FileUploadError.cancelled }

        guard let filename = fileURL.lastPathComponent.addingPercentEncoding(
            withAllowedCharacters: CharacterSet(charactersIn: "\r\n\"\\").inverted
        ) else {
            throw FileUploadError.invalidFilename
        }

        let purposePart = STPMultipartFormDataPart()
        purposePart.name = "purpose"
        purposePart.data = Data(purpose.utf8)
        let filePart = STPMultipartFormDataPart()
        filePart.name = "file"
        filePart.filename = filename
        filePart.contentType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        do {
            filePart.data = try Data(contentsOf: fileURL)
        } catch {
            throw FileUploadError.fileReadFailed(underlying: error)
        }
        let boundary = STPMultipartFormDataEncoder.generateBoundary()
        let body = STPMultipartFormDataEncoder.multipartFormData(for: [purposePart, filePart], boundary: boundary)

        var request = configuredRequest(for: URL(string: FileUploadURL)!, using: authorizationSecret)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let delegate = STPFileUploadProgressDelegate(progress: progress)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.stp_performUploadTask(with: request, from: body, delegate: delegate)
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw FileUploadError.cancelled
            }
            throw FileUploadError.networkFailed(underlying: error)
        }
        guard !Task.isCancelled else { throw FileUploadError.cancelled }
        do {
            return try Self.decodeResponse(data: data, error: nil, response: response, request: request).get()
        } catch StripeError.apiError(let apiError) {
            throw FileUploadError.apiError(apiError)
        } catch {
            throw FileUploadError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode, underlying: error)
        }
    }

}

private let FileUploadURL = "https://uploads.stripe.com/v1/files"

private final class STPFileUploadProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let progress: @Sendable (Double) -> Void

    init(progress: @escaping @Sendable (Double) -> Void) {
        self.progress = progress
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        // Reports cumulative bytes sent as a fraction of the full multipart request body.
        // Clamp to 0...1 so progress stays between 0% and 100%.
        progress(min(1, max(0, Double(totalBytesSent) / Double(totalBytesExpectedToSend))))
    }
}

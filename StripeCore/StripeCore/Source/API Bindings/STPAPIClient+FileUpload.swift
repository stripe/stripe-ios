//
//  STPAPIClient+FileUpload.swift
//  StripeCore
//
//  Created by Mel Ludowise on 11/9/21.
//

import Foundation
import UIKit

/// STPAPIClient extensions to upload files.
extension STPAPIClient {
    func data(
        forUploadedImage image: UIImage,
        purpose: StripeFile.Purpose
    ) -> Data {

        var maxBytes: Int = 0
        switch purpose {
        case .identityDocument:
            maxBytes = 4 * 1_000_000
        case .disputeEvidence:
            maxBytes = 8 * 1_000_000
        case .unparsable:
            maxBytes = 0
        }
        return image.stp_jpegData(withMaxFileSize: maxBytes)
    }

    /// Uses the Stripe file upload API to upload an image. This can be used for
    /// identity verification and evidence disputes.
    /// - Parameters:
    ///   - image: The image to be uploaded. The maximum allowed file size is 4MB
    /// for identity documents and 8MB for evidence disputes. Cannot be nil.
    /// Your image will be automatically resized down if you pass in one that
    /// is too large
    ///   - purpose: The purpose of this file. This can be either an identifing
    /// document or an evidence dispute.
    ///   - completion: The callback to run with the returned Stripe file
    /// (and any errors that may have occurred).
    /// - seealso: https://stripe.com/docs/file-upload
    @_spi(STP) public func uploadImage(
        _ image: UIImage,
        purpose: StripeFile.Purpose,
        completion: @escaping (Result<StripeFile, Error>) -> Void
    ) {

        let purposePart = STPMultipartFormDataPart()
        purposePart.name = "purpose"
        if let purposeData = purpose.rawValue.data(using: .utf8)
        {
            purposePart.data = purposeData
        }

        let imagePart = STPMultipartFormDataPart()
        imagePart.name = "file"
        imagePart.filename = "image.jpg"
        imagePart.contentType = "image/jpeg"

        imagePart.data = self.data(
            forUploadedImage: image,
            purpose: purpose)

        let boundary = STPMultipartFormDataEncoder.generateBoundary()
        let data = STPMultipartFormDataEncoder.multipartFormData(
            for: [purposePart, imagePart], boundary: boundary)

        var request = configuredRequest(for: URL(string: FileUploadURL)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.stp_setMultipartForm(data, boundary: boundary)

        sendRequest(request: request, completion: completion)
    }

    @_spi(STP) public func uploadImage(
        _ image: UIImage,
        purpose: StripeFile.Purpose
    ) -> Promise<StripeFile> {
        let promise = Promise<StripeFile>()
        uploadImage(image, purpose: purpose) { result in
            promise.fullfill(with: result)
        }
        return promise
    }
}

private let FileUploadURL = "https://uploads.stripe.com/v1/files"

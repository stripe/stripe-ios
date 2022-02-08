//
//  DocumentUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/8/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol DocumentUploaderDelegate: AnyObject {
    func documentUploaderDidUpdateStatus(_ documentUploader: DocumentUploader)
}

protocol DocumentUploaderProtocol: AnyObject {

    /// Tuple of front and back document file data
    typealias CombinedFileData = (
        front: VerificationPageDataDocumentFileData?,
        back: VerificationPageDataDocumentFileData?
    )

    var delegate: DocumentUploaderDelegate? { get set }

    var frontUploadStatus: DocumentUploader.UploadStatus { get }
    var backUploadStatus: DocumentUploader.UploadStatus { get }

    var frontBackUploadFuture: Future<CombinedFileData> { get }

    func uploadImages(
        for side: DocumentUploader.DocumentSide,
        originalImage: CIImage,
        documentBounds: CGRect?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    )
}

final class DocumentUploader: DocumentUploaderProtocol {

    enum DocumentSide: String {
        case front
        case back
    }

    enum UploadStatus {
        case notStarted
        case inProgress
        case complete
        case error(Error)
    }

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

    weak var delegate: DocumentUploaderDelegate?

    /// Determines padding, compression, and scaling of images uploaded to the server
    let configuration: Configuration

    let apiClient: IdentityAPIClient
    let verificationSessionId: String
    let ephemeralKeySecret: String

    /// Worker queue to encode the image to jpeg
    let imageEncodingQueue = DispatchQueue(label: "com.stripe.identity.image-encoding")

    /// Future that is fulfilled when front images are uploaded to the server.
    /// Value is nil if upload has not been requested.
    private(set) var frontUploadFuture: Future<VerificationPageDataDocumentFileData>? {
        didSet {
            guard let frontUploadFuture = frontUploadFuture,
                  oldValue !== frontUploadFuture else {
                return
            }
            frontUploadStatus = .inProgress
            frontUploadFuture.observe { [weak self, weak frontUploadFuture] result in
                // Only update `frontUploadStatus` if `frontUploadFuture` has not been reassigned
                guard let self = self,
                      frontUploadFuture === self.frontUploadFuture else {
                    return
                }
                switch result {
                case .success:
                    self.frontUploadStatus = .complete
                case .failure(let error):
                    self.frontUploadStatus = .error(error)
                }
            }
        }
    }

    /// Future that is fulfilled when back images are uploaded to the server.
    /// Value is nil if upload has not been requested.
    private(set) var backUploadFuture: Future<VerificationPageDataDocumentFileData>? {
        didSet {
            guard let backUploadFuture = backUploadFuture,
                  oldValue !== backUploadFuture else {
                return
            }
            backUploadStatus = .inProgress
            backUploadFuture.observe { [weak self, weak backUploadFuture] result in
                // Only update `backUploadStatus` if `backUploadFuture` has not been reassigned
                guard let self = self,
                      backUploadFuture === self.backUploadFuture else {
                    return
                }
                switch result {
                case .success:
                    self.backUploadStatus = .complete
                case .failure(let error):
                    self.backUploadStatus = .error(error)
                }
            }
        }
    }

    /// Status of whether the front images have finished uploading
    private(set) var frontUploadStatus: UploadStatus = .notStarted {
        didSet {
            delegate?.documentUploaderDidUpdateStatus(self)
        }
    }
    /// Status of whether the back images have finished uploading
    private(set) var backUploadStatus: UploadStatus = .notStarted {
        didSet {
            delegate?.documentUploaderDidUpdateStatus(self)
        }
    }

    /// Combined future that returns a tuple of front & back uploads
    var frontBackUploadFuture: Future<CombinedFileData> {
        // Unwrap futures by converting
        // from Future<VerificationPageDataDocumentFileData>?
        // to Future<VerificationPageDataDocumentFileData?>
        let unwrappedFrontUploadFuture: Future<VerificationPageDataDocumentFileData?> = frontUploadFuture?.chained { Promise(value: $0) } ?? Promise(value: nil)
        let unwrappedBackUploadFuture: Future<VerificationPageDataDocumentFileData?> = backUploadFuture?.chained { Promise(value: $0) } ?? Promise(value: nil)

        return unwrappedFrontUploadFuture.chained { frontData in
            return unwrappedBackUploadFuture.chained { Promise(value: (front: frontData, back: $0)) }
        }
    }

    init(
        configuration: Configuration,
        apiClient: IdentityAPIClient,
        verificationSessionId: String,
        ephemeralKeySecret: String
    ) {
        self.configuration = configuration
        self.apiClient = apiClient
        self.verificationSessionId = verificationSessionId
        self.ephemeralKeySecret = ephemeralKeySecret
    }

    /**
     Uploads a high and low resolution image for a specific side of the
     document and updates either `frontUploadFuture` or `backUploadFuture`.
     - Note: If `documentBounds` is non-nil, the high-res image will be
     cropped and an un-cropped image will be uploaded as the low-res image.
     If `documentBounds` is nil, then only a high-res image will be
     uploaded and it will not be cropped.
     - Parameters:
       - side: The side of the image (front or back) to upload.
       - originalImage: The original image captured or uploaded by the user.
       - documentBounds: The bounds of the document detected during auto-capture.
       - method: The method the image was obtained.
     */
    func uploadImages(
        for side: DocumentSide,
        originalImage: CIImage,
        documentBounds: CGRect?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        let uploadFuture = uploadImages(
            originalImage,
            documentBounds: documentBounds,
            method: method,
            fileNamePrefix: "\(verificationSessionId)_\(side.rawValue)"
        )

        switch side {
        case .front:
            self.frontUploadFuture = uploadFuture
        case .back:
            self.backUploadFuture = uploadFuture
        }
    }

    /// Uploads both a high and low resolution image
    func uploadImages(
        _ originalImage: CIImage,
        documentBounds: CGRect?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod,
        fileNamePrefix: String
    ) -> Future<VerificationPageDataDocumentFileData> {
        // Only upload a full frame image if the user uploaded image will be cropped
        let lowResUploadFuture: Future<StripeFile?> = (documentBounds == nil)
            ? Promise(value: nil)
            : uploadLowResImage(
                originalImage,
                fileNamePrefix: fileNamePrefix
            ).chained { Promise(value: $0) }

        return uploadHighResImage(
            originalImage,
            regionOfInterest: documentBounds,
            fileNamePrefix: fileNamePrefix
        ).chained { highResFile in
            return lowResUploadFuture.chained { lowResFile in
                // Convert promise to a tuple of file IDs
                return Promise(value: (
                    lowRes: lowResFile?.id,
                    highRes: highResFile.id
                ))
            }
        }.chained { lowRes, highRes in
            // TODO(mludowise|IDPROD-3224): Add ML scores to API model
            return Promise(value: .init(
                backScore: nil,
                frontCardScore: nil,
                highResImage: highRes,
                invalidScore: nil,
                lowResImage: lowRes,
                noDocumentScore: nil,
                passportScore: nil,
                uploadMethod: method,
                _additionalParametersStorage: nil
            ))
        }
    }

    /// Crops, resizes, and uploads the high resolution image to the server
    func uploadHighResImage(
        _ image: CIImage,
        regionOfInterest: CGRect?,
        fileNamePrefix: String
    ) -> Future<StripeFile> {
        // Crop image if there's a region of interest
        var imageToResize = image
        if let regionOfInterest = regionOfInterest {
            imageToResize = image.cropped(
                toInvertedNormalizedRegion: regionOfInterest,
                withPadding: configuration.highResImageCropPadding
            )
        }

        return uploadJPEG(
            image: imageToResize.scaledDown(toMaxPixelDimension: CGSize(
                width: configuration.highResImageMaxDimension,
                height: configuration.highResImageMaxDimension
            )),
            fileName: fileNamePrefix,
            jpegCompressionQuality: configuration.highResImageCompressionQuality
        )
    }

    /// Resizes and uploads the low resolution image to the server
    func uploadLowResImage(
        _ image: CIImage,
        fileNamePrefix: String
    ) -> Future<StripeFile> {
        return uploadJPEG(
            image: image.scaledDown(toMaxPixelDimension: CGSize(
                width: configuration.lowResImageMaxDimension,
                height: configuration.lowResImageMaxDimension
            )),
            fileName: "\(fileNamePrefix)_full_frame",
            jpegCompressionQuality: configuration.lowResImageCompressionQuality
        )
    }

    /// Converts image to JPEG data and uploads it to the server on a worker thread
    func uploadJPEG(
        image: CIImage,
        fileName: String,
        jpegCompressionQuality: CGFloat
    ) -> Future<StripeFile> {
        let promise = Promise<StripeFile>()
        imageEncodingQueue.async { [weak self] in
            guard let self = self else { return }

            let uiImage = UIImage(ciImage: image)
            self.apiClient.uploadImage(
                uiImage,
                compressionQuality: jpegCompressionQuality,
                purpose: self.configuration.filePurpose,
                fileName: fileName,
                ownedBy: self.verificationSessionId,
                ephemeralKeySecret: self.ephemeralKeySecret
            ).observe { result in
                promise.fullfill(with: result)
            }
        }
        return promise
    }
}

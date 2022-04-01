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
        for side: DocumentSide,
        originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    )

    func reset()
}

enum DocumentUploaderError: AnalyticLoggableError {
    case unableToCrop
    case unableToResize

    func serializeForLogging() -> [String : Any] {
        // TODO(mludowise|IDPROD-2816): Log error
        return [:]
    }
}

final class DocumentUploader: DocumentUploaderProtocol {

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

    /// Worker queue to encode the image to jpeg
    let imageEncodingQueue = DispatchQueue(label: "com.stripe.identity.image-encoding")

    /// Future that is fulfilled when front images are uploaded to the server.
    /// Value is nil if upload has not been requested.
    private(set) var frontUploadFuture: Future<VerificationPageDataDocumentFileData>? {
        didSet {
            guard oldValue !== frontUploadFuture else {
                return
            }
            frontUploadStatus = (frontUploadFuture == nil) ? .notStarted : .inProgress
            frontUploadFuture?.observe { [weak self, weak frontUploadFuture] result in
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
            guard oldValue !== backUploadFuture else {
                return
            }
            backUploadStatus = (backUploadFuture == nil) ? .notStarted : .inProgress
            backUploadFuture?.observe { [weak self, weak backUploadFuture] result in
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
        apiClient: IdentityAPIClient
    ) {
        self.configuration = configuration
        self.apiClient = apiClient
    }

    /**
     Uploads a high and low resolution image for a specific side of the
     document and updates either `frontUploadFuture` or `backUploadFuture`.
     - Note: If `idDetectorOutput` is non-nil, the high-res image will be
     cropped and an un-cropped image will be uploaded as the low-res image.
     If `idDetectorOutput` is nil, then only a high-res image will be
     uploaded and it will not be cropped.
     - Parameters:
       - side: The side of the image (front or back) to upload.
       - originalImage: The original image captured or uploaded by the user.
       - idDetectorOutput: The output from the IDDetector model
       - method: The method the image was obtained.
     */
    func uploadImages(
        for side: DocumentSide,
        originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        let uploadFuture = uploadImages(
            originalImage,
            documentScannerOutput: documentScannerOutput,
            method: method,
            fileNamePrefix: "\(apiClient.verificationSessionId)_\(side.rawValue)"
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
        _ originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        method: VerificationPageDataDocumentFileData.FileUploadMethod,
        fileNamePrefix: String
    ) -> Future<VerificationPageDataDocumentFileData> {
        // Only upload a low res image if the high res image will be cropped
        let lowResUploadFuture: Future<StripeFile?> = (documentScannerOutput == nil)
            ? Promise(value: nil)
            : uploadLowResImage(
                originalImage,
                fileNamePrefix: fileNamePrefix
            ).chained { Promise(value: $0) }

        return uploadHighResImage(
            originalImage,
            regionOfInterest: documentScannerOutput?.idDetectorOutput.documentBounds,
            fileNamePrefix: fileNamePrefix
        ).chained { highResFile in
            return lowResUploadFuture.chained { lowResFile in
                // Convert promise to a tuple of file IDs
                return Promise(value: (
                    lowRes: lowResFile?.id,
                    highRes: highResFile.id
                ))
            }
        }.chained { (lowRes, highRes) -> Future<VerificationPageDataDocumentFileData> in
            return Promise(value: VerificationPageDataDocumentFileData(
                documentScannerOutput: documentScannerOutput,
                highResImage: highRes,
                lowResImage: lowRes,
                uploadMethod: method
            ))
        }
    }

    /// Crops, resizes, and uploads the high resolution image to the server
    func uploadHighResImage(
        _ image: CGImage,
        regionOfInterest: CGRect?,
        fileNamePrefix: String
    ) -> Future<StripeFile> {
        // Crop image if there's a region of interest
        var imageToResize = image
        if let regionOfInterest = regionOfInterest {
            guard let croppedImage = image.cropping(
                toNormalizedRegion: regionOfInterest,
                withPadding: configuration.highResImageCropPadding
            ) else {
                return Promise(error: DocumentUploaderError.unableToCrop)
            }
            imageToResize = croppedImage
        }

        guard let resizedImage = imageToResize.scaledDown(toMaxPixelDimension: CGSize(
            width: configuration.highResImageMaxDimension,
            height: configuration.highResImageMaxDimension
        )) else {
            return Promise(error: DocumentUploaderError.unableToResize)
        }

        return uploadJPEG(
            image: resizedImage,
            fileName: fileNamePrefix,
            jpegCompressionQuality: configuration.highResImageCompressionQuality
        )
    }

    /// Resizes and uploads the low resolution image to the server
    func uploadLowResImage(
        _ image: CGImage,
        fileNamePrefix: String
    ) -> Future<StripeFile> {
        guard let resizedImage = image.scaledDown(toMaxPixelDimension: CGSize(
            width: configuration.lowResImageMaxDimension,
            height: configuration.lowResImageMaxDimension
        )) else {
            return Promise(error: DocumentUploaderError.unableToResize)
        }

        return uploadJPEG(
            image: resizedImage,
            fileName: "\(fileNamePrefix)_full_frame",
            jpegCompressionQuality: configuration.lowResImageCompressionQuality
        )
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
            ).observe { result in
                promise.fullfill(with: result)
            }
        }
        return promise
    }

    /// Resets the status of the uploader
    func reset() {
        frontUploadFuture = nil
        backUploadFuture = nil
    }
}

//
//  DocumentUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit

protocol DocumentUploaderDelegate: AnyObject {
    func documentUploaderDidUpdateStatus(_ documentUploader: DocumentUploader)

    func documentUploaderDidUploadFront(_ documentUploader: DocumentUploaderProtocol)

    func documentUploaderDidUploadBack(_ documentUploader: DocumentUploaderProtocol)
}

protocol DocumentUploaderProtocol: AnyObject {

    /// Tuple of front and back document file data
    typealias CombinedFileData = (
        front: StripeAPI.VerificationPageDataDocumentFileData?,
        back: StripeAPI.VerificationPageDataDocumentFileData?
    )

    var delegate: DocumentUploaderDelegate? { get set }

    var frontUploadStatus: DocumentUploader.UploadStatus { get }
    var backUploadStatus: DocumentUploader.UploadStatus { get }

    func frontUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    func backUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?

    func uploadImages(
        for side: DocumentSide,
        originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        exifMetadata: CameraExifMetadata?,
        method: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod
    )

    func reset()
}

final class DocumentUploader: DocumentUploaderProtocol {

    enum UploadStatus {
        case notStarted
        case inProgress
        case complete
        case error(Error)
    }

    weak var delegate: DocumentUploaderDelegate?

    let imageUploader: IdentityImageUploader

    private var frontUploadGeneration = 0

    /// Task that is fulfilled when front images are uploaded to the server.
    /// Value is nil if upload has not been requested.
    private var frontUploadTask: Task<StripeAPI.VerificationPageDataDocumentFileData, Error>?

    private var backUploadGeneration = 0

    /// Task that is fulfilled when back images are uploaded to the server.
    /// Value is nil if upload has not been requested.
    private var backUploadTask: Task<StripeAPI.VerificationPageDataDocumentFileData, Error>?

    /// Status of whether the front images have finished uploading
    private(set) var frontUploadStatus: UploadStatus = .notStarted {
        didSet {
            delegate?.documentUploaderDidUpdateStatus(self)

            if case .complete = frontUploadStatus {
                delegate?.documentUploaderDidUploadFront(self)
            }
        }
    }
    /// Status of whether the back images have finished uploading
    private(set) var backUploadStatus: UploadStatus = .notStarted {
        didSet {
            delegate?.documentUploaderDidUpdateStatus(self)

            if case .complete = backUploadStatus {
                delegate?.documentUploaderDidUploadBack(self)
            }
        }
    }

    init(
        imageUploader: IdentityImageUploader
    ) {
        self.imageUploader = imageUploader
    }

    func frontUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>? {
        guard let frontUploadTask else {
            return nil
        }
        return await frontUploadTask.result
    }

    func backUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>? {
        guard let backUploadTask else {
            return nil
        }
        return await backUploadTask.result
    }

    /// Uploads a high and low resolution image for a specific side of the
    /// document and updates either `frontUploadTask` or `backUploadTask`.
    /// - Note: If `idDetectorOutput` is non-nil, the high-res image will be
    /// cropped and an un-cropped image will be uploaded as the low-res image.
    /// If `idDetectorOutput` is nil, then only a high-res image will be
    /// uploaded and it will not be cropped.
    /// - Parameters:
    ///   - side: The side of the image (front or back) to upload.
    ///   - originalImage: The original image captured or uploaded by the user.
    ///   - documentScannerOutput: The output from the DocumentScanner.
    ///   - method: The method the image was obtained.
    func uploadImages(
        for side: DocumentSide,
        originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        exifMetadata: CameraExifMetadata?,
        method: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        let uploadTask = Task {
            try await self.uploadImages(
                originalImage,
                documentScannerOutput: documentScannerOutput,
                exifMetadata: exifMetadata,
                method: method,
                fileNamePrefix: "\(self.imageUploader.apiClient.verificationSessionId)_\(side.rawValue)"
            )
        }

        switch side {
        case .front:
            setFrontUploadTask(uploadTask)
        case .back:
            setBackUploadTask(uploadTask)
        }
    }

    /// Uploads both a high and low resolution image
    func uploadImages(
        _ originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        exifMetadata: CameraExifMetadata?,
        method: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod,
        fileNamePrefix: String
    ) async throws -> StripeAPI.VerificationPageDataDocumentFileData {

        // Only upload a low res image if the high res image will be cropped
        if let documentBounds = documentScannerOutput?.idDetectorOutput.documentBounds {
            let (lowResFile, highResFile) = try await imageUploader.uploadLowAndHighResImages(
                originalImage,
                highResRegionOfInterest: documentBounds,
                cropPaddingComputationMethod: .maxImageWidthOrHeight,
                lowResFileName: "\(fileNamePrefix)_full_frame",
                highResFileName: fileNamePrefix
            )
            return StripeAPI.VerificationPageDataDocumentFileData(
                documentScannerOutput: documentScannerOutput,
                highResImage: highResFile.id,
                lowResImage: lowResFile.id,
                exifMetadata: exifMetadata,
                uploadMethod: method
            )
        } else {
            let highResFile = try await imageUploader.uploadHighResImage(
                originalImage,
                regionOfInterest: nil,
                cropPaddingComputationMethod: .maxImageWidthOrHeight,
                fileName: fileNamePrefix
            )
            return StripeAPI.VerificationPageDataDocumentFileData(
                documentScannerOutput: documentScannerOutput,
                highResImage: highResFile.id,
                lowResImage: nil,
                exifMetadata: exifMetadata,
                uploadMethod: method
            )
        }
    }

    /// Resets the status of the uploader
    func reset() {
        setFrontUploadTask(nil)
        setBackUploadTask(nil)
    }
}

private extension DocumentUploader {
    func setFrontUploadTask(
        _ uploadTask: Task<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    ) {
        frontUploadGeneration += 1
        let generation = frontUploadGeneration

        guard let uploadTask else {
            frontUploadTask = nil
            frontUploadStatus = .notStarted
            return
        }

        frontUploadStatus = .inProgress
        frontUploadTask = Task { @MainActor [weak self] in
            do {
                let value = try await uploadTask.value
                guard generation == self?.frontUploadGeneration else {
                    return value
                }
                self?.frontUploadStatus = .complete
                return value
            } catch {
                guard generation == self?.frontUploadGeneration else {
                    throw error
                }
                self?.frontUploadStatus = .error(error)
                throw error
            }
        }
    }

    func setBackUploadTask(
        _ uploadTask: Task<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    ) {
        backUploadGeneration += 1
        let generation = backUploadGeneration

        guard let uploadTask else {
            backUploadTask = nil
            backUploadStatus = .notStarted
            return
        }

        backUploadStatus = .inProgress
        backUploadTask = Task { @MainActor [weak self] in
            do {
                let value = try await uploadTask.value
                guard generation == self?.backUploadGeneration else {
                    return value
                }
                self?.backUploadStatus = .complete
                return value
            } catch {
                guard generation == self?.backUploadGeneration else {
                    throw error
                }
                self?.backUploadStatus = .error(error)
                throw error
            }
        }
    }
}

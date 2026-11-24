//
//  DocumentUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore
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

    // Main actor, because `uploadImages` and `reset` replace the upload tasks on the main thread.
    @MainActor func frontUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    @MainActor func backUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?

    /// If the last upload of `side` failed, waits for the files still uploading, then starts again
    /// only the files that failed.
    @MainActor func retryFailedUploads(for side: DocumentSide) async

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
    let isTestMode: Bool

    private var frontUploadGeneration = 0

    /// The file uploads of the front images. Value is nil if upload has not been requested, or
    /// after it succeeded.
    private var frontUpload: SideUpload?

    /// Task that is fulfilled when front images are uploaded to the server.
    /// Value is nil if upload has not been requested.
    private var frontUploadTask: Task<StripeAPI.VerificationPageDataDocumentFileData, Error>?

    private var backUploadGeneration = 0

    /// The file uploads of the back images. Value is nil if upload has not been requested, or
    /// after it succeeded.
    private var backUpload: SideUpload?

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
        imageUploader: IdentityImageUploader,
        isTestMode: Bool = false
    ) {
        self.imageUploader = imageUploader
        self.isTestMode = isTestMode
    }

    @MainActor func frontUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>? {
        guard let frontUploadTask else {
            return nil
        }
        return await frontUploadTask.result
    }

    @MainActor func backUploadResult() async -> Result<StripeAPI.VerificationPageDataDocumentFileData, Error>? {
        guard let backUploadTask else {
            return nil
        }
        return await backUploadTask.result
    }

    /// Uploads a high and low resolution image for a specific side of the
    /// document and updates either `frontUploadTask` or `backUploadTask`.
    /// - Note: If `idDetectorOutput` is non-nil, high- and low-resolution images
    /// are uploaded. In live mode, the high-resolution image is cropped. If
    /// `idDetectorOutput` is nil, only an uncropped high-resolution image is uploaded.
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
        let upload = makeSideUpload(
            for: side,
            originalImage: originalImage,
            documentScannerOutput: documentScannerOutput,
            exifMetadata: exifMetadata,
            method: method
        )

        switch side {
        case .front:
            frontUpload = upload
            setFrontUploadTask(Task { try await upload.result() })
        case .back:
            backUpload = upload
            setBackUploadTask(Task { try await upload.result() })
        }
    }

    @MainActor func retryFailedUploads(for side: DocumentSide) async {
        switch side {
        case .front:
            guard case .error = frontUploadStatus, let frontUpload else {
                return
            }
            let generation = frontUploadGeneration
            let failedFiles = await frontUpload.failedFiles()
            guard generation == frontUploadGeneration else {
                return
            }
            failedFiles.forEach { $0.restart() }
            setFrontUploadTask(Task { try await frontUpload.result() })
        case .back:
            guard case .error = backUploadStatus, let backUpload else {
                return
            }
            let generation = backUploadGeneration
            let failedFiles = await backUpload.failedFiles()
            guard generation == backUploadGeneration else {
                return
            }
            failedFiles.forEach { $0.restart() }
            setBackUploadTask(Task { try await backUpload.result() })
        }
    }

    /// Resets the status of the uploader
    func reset() {
        frontUpload = nil
        backUpload = nil
        setFrontUploadTask(nil)
        setBackUploadTask(nil)
    }
}

/// The file uploads for one side of the document.
private struct SideUpload {
    let highRes: RetryableUpload<StripeFile>
    let lowRes: RetryableUpload<StripeFile>?
    let makeFileData: (_ highRes: StripeFile, _ lowRes: StripeFile?) -> StripeAPI.VerificationPageDataDocumentFileData

    @MainActor func result() async throws -> StripeAPI.VerificationPageDataDocumentFileData {
        let highResFile = try await highRes.task.value
        let lowResFile = try await lowRes?.task.value
        return makeFileData(highResFile, lowResFile)
    }

    @MainActor func failedFiles() async -> [RetryableUpload<StripeFile>] {
        await RetryableUpload.failed([highRes, lowRes])
    }
}

private extension DocumentUploader {
    func makeSideUpload(
        for side: DocumentSide,
        originalImage: CGImage,
        documentScannerOutput: DocumentScannerOutput?,
        exifMetadata: CameraExifMetadata?,
        method: StripeAPI.VerificationPageDataDocumentFileData.FileUploadMethod
    ) -> SideUpload {
        let imageUploader = imageUploader
        let isTestMode = isTestMode
        let fileNamePrefix = "\(imageUploader.apiClient.verificationSessionId)_\(side.rawValue)"
        let documentBounds = documentScannerOutput?.idDetectorOutput.documentBounds
        let imageToUpload = {
            isTestMode ? try side.testModeImage.makeCGImage() : originalImage
        }

        let highRes = RetryableUpload {
            try await imageUploader.uploadHighResImage(
                imageToUpload(),
                regionOfInterest: isTestMode ? nil : documentBounds,
                cropPaddingComputationMethod: .maxImageWidthOrHeight,
                fileName: fileNamePrefix
            )
        }
        // Only upload a low-res image when document bounds are available.
        let lowRes = documentBounds == nil ? nil : RetryableUpload {
            try await imageUploader.uploadLowResImage(
                imageToUpload(),
                fileName: "\(fileNamePrefix)_full_frame"
            )
        }

        return SideUpload(highRes: highRes, lowRes: lowRes) { highResFile, lowResFile in
            StripeAPI.VerificationPageDataDocumentFileData(
                documentScannerOutput: documentScannerOutput,
                highResImage: highResFile.id,
                lowResImage: lowResFile?.id,
                exifMetadata: exifMetadata,
                uploadMethod: method
            )
        }
    }

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
                // Only a failed upload needs its images kept for a retry.
                self?.frontUpload = nil
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
                // Only a failed upload needs its images kept for a retry.
                self?.backUpload = nil
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

private extension DocumentSide {
    var testModeImage: TestModeImage {
        switch self {
        case .front:
            return .documentFront
        case .back:
            return .documentBack
        }
    }
}

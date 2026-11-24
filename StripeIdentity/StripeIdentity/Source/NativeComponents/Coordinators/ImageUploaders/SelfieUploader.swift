//
//  SelfieUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/// Dependency-injectable protocol for SelfieUploader
protocol SelfieUploaderProtocol: AnyObject {
    // Main actor, because `uploadImages` and `reset` replace the upload task on the main thread.
    @MainActor func uploadResult() async -> Result<SelfieUploader.FileData, Error>?

    /// The error of the last upload, if it failed.
    var uploadError: Error? { get }

    /// If the last upload failed, waits for the files still uploading, then starts again only the
    /// files that failed.
    @MainActor func retryFailedUploads() async

    func uploadImages(
        _ capturedImages: FaceCaptureData
    )

    func reset()
}

final class SelfieUploader: SelfieUploaderProtocol {

    struct FileData {
        let bestHighResFile: StripeFile
        let bestLowResFile: StripeFile
        let firstHighResFile: StripeFile
        let firstLowResFile: StripeFile
        let lastHighResFile: StripeFile
        let lastLowResFile: StripeFile
        let leftFullFrameFile: StripeFile?
        let rightFullFrameFile: StripeFile?

        init(
            bestHighResFile: StripeFile,
            bestLowResFile: StripeFile,
            firstHighResFile: StripeFile,
            firstLowResFile: StripeFile,
            lastHighResFile: StripeFile,
            lastLowResFile: StripeFile,
            leftFullFrameFile: StripeFile? = nil,
            rightFullFrameFile: StripeFile? = nil
        ) {
            self.bestHighResFile = bestHighResFile
            self.bestLowResFile = bestLowResFile
            self.firstHighResFile = firstHighResFile
            self.firstLowResFile = firstLowResFile
            self.lastHighResFile = lastHighResFile
            self.lastLowResFile = lastLowResFile
            self.leftFullFrameFile = leftFullFrameFile
            self.rightFullFrameFile = rightFullFrameFile
        }
    }

    let imageUploader: IdentityImageUploader
    let isTestMode: Bool

    private var uploadGeneration = 0

    /// The file uploads of the selfie images. Value is nil if upload has not been requested, or
    /// after it succeeded.
    private var upload: SelfieUpload?

    private var uploadTask: Task<SelfieUploader.FileData, Error>?

    private(set) var uploadError: Error?

    init(
        imageUploader: IdentityImageUploader,
        isTestMode: Bool = false
    ) {
        self.imageUploader = imageUploader
        self.isTestMode = isTestMode
    }

    @MainActor func uploadResult() async -> Result<SelfieUploader.FileData, Error>? {
        guard let uploadTask else {
            return nil
        }
        return await uploadTask.result
    }

    /// Uploads high- and low-resolution front frames and full-frame side captures.
    /// - Parameters:
    ///   - capturedImages: The original images and scanner output for each captured selfie image.
    func uploadImages(
        _ capturedImages: FaceCaptureData
    ) {
        // Start uploading all images in parallel
        let upload = SelfieUpload(
            bestHighRes: highResUpload(capturedImages.bestMiddle, ofType: .best),
            bestLowRes: lowResUpload(capturedImages.bestMiddle, ofType: .best),
            firstHighRes: highResUpload(capturedImages.first, ofType: .first),
            firstLowRes: lowResUpload(capturedImages.first, ofType: .first),
            lastHighRes: highResUpload(capturedImages.last, ofType: .last),
            lastLowRes: lowResUpload(capturedImages.last, ofType: .last),
            leftFullFrame: capturedImages.leftSide.map { fullFrameUpload($0, ofType: .left) },
            rightFullFrame: capturedImages.rightSide.map { fullFrameUpload($0, ofType: .right) }
        )
        self.upload = upload
        setUploadTask(Task { try await upload.result() })
    }

    @MainActor func retryFailedUploads() async {
        guard uploadError != nil, let upload else {
            return
        }
        let generation = uploadGeneration
        let failedFiles = await upload.failedFiles()
        guard generation == uploadGeneration else {
            return
        }
        failedFiles.forEach { $0.restart() }
        setUploadTask(Task { try await upload.result() })
    }

    func reset() {
        upload = nil
        setUploadTask(nil)
    }

    private func setUploadTask(_ uploadTask: Task<SelfieUploader.FileData, Error>?) {
        uploadGeneration += 1
        let generation = uploadGeneration
        uploadError = nil

        guard let uploadTask else {
            self.uploadTask = nil
            return
        }

        self.uploadTask = Task { @MainActor [weak self] in
            do {
                let value = try await uploadTask.value
                if generation == self?.uploadGeneration {
                    // Only a failed upload needs its images kept for a retry.
                    self?.upload = nil
                }
                return value
            } catch {
                if generation == self?.uploadGeneration {
                    self?.uploadError = error
                }
                throw error
            }
        }
    }

    private func highResUpload(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) -> RetryableUpload<StripeFile> {
        let imageUploader = imageUploader
        let isTestMode = isTestMode
        let fileName = SelfieUploader.fileName(
            with: imageUploader.apiClient.verificationSessionId,
            for: type,
            resolution: .high
        )
        return RetryableUpload {
            try await imageUploader.uploadHighResImage(
                isTestMode ? TestModeImage.selfie.makeCGImage() : capturedImage.image,
                regionOfInterest: isTestMode ? nil : capturedImage.scannerOutput.faceRect,
                cropPaddingComputationMethod: .regionWidth,
                fileName: fileName
            )
        }
    }

    private func lowResUpload(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) -> RetryableUpload<StripeFile> {
        let imageUploader = imageUploader
        let isTestMode = isTestMode
        let fileName = SelfieUploader.fileName(
            with: imageUploader.apiClient.verificationSessionId,
            for: type,
            resolution: .low
        )
        return RetryableUpload {
            try await imageUploader.uploadLowResImage(
                isTestMode ? TestModeImage.selfie.makeCGImage() : capturedImage.image,
                fileName: fileName
            )
        }
    }

    private func fullFrameUpload(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) -> RetryableUpload<StripeFile> {
        let imageUploader = imageUploader
        let fileName = SelfieUploader.fileName(
            with: imageUploader.apiClient.verificationSessionId,
            for: type,
            resolution: .low
        )
        return RetryableUpload {
            try await imageUploader.uploadLowResImage(capturedImage.image, fileName: fileName)
        }
    }
}

/// The file uploads for one selfie capture.
private struct SelfieUpload {
    let bestHighRes: RetryableUpload<StripeFile>
    let bestLowRes: RetryableUpload<StripeFile>
    let firstHighRes: RetryableUpload<StripeFile>
    let firstLowRes: RetryableUpload<StripeFile>
    let lastHighRes: RetryableUpload<StripeFile>
    let lastLowRes: RetryableUpload<StripeFile>
    let leftFullFrame: RetryableUpload<StripeFile>?
    let rightFullFrame: RetryableUpload<StripeFile>?

    @MainActor func result() async throws -> SelfieUploader.FileData {
        try await SelfieUploader.FileData(
            bestHighResFile: bestHighRes.task.value,
            bestLowResFile: bestLowRes.task.value,
            firstHighResFile: firstHighRes.task.value,
            firstLowResFile: firstLowRes.task.value,
            lastHighResFile: lastHighRes.task.value,
            lastLowResFile: lastLowRes.task.value,
            leftFullFrameFile: leftFullFrame?.task.value,
            rightFullFrameFile: rightFullFrame?.task.value
        )
    }

    @MainActor func failedFiles() async -> [RetryableUpload<StripeFile>] {
        await RetryableUpload.failed([
            bestHighRes, bestLowRes, firstHighRes, firstLowRes, lastHighRes, lastLowRes,
            leftFullFrame, rightFullFrame,
        ])
    }
}

// MARK: - File Name Helpers

extension SelfieUploader {
    enum ImageType {
        case first, last, best, left, right
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
        case (.left, .high):
            return "face_left_crop_frame"
        case (.left, .low):
            return "face_left_full_frame"
        case (.right, .high):
            return "face_right_crop_frame"
        case (.right, .low):
            return "face_right_full_frame"
        }
    }
}

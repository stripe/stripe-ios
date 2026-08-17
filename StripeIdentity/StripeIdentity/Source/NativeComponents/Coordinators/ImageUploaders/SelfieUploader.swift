//
//  SelfieUploader.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit

/// Dependency-injectable protocol for SelfieUploader
protocol SelfieUploaderProtocol: AnyObject {
    func uploadResult() async -> Result<SelfieUploader.FileData, Error>?

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

    private var uploadTask: Task<SelfieUploader.FileData, Error>?

    init(
        imageUploader: IdentityImageUploader
    ) {
        self.imageUploader = imageUploader
    }

    func uploadResult() async -> Result<SelfieUploader.FileData, Error>? {
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
        uploadTask = Task {
            let bestTask = Task {
                try await uploadImages(capturedImages.bestMiddle, ofType: .best)
            }
            let firstTask = Task {
                try await uploadImages(capturedImages.first, ofType: .first)
            }
            let lastTask = Task {
                try await uploadImages(capturedImages.last, ofType: .last)
            }
            let leftTask = capturedImages.leftSide.map { image in
                Task { try await uploadFullFrameImage(image, ofType: .left) }
            }
            let rightTask = capturedImages.rightSide.map { image in
                Task { try await uploadFullFrameImage(image, ofType: .right) }
            }

            return try await FileData(
                bestHighResFile: bestTask.value.highRes,
                bestLowResFile: bestTask.value.lowRes,
                firstHighResFile: firstTask.value.highRes,
                firstLowResFile: firstTask.value.lowRes,
                lastHighResFile: lastTask.value.highRes,
                lastLowResFile: lastTask.value.lowRes,
                leftFullFrameFile: leftTask?.value,
                rightFullFrameFile: rightTask?.value
            )
        }
    }

    func uploadImages(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) async throws -> IdentityImageUploader.LowHighResFiles {
        try await imageUploader.uploadLowAndHighResImages(
            capturedImage.image,
            highResRegionOfInterest: capturedImage.scannerOutput.faceRect,
            cropPaddingComputationMethod: .regionWidth,
            lowResFileName: SelfieUploader.fileName(
                with: imageUploader.apiClient.verificationSessionId,
                for: type,
                resolution: .low
            ),
            highResFileName: SelfieUploader.fileName(
                with: imageUploader.apiClient.verificationSessionId,
                for: type,
                resolution: .high
            )
        )
    }

    private func uploadFullFrameImage(
        _ capturedImage: FaceScannerInputOutput,
        ofType type: ImageType
    ) async throws -> StripeFile {
        try await imageUploader.uploadLowResImage(
            capturedImage.image,
            fileName: SelfieUploader.fileName(
                with: imageUploader.apiClient.verificationSessionId,
                for: type,
                resolution: .low
            )
        )
    }

    func reset() {
        uploadTask = nil
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

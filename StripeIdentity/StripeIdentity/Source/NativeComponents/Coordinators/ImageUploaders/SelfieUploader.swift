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

    /// Uploads a high and low resolution image for each of the captured images.
    /// - Parameters:
    ///   - capturedImages: The original images and scanner output for each of the 3 captured images.
    func uploadImages(
        _ capturedImages: FaceCaptureData
    ) {
        // Start uploading all 3 images in parallel
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

            return try await FileData(
                bestHighResFile: bestTask.value.highRes,
                bestLowResFile: bestTask.value.lowRes,
                firstHighResFile: firstTask.value.highRes,
                firstLowResFile: firstTask.value.lowRes,
                lastHighResFile: lastTask.value.highRes,
                lastLowResFile: lastTask.value.lowRes
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

    func reset() {
        uploadTask = nil
    }
}

// MARK: - File Name Helpers

extension SelfieUploader {
    enum ImageType {
        case first, last, best
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
        }
    }
}

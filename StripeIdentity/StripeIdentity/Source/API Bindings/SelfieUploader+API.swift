//
//  SelfieUploader+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit

extension IdentityImageUploader.Configuration {
    init(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    ) {
        self.init(
            filePurpose: selfiePageConfig.filePurpose,
            highResImageCompressionQuality: selfiePageConfig.highResImageCompressionQuality,
            highResImageCropPadding: selfiePageConfig.highResImageCropPadding,
            highResImageMaxDimension: selfiePageConfig.highResImageMaxDimension,
            lowResImageCompressionQuality: selfiePageConfig.lowResImageCompressionQuality,
            lowResImageMaxDimension: selfiePageConfig.lowResImageMaxDimension
        )
    }
}

extension StripeAPI.VerificationPageDataFace {
    init(
        uploadedFiles: SelfieUploader.FileData,
        capturedImages: FaceCaptureData,
        bestFrameExifMetadata: CameraExifMetadata?,
        trainingConsent: Bool
    ) {
        self.init(
            bestHighResImage: uploadedFiles.bestHighResFile.id,
            bestLowResImage: uploadedFiles.bestLowResFile.id,
            firstHighResImage: uploadedFiles.firstHighResFile.id,
            firstLowResImage: uploadedFiles.firstLowResFile.id,
            lastHighResImage: uploadedFiles.lastHighResFile.id,
            lastLowResImage: uploadedFiles.lastLowResFile.id,
            leftHighResImage: uploadedFiles.leftHighResFile?.id,
            leftLowResImage: uploadedFiles.leftLowResFile?.id,
            rightHighResImage: uploadedFiles.rightHighResFile?.id,
            rightLowResImage: uploadedFiles.rightLowResFile?.id,
            bestFaceScore: .init(capturedImages.bestMiddle.scannerOutput.faceScore),
            faceScoreVariance: .init(capturedImages.faceScoreVariance),
            numFrames: capturedImages.numSamples,
            bestBrightnessValue: bestFrameExifMetadata?.brightnessValue.map {
                TwoDecimalFloat(double: $0)
            },
            bestCameraLensModel: bestFrameExifMetadata?.lensModel,
            bestExposureDuration: capturedImages.bestMiddle.scannerOutput.cameraProperties.flatMap { properties in
                let exposureDuration = properties.exposureDuration

                if exposureDuration.isNumeric {
                    return Int(properties.exposureDuration.seconds * 1000)
                }

                return nil
            },
            bestExposureIso: capturedImages.bestMiddle.scannerOutput.cameraProperties.map {
                TwoDecimalFloat($0.exposureISO)
            },
            bestFocalLength: bestFrameExifMetadata?.focalLength.map {
                TwoDecimalFloat(double: $0)
            },
            bestIsVirtualCamera: capturedImages.bestMiddle.scannerOutput.cameraProperties?
                .isVirtualDevice,
            captureFrames: capturedImages.shouldIncludeCaptureFrameMetadata
                ? capturedImages.toArray.map {
                    StripeAPI.VerificationPageDataFaceCaptureFrame(capturedImage: $0)
                }
                : nil,
            trainingConsent: trainingConsent
        )
    }
}

private extension FaceCaptureData {
    var shouldIncludeCaptureFrameMetadata: Bool {
        return toArray.contains {
            $0.capturePose != .front || $0.scannerOutput.facePose != nil
        }
    }
}

extension StripeAPI.VerificationPageDataFaceCaptureFrame {
    init(capturedImage: FaceScannerInputOutput) {
        self.init(
            pose: capturedImage.capturePose.rawValue,
            faceScore: .init(capturedImage.scannerOutput.faceScore),
            yaw: capturedImage.scannerOutput.facePose.map { .init($0.yaw) },
            pitch: capturedImage.scannerOutput.facePose.map { .init($0.pitch) },
            roll: capturedImage.scannerOutput.facePose.map { .init($0.roll) }
        )
    }
}

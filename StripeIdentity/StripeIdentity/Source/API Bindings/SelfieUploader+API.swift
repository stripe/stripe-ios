//
//  SelfieUploader+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/2/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

extension IdentityImageUploader.Configuration {
    init(from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage) {
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
            bestFaceScore: .init(capturedImages.bestMiddle.scannerOutput.faceScore),
            faceScoreVariance: .init(capturedImages.faceScoreVariance),
            numFrames: capturedImages.numSamples,
            bestBrightnessValue: bestFrameExifMetadata?.brightnessValue.map {
                TwoDecimalFloat(double: $0)
            },
            bestCameraLensModel: bestFrameExifMetadata?.lensModel,
            bestExposureDuration: capturedImages.bestMiddle.scannerOutput.cameraProperties.map {
                Int($0.exposureDuration.seconds * 1000)
            },
            bestExposureIso: capturedImages.bestMiddle.scannerOutput.cameraProperties.map {
                TwoDecimalFloat($0.exposureISO)
            },
            bestFocalLength: bestFrameExifMetadata?.focalLength.map {
                TwoDecimalFloat(double: $0)
            },
            bestIsVirtualCamera: capturedImages.bestMiddle.scannerOutput.cameraProperties?.isVirtualDevice,
            trainingConsent: trainingConsent
        )
    }
}

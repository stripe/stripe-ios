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
        let captureOrders = capturedImages.captureOrders
        self.init(
            bestHighResImage: uploadedFiles.bestHighResFile.id,
            bestLowResImage: uploadedFiles.bestLowResFile.id,
            firstHighResImage: uploadedFiles.firstHighResFile.id,
            firstLowResImage: uploadedFiles.firstLowResFile.id,
            lastHighResImage: uploadedFiles.lastHighResFile.id,
            lastLowResImage: uploadedFiles.lastLowResFile.id,
            leftFullFrame: uploadedFiles.leftFullFrameFile?.id,
            rightFullFrame: uploadedFiles.rightFullFrameFile?.id,
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
            bestFrameData: capturedImages.shouldIncludeCaptureFrameMetadata
                ? .init(
                    capturedImage: capturedImages.bestMiddle,
                    faceScoreVariance: capturedImages.faceScoreVariance,
                    captureOrder: captureOrders[.best]
                )
                : nil,
            firstFrameData: capturedImages.shouldIncludeCaptureFrameMetadata
                ? .init(
                    capturedImage: capturedImages.first,
                    faceScoreVariance: capturedImages.faceScoreVariance,
                    captureOrder: captureOrders[.first]
                )
                : nil,
            lastFrameData: capturedImages.shouldIncludeCaptureFrameMetadata
                ? .init(
                    capturedImage: capturedImages.last,
                    faceScoreVariance: capturedImages.faceScoreVariance,
                    captureOrder: captureOrders[.last]
                )
                : nil,
            leftFrameData: capturedImages.shouldIncludeCaptureFrameMetadata
                ? capturedImages.leftSide.map {
                    .init(
                        capturedImage: $0,
                        faceScoreVariance: capturedImages.faceScoreVariance,
                        captureOrder: captureOrders[.left]
                    )
                }
                : nil,
            rightFrameData: capturedImages.shouldIncludeCaptureFrameMetadata
                ? capturedImages.rightSide.map {
                    .init(
                        capturedImage: $0,
                        faceScoreVariance: capturedImages.faceScoreVariance,
                        captureOrder: captureOrders[.right]
                    )
                }
                : nil,
            trainingConsent: trainingConsent
        )
    }
}

private enum FaceCaptureFrameSlot: Hashable {
    case first
    case best
    case last
    case left
    case right
}

private extension FaceCaptureData {
    var shouldIncludeCaptureFrameMetadata: Bool {
        return toArray.contains {
            $0.capturePose != .front || $0.scannerOutput.facePose != nil
        }
    }

    var captureOrders: [FaceCaptureFrameSlot: Int] {
        var frames: [(FaceCaptureFrameSlot, FaceScannerInputOutput)] = [
            (.first, first),
            (.best, bestMiddle),
            (.last, last),
        ]
        if let leftSide {
            frames.append((.left, leftSide))
        }
        if let rightSide {
            frames.append((.right, rightSide))
        }

        let sortedFrames = frames.enumerated().sorted { lhs, rhs in
            if lhs.element.1.capturedAt == rhs.element.1.capturedAt {
                return lhs.offset < rhs.offset
            }
            return lhs.element.1.capturedAt < rhs.element.1.capturedAt
        }

        return Dictionary(
            uniqueKeysWithValues: sortedFrames.enumerated().map { index, frame in
                (frame.element.0, index + 1)
            }
        )
    }
}

extension StripeAPI.VerificationPageDataFaceFrameData {
    init(
        capturedImage: FaceScannerInputOutput,
        faceScoreVariance: Float,
        captureOrder: Int?
    ) {
        let faceRect = capturedImage.scannerOutput.faceRect
        let imageWidth = CGFloat(capturedImage.image.width)
        let imageHeight = CGFloat(capturedImage.image.height)

        self.init(
            faceScore: .init(capturedImage.scannerOutput.faceScore),
            faceScoreVariance: .init(faceScoreVariance),
            blurScore: nil,
            blurScoreVariance: .init(1),
            yaw: capturedImage.scannerOutput.facePose.map { .init($0.yaw) },
            pitch: capturedImage.scannerOutput.facePose.map { .init($0.pitch) },
            roll: capturedImage.scannerOutput.facePose.map { .init($0.roll) },
            bbox: [
                Int(faceRect.minX * imageWidth),
                Int(faceRect.minY * imageHeight),
                Int(faceRect.width * imageWidth),
                Int(faceRect.height * imageHeight),
            ],
            inputSize: [
                capturedImage.image.width,
                capturedImage.image.height,
            ],
            faceLandmarkResult: capturedImage.scannerOutput.faceLandmarkResult,
            capturedAt: capturedImage.capturedAt,
            captureOrder: captureOrder,
            cameraInfo: Self.encodedCameraInfo(from: capturedImage.cameraExifMetadata)
        )
    }

    private static func encodedCameraInfo(
        from exifMetadata: CameraExifMetadata?
    ) -> String? {
        guard let cameraLabel = exifMetadata?.lensModel else {
            return nil
        }
        let payload: [String: Any] = [
            "cameraLabel": cameraLabel,
        ]
        guard JSONSerialization.isValidJSONObject(payload),
            let data = try? JSONSerialization.data(withJSONObject: payload)
        else {
            return nil
        }
        return data.base64EncodedString()
    }
}

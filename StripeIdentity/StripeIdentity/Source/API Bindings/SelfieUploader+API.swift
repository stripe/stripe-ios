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
        trainingConsent: Bool,
        shouldSubmit3DFaceCaptureData: Bool = false
    ) {
        let captureOrders = capturedImages.captureOrders
        let leftFullFrame = shouldSubmit3DFaceCaptureData
            ? uploadedFiles.leftFullFrameFile?.id
            : nil
        let rightFullFrame = shouldSubmit3DFaceCaptureData
            ? uploadedFiles.rightFullFrameFile?.id
            : nil
        self.init(
            bestHighResImage: uploadedFiles.bestHighResFile.id,
            bestLowResImage: uploadedFiles.bestLowResFile.id,
            firstHighResImage: uploadedFiles.firstHighResFile.id,
            firstLowResImage: uploadedFiles.firstLowResFile.id,
            lastHighResImage: uploadedFiles.lastHighResFile.id,
            lastLowResImage: uploadedFiles.lastLowResFile.id,
            leftFullFrame: leftFullFrame,
            rightFullFrame: rightFullFrame,
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
                    return Int(properties.exposureDuration.seconds * 1_000_000)
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
                ? capturedImages.leftSide.flatMap { leftSide in
                    guard leftFullFrame != nil else {
                        return nil
                    }
                    return .init(
                        capturedImage: leftSide,
                        faceScoreVariance: capturedImages.faceScoreVariance,
                        captureOrder: captureOrders[.left]
                    )
                }
                : nil,
            rightFrameData: capturedImages.shouldIncludeCaptureFrameMetadata
                ? capturedImages.rightSide.flatMap { rightSide in
                    guard rightFullFrame != nil else {
                        return nil
                    }
                    return .init(
                        capturedImage: rightSide,
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
    private enum FaceLandmarkResultEncoding {
        static let maxEncodedLength = 5000
        static let scorePrecision = 4
    }
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
            faceLandmarkResult: Self.compactedFaceLandmarkResult(
                capturedImage.scannerOutput.faceLandmarkResult
            ),
            capturedAt: capturedImage.capturedAt,
            captureOrder: captureOrder,
            cameraInfo: Self.encodedCameraInfo(from: capturedImage.cameraExifMetadata)
        )
    }

    private static func compactedFaceLandmarkResult(
        _ encodedFaceLandmarkResult: String?
    ) -> String? {
        guard let encodedFaceLandmarkResult else {
            return nil
        }

        guard
            let data = Data(base64Encoded: encodedFaceLandmarkResult),
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let categories = jsonObject["categories"] as? [[String: Any]]
        else {
            return encodedFaceLandmarkResult.count <= FaceLandmarkResultEncoding.maxEncodedLength
                ? encodedFaceLandmarkResult
                : nil
        }

        let compactCategories: [[String: Any]] = categories.compactMap { category in
            guard let rawScore = category["score"] as? NSNumber else {
                return nil
            }

            var compactCategory: [String: Any] = [
                "score": roundedScore(rawScore.doubleValue),
            ]
            if let categoryName = category["category_name"] as? String,
                !categoryName.isEmpty
            {
                compactCategory["category_name"] = categoryName
            } else if let displayName = category["display_name"] as? String,
                !displayName.isEmpty
            {
                compactCategory["category_name"] = displayName
            }
            return compactCategory
        }

        let compactPayload: [String: Any] = [
            "categories": compactCategories,
        ]
        guard JSONSerialization.isValidJSONObject(compactPayload),
            let compactData = try? JSONSerialization.data(withJSONObject: compactPayload)
        else {
            return nil
        }

        let compactEncodedFaceLandmarkResult = compactData.base64EncodedString()
        guard compactEncodedFaceLandmarkResult.count <= FaceLandmarkResultEncoding.maxEncodedLength
        else {
            return nil
        }

        return compactEncodedFaceLandmarkResult
    }

    private static func roundedScore(_ score: Double) -> Double {
        let multiplier = pow(10.0, Double(FaceLandmarkResultEncoding.scorePrecision))
        return (score * multiplier).rounded() / multiplier
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

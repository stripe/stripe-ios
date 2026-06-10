//
//  VerificationPageDataFace.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageDataFace: Encodable, Equatable {

        /// File ID of uploaded image for best selfie frame. This will be cropped to the bounds of the face in the image.
        let bestHighResImage: String
        /// File ID of uploaded image for best selfie frame. This will be un-cropped.
        let bestLowResImage: String
        /// File ID of uploaded image for first selfie frame. This will be cropped to the bounds of the face in the image.
        let firstHighResImage: String
        /// File ID of uploaded image for first selfie frame. This will be un-cropped.
        let firstLowResImage: String
        /// File ID of uploaded image for last selfie frame. This will be cropped to the bounds of the face in the image.
        let lastHighResImage: String
        /// File ID of uploaded image for last selfie frame. This will be un-cropped.
        let lastLowResImage: String
        /// File ID of uploaded image for left side selfie frame. This will be cropped to the bounds of the face in the image.
        let leftHighResImage: String?
        /// File ID of uploaded image for left side selfie frame. This will be un-cropped.
        let leftLowResImage: String?
        /// File ID of uploaded image for right side selfie frame. This will be cropped to the bounds of the face in the image.
        let rightHighResImage: String?
        /// File ID of uploaded image for right side selfie frame. This will be un-cropped.
        let rightLowResImage: String?
        /// FaceDetector score for the best selfie frame.
        let bestFaceScore: TwoDecimalFloat
        /// Variance of the FaceDetector scores over all selfie frames.
        let faceScoreVariance: TwoDecimalFloat
        /// The total number of selfie frames taken.
        let numFrames: Int
        /// Camera brightness value for the best selfie frame.
        let bestBrightnessValue: TwoDecimalFloat?
        /// Camera lens model for the best selfie frame.
        let bestCameraLensModel: String?
        /// Camera exposure duration for the best selfie frame.
        let bestExposureDuration: Int?
        /// Camera exposure ISO for the best selfie frame
        let bestExposureIso: TwoDecimalFloat?
        /// Camera focal length for the best selfie frame.
        let bestFocalLength: TwoDecimalFloat?
        /// If the best selfie frame was taken by a virtual camera.
        let bestIsVirtualCamera: Bool?
        /// Capture metadata for the accepted selfie frames.
        let captureFrames: [VerificationPageDataFaceCaptureFrame]?
        /// Whether the user consents for their selfie to be used for training purposes
        let trainingConsent: Bool

        init(
            bestHighResImage: String,
            bestLowResImage: String,
            firstHighResImage: String,
            firstLowResImage: String,
            lastHighResImage: String,
            lastLowResImage: String,
            leftHighResImage: String? = nil,
            leftLowResImage: String? = nil,
            rightHighResImage: String? = nil,
            rightLowResImage: String? = nil,
            bestFaceScore: TwoDecimalFloat,
            faceScoreVariance: TwoDecimalFloat,
            numFrames: Int,
            bestBrightnessValue: TwoDecimalFloat?,
            bestCameraLensModel: String?,
            bestExposureDuration: Int?,
            bestExposureIso: TwoDecimalFloat?,
            bestFocalLength: TwoDecimalFloat?,
            bestIsVirtualCamera: Bool?,
            captureFrames: [VerificationPageDataFaceCaptureFrame]? = nil,
            trainingConsent: Bool
        ) {
            self.bestHighResImage = bestHighResImage
            self.bestLowResImage = bestLowResImage
            self.firstHighResImage = firstHighResImage
            self.firstLowResImage = firstLowResImage
            self.lastHighResImage = lastHighResImage
            self.lastLowResImage = lastLowResImage
            self.leftHighResImage = leftHighResImage
            self.leftLowResImage = leftLowResImage
            self.rightHighResImage = rightHighResImage
            self.rightLowResImage = rightLowResImage
            self.bestFaceScore = bestFaceScore
            self.faceScoreVariance = faceScoreVariance
            self.numFrames = numFrames
            self.bestBrightnessValue = bestBrightnessValue
            self.bestCameraLensModel = bestCameraLensModel
            self.bestExposureDuration = bestExposureDuration
            self.bestExposureIso = bestExposureIso
            self.bestFocalLength = bestFocalLength
            self.bestIsVirtualCamera = bestIsVirtualCamera
            self.captureFrames = captureFrames
            self.trainingConsent = trainingConsent
        }
    }

    struct VerificationPageDataFaceCaptureFrame: Encodable, Equatable {
        let pose: String
        let faceScore: TwoDecimalFloat
        let yaw: TwoDecimalFloat?
        let pitch: TwoDecimalFloat?
        let roll: TwoDecimalFloat?
    }
}

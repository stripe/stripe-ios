//
//  VerificationPageDataFace.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/10/22.
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
        /// Whether the user consents for their selfie to be used for training purposes
        let trainingConsent: Bool
    }
}

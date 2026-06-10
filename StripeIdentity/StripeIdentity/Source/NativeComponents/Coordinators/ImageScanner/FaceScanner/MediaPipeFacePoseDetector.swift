//
//  MediaPipeFacePoseDetector.swift
//  StripeIdentity
//
//  Created by Stripe on 6/10/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreMedia
import Foundation

#if canImport(MediaPipeTasksVision)
@_implementationOnly import MediaPipeTasksVision

final class MediaPipeFacePoseDetector: FacePoseDetector {
    private enum Configuration {
        static let maxNumFaces = 1
        static let scoreThreshold: Float = 0.8
    }

    private let faceLandmarker: FaceLandmarker

    init(modelPath: String) throws {
        let options = FaceLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.numFaces = Configuration.maxNumFaces
        options.minFaceDetectionConfidence = Configuration.scoreThreshold
        options.minFacePresenceConfidence = Configuration.scoreThreshold
        options.minTrackingConfidence = Configuration.scoreThreshold
        options.outputFaceBlendshapes = true
        options.outputFacialTransformationMatrixes = true

        faceLandmarker = try FaceLandmarker(options: options)
    }

    func detectPose(sampleBuffer: CMSampleBuffer) throws -> FacePose? {
        let image = try MPImage(sampleBuffer: sampleBuffer)
        let result = try faceLandmarker.detect(image: image)

        guard let matrix = result.facialTransformationMatrixes.first else {
            return nil
        }

        return Self.rotationMatrixToPose(matrix)
    }

    func reset() {}
}

private extension MediaPipeFacePoseDetector {
    static func radiansToDegrees(_ radians: Float) -> Float {
        return radians * 180 / .pi
    }

    static func clamp(_ value: Float, min: Float, max: Float) -> Float {
        return Swift.max(min, Swift.min(max, value))
    }

    static func rotationMatrixToPose(_ matrix: TransformMatrix) -> FacePose? {
        guard matrix.rows == 4,
            matrix.columns == 4
        else {
            return nil
        }

        // MediaPipe returns a column-major 4x4 facial transformation matrix.
        let data = matrix.data
        let m11 = data[0]
        let m12 = data[4]
        let m13 = data[8]
        let m22 = data[5]
        let m23 = data[9]
        let m32 = data[6]
        let m33 = data[10]

        let y = asin(clamp(m13, min: -1, max: 1))
        let x: Float
        let z: Float
        if abs(m13) < 0.9999999 {
            x = atan2(-m23, m33)
            z = atan2(-m12, m11)
        } else {
            x = atan2(m32, m22)
            z = 0
        }

        return FacePose(
            yaw: radiansToDegrees(-y),
            pitch: radiansToDegrees(-x),
            roll: radiansToDegrees(z)
        )
    }
}
#endif

enum FacePoseDetectorFactory {
    static func makeDefaultDetector() -> FacePoseDetector? {
        guard let modelPath = StripeIdentityBundleLocator.resourcesBundle.path(
            forResource: "face_landmarker",
            ofType: "task"
        ) else {
            return nil
        }

        #if canImport(MediaPipeTasksVision)
        return try? MediaPipeFacePoseDetector(modelPath: modelPath)
        #else
        return nil
        #endif
    }
}

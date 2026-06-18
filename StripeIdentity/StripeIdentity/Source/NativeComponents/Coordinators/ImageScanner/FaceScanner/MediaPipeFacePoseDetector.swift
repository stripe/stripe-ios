//
//  MediaPipeFacePoseDetector.swift
//  StripeIdentity
//
//  Created by Stripe on 6/10/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreMedia
import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore
import UIKit

#if canImport(MediaPipeTasksVision)
@_implementationOnly import MediaPipeTasksVision

final class MediaPipeFacePoseDetector: FaceGeometryDetector {
    private enum Configuration {
        static let maxNumFaces = 1
        static let scoreThreshold: Float = 0.5
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

    func detectFace(pixelBuffer: CVPixelBuffer) throws -> FaceGeometry? {
        guard let image = try Self.makeImage(pixelBuffer: pixelBuffer) else {
            return nil
        }

        let result = try faceLandmarker.detect(image: image)

        guard let landmarks = result.faceLandmarks.first,
            let rect = Self.faceRect(from: landmarks)
        else {
            return nil
        }

        let facePose = result.facialTransformationMatrixes.first.flatMap {
            Self.rotationMatrixToPose($0)
        }
        return .init(
            faceDetectorOutput: .init(
                predictions: [
                    .init(
                        rect: rect,
                        score: Self.faceScore(from: landmarks)
                    ),
                ]
            ),
            facePose: facePose
        )
    }

    func reset() {}
}

private extension MediaPipeFacePoseDetector {
    static func makeImage(pixelBuffer: CVPixelBuffer) throws -> MPImage? {
        if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA {
            return try MPImage(pixelBuffer: pixelBuffer, orientation: .up)
        }

        guard let cgImage = pixelBuffer.cgImage() else {
            return nil
        }

        return try MPImage(uiImage: UIImage(cgImage: cgImage), orientation: .up)
    }

    static func radiansToDegrees(_ radians: Float) -> Float {
        return radians * 180 / .pi
    }

    static func clamp(_ value: Float, min: Float, max: Float) -> Float {
        return Swift.max(min, Swift.min(max, value))
    }

    static func faceRect(from landmarks: [NormalizedLandmark]) -> CGRect? {
        guard !landmarks.isEmpty else {
            return nil
        }

        let minX = landmarks.map { CGFloat($0.x) }.min() ?? 0
        let minY = landmarks.map { CGFloat($0.y) }.min() ?? 0
        let maxX = landmarks.map { CGFloat($0.x) }.max() ?? 0
        let maxY = landmarks.map { CGFloat($0.y) }.max() ?? 0
        let rect = CGRect(
            x: min(max(minX, 0), 1),
            y: min(max(minY, 0), 1),
            width: min(max(maxX - minX, 0), 1),
            height: min(max(maxY - minY, 0), 1)
        )
        guard rect.width > 0, rect.height > 0 else {
            return nil
        }
        return rect
    }

    static func faceScore(from landmarks: [NormalizedLandmark]) -> Float {
        let scores = landmarks.compactMap { landmark -> Float? in
            if let presence = landmark.presence {
                return presence.floatValue
            }
            if let visibility = landmark.visibility {
                return visibility.floatValue
            }
            return nil
        }
        guard !scores.isEmpty else {
            return 1
        }
        return scores.reduce(0, +) / Float(scores.count)
    }

    static func rotationMatrixToPose(_ matrix: TransformMatrix) -> FacePose? {
        guard matrix.rows == 4,
            matrix.columns == 4
        else {
            return nil
        }

        let m11 = matrix.value(atRow: 0, column: 0)
        let m12 = matrix.value(atRow: 0, column: 1)
        let m13 = matrix.value(atRow: 0, column: 2)
        let m22 = matrix.value(atRow: 1, column: 1)
        let m23 = matrix.value(atRow: 1, column: 2)
        let m32 = matrix.value(atRow: 2, column: 1)
        let m33 = matrix.value(atRow: 2, column: 2)

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
            yaw: radiansToDegrees(y),
            pitch: radiansToDegrees(x),
            roll: radiansToDegrees(z)
        )
    }
}
#endif

enum FaceGeometryDetectorFactory {
    static func makeDefaultDetector() -> FaceGeometryDetector? {
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

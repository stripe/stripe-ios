//
//  FaceScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreGraphics
import Foundation
@_spi(STP) import StripeCameraCore

struct FaceScannerOutput: Equatable {
    enum ValidationIssue: Equatable {
        case faceCount
        case adjustingFocus
        case motionBlur
        case offCenter
        case nearEdge
        case tooFar
        case tooClose
    }

    private enum BestFrame {
        static let faceScoreWeight: Float = 0.25
        static let centeringWeight: Float = 0.25
        static let coverageWeight: Float = 0.25
        static let stabilityWeight: Float = 0.25
        static let targetCoverage: CGFloat = 0.16
        static let maxCoverageDelta: CGFloat = 0.16
    }

    let faceDetectorOutput: FaceDetectorOutput
    let cameraProperties: CameraSession.DeviceProperties?
    let motionBlurResult: MotionBlurDetector.Output?
    let facePose: FacePose?
    let faceLandmarkResult: String?
    let validationIssue: ValidationIssue?
    let isValid: Bool

    init(
        faceDetectorOutput: FaceDetectorOutput,
        cameraProperties: CameraSession.DeviceProperties?,
        motionBlurResult: MotionBlurDetector.Output?,
        facePose: FacePose? = nil,
        faceLandmarkResult: String? = nil,
        validationIssue: ValidationIssue? = nil,
        isValid: Bool
    ) {
        self.faceDetectorOutput = faceDetectorOutput
        self.cameraProperties = cameraProperties
        self.motionBlurResult = motionBlurResult
        self.facePose = facePose
        self.faceLandmarkResult = faceLandmarkResult
        self.validationIssue = validationIssue
        self.isValid = isValid
    }

    var faceScore: Float {
        return faceDetectorOutput.predictions.first?.score ?? 0
    }

    var faceRect: CGRect {
        return faceDetectorOutput.predictions.first?.rect ?? .zero
    }

    /// A basic ranking score for selecting the best frame among valid samples.
    /// Range: [0, 1], where higher is better.
    var bestFrameScore: Float {
        guard faceDetectorOutput.predictions.count == 1 else {
            return 0
        }

        return
            (faceScore * BestFrame.faceScoreWeight)
            + (centeringScore * BestFrame.centeringWeight)
            + (coverageScore * BestFrame.coverageWeight)
            + (stabilityScore * BestFrame.stabilityWeight)
    }

    private var centeringScore: Float {
        let dx = abs(faceRect.midX - 0.5)
        let dy = abs(faceRect.midY - 0.5)
        let distanceFromCenter = sqrt((dx * dx) + (dy * dy))
        let maxDistanceFromCenter = sqrt(CGFloat(0.5))
        let normalizedDistance = min(CGFloat(1), distanceFromCenter / maxDistanceFromCenter)
        return 1 - Float(normalizedDistance)
    }

    private var coverageScore: Float {
        let coverage = faceRect.width * faceRect.height
        let delta = abs(coverage - BestFrame.targetCoverage)
        let normalizedDelta = min(CGFloat(1), delta / BestFrame.maxCoverageDelta)
        return 1 - Float(normalizedDelta)
    }

    private var stabilityScore: Float {
        if cameraProperties?.isAdjustingFocus == true || motionBlurResult?.hasMotionBlur == true {
            return 0
        }
        // If motion blur is unknown (e.g. very first frame), provide a partial score.
        if motionBlurResult == nil {
            return 0.5
        }
        return 1
    }
}

extension FaceScannerOutput {

    init(
        faceDetectorOutput: FaceDetectorOutput,
        cameraProperties: CameraSession.DeviceProperties?,
        configuration: FaceScanner.Configuration,
        motionBlurResult: MotionBlurDetector.Output? = nil,
        facePose: FacePose? = nil,
        faceLandmarkResult: String? = nil
    ) {
        let validationIssue = FaceScannerOutput.validationIssue(
            faceDetectorOutput: faceDetectorOutput,
            cameraProperties: cameraProperties,
            motionBlurResult: motionBlurResult,
            configuration: configuration
        )

        self.init(
            faceDetectorOutput: faceDetectorOutput,
            cameraProperties: cameraProperties,
            motionBlurResult: motionBlurResult,
            facePose: facePose,
            faceLandmarkResult: faceLandmarkResult,
            validationIssue: validationIssue,
            isValid: validationIssue == nil
        )
    }

    private static func validationIssue(
        faceDetectorOutput: FaceDetectorOutput,
        cameraProperties: CameraSession.DeviceProperties?,
        motionBlurResult: MotionBlurDetector.Output?,
        configuration: FaceScanner.Configuration
    ) -> ValidationIssue? {
        guard faceDetectorOutput.predictions.count == 1,
            let rect = faceDetectorOutput.predictions.first?.rect
        else {
            return .faceCount
        }
        guard cameraProperties?.isAdjustingFocus != true else {
            return .adjustingFocus
        }
        guard motionBlurResult?.hasMotionBlur != true else {
            return .motionBlur
        }
        guard FaceScannerOutput.isFaceCentered(
            rect: rect,
            maxCenteredThreshold: configuration.maxCenteredThreshold
        ) else {
            return .offCenter
        }
        guard FaceScannerOutput.isFaceAwayFromEdges(
            rect: rect,
            minEdgeThreshold: configuration.minEdgeThreshold
        ) else {
            return .nearEdge
        }

        let coverage = rect.width * rect.height
        if coverage <= configuration.minCoverageThreshold {
            return .tooFar
        }
        if coverage >= configuration.maxCoverageThreshold {
            return .tooClose
        }
        return nil
    }

    /// Whether the face's bounding box is centered in the frame within the maximum thresholds.
    static func isFaceCentered(rect: CGRect, maxCenteredThreshold: CGPoint) -> Bool {
        return abs(1 - (rect.maxY + rect.minY)) < maxCenteredThreshold.y
            && abs(1 - (rect.maxX + rect.minX)) < maxCenteredThreshold.x
    }

    /// Whether the face's bounding box is away from the image edges by the minimum threshold.
    static func isFaceAwayFromEdges(rect: CGRect, minEdgeThreshold: CGFloat) -> Bool {
        return rect.minY > minEdgeThreshold
            && rect.maxY < (1 - minEdgeThreshold)
            && rect.minX > minEdgeThreshold
            && rect.maxX < (1 - minEdgeThreshold)
    }
}

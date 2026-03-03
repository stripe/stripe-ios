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
    let isValid: Bool

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
        motionBlurResult: MotionBlurDetector.Output? = nil
    ) {
        var isValid = false
        if let rect = faceDetectorOutput.predictions.first?.rect {
            isValid =
                cameraProperties?.isAdjustingFocus != true
                && faceDetectorOutput.predictions.count == 1
                && motionBlurResult?.hasMotionBlur != true
                && FaceScannerOutput.isFaceCentered(
                    rect: rect,
                    maxCenteredThreshold: configuration.maxCenteredThreshold
                )
                && FaceScannerOutput.isFaceAwayFromEdges(
                    rect: rect,
                    minEdgeThreshold: configuration.minEdgeThreshold
                )
                && FaceScannerOutput.isFaceWithinCoverageThresholds(
                    rect: rect,
                    min: configuration.minCoverageThreshold,
                    max: configuration.maxCoverageThreshold
                )
        }

        self.init(
            faceDetectorOutput: faceDetectorOutput,
            cameraProperties: cameraProperties,
            motionBlurResult: motionBlurResult,
            isValid: isValid
        )
    }

    /// Is the face’s bounding box is centered in the frame within max thresholds
    static func isFaceCentered(rect: CGRect, maxCenteredThreshold: CGPoint) -> Bool {
        return abs(1 - (rect.maxY + rect.minY)) < maxCenteredThreshold.y
            && abs(1 - (rect.maxX + rect.minX)) < maxCenteredThreshold.x
    }

    /// Is the face’s bounding box is away from the edges of the image by a minimum threshold
    static func isFaceAwayFromEdges(rect: CGRect, minEdgeThreshold: CGFloat) -> Bool {
        return rect.minY > minEdgeThreshold
            && rect.maxY < (1 - minEdgeThreshold)
            && rect.minX > minEdgeThreshold
            && rect.maxX < (1 - minEdgeThreshold)
    }

    /// Is the face’s bounding box area (coverage) is between a min & max threshold
    static func isFaceWithinCoverageThresholds(rect: CGRect, min: CGFloat, max: CGFloat) -> Bool {
        let coverage = rect.width * rect.height
        return coverage > min && coverage < max
    }
}

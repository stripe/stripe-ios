//
//  FaceScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import Foundation
import CoreGraphics
@_spi(STP) import StripeCameraCore

struct FaceScannerOutput: Equatable {
    let faceDetectorOutput: FaceDetectorOutput
    let cameraProperties: CameraSession.DeviceProperties?
    let isValid: Bool

    var faceScore: Float {
        return faceDetectorOutput.predictions.first?.score ?? 0
    }

    var faceRect: CGRect {
        return faceDetectorOutput.predictions.first?.rect ?? .zero
    }

    /// The quality of the image
    var quality: Float {
        return faceScore
    }
}

extension FaceScannerOutput {
    @available(iOS 13, *)
    init(
        faceDetectorOutput: FaceDetectorOutput,
        cameraProperties: CameraSession.DeviceProperties?,
        configuration: FaceScanner.Configuration
    ) {
        var isValid = false
        if let rect = faceDetectorOutput.predictions.first?.rect {
            isValid = cameraProperties?.isAdjustingFocus != true
            && faceDetectorOutput.predictions.count == 1
            && FaceScannerOutput.isFaceCentered(
                rect: rect,
                maxCenteredThreshold: configuration.maxCenteredThreshold
            ) && FaceScannerOutput.isFaceAwayFromEdges(
                rect: rect,
                minEdgeThreshold: configuration.minEdgeThreshold
            ) && FaceScannerOutput.isFaceWithinCoverageThresholds(
                rect: rect,
                min: configuration.minCoverageThreshold,
                max: configuration.maxCoverageThreshold
            )
        }

        self.init(
            faceDetectorOutput: faceDetectorOutput,
            cameraProperties: cameraProperties,
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

//
//  MBCCFrameAnalysisStatus+Extensions.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/5/24.
//

import CaptureCore
import Foundation

extension MBCCFrameAnalysisStatus {
    func toCaptureFeedback() -> MBDetector.CaptureFeedback {
        if sideAnalysisStatus == .sideAlreadyCaptured {
            return .wrongSide
        }

        if framingStatus == .noDocument {
            return .documentFramingNoDocument
        } else if framingStatus == .cameraTooFar {
            return .documentFramingCameraTooFar
        } else if framingStatus == .cameraTooClose {
            return .documentFramingCameraTooClose
        } else if framingStatus == .cameraOrientationUnsuitable {
            return .documentFramingCameraOrientationUnsuitable
        } else if framingStatus == .cameraAngleTooSteep {
            return .documentFramingCameraAngleTooSteep
        } else if framingStatus == .documentTooCloseToFrameEdge {
            return .documentTooCloseToFrameEdge
        }

        if lightingStatus == .tooBright {
            return .lightingTooBright
        } else if lightingStatus == .tooDark {
            return .lightingTooDark
        }
        if blurStatus == .blurDetected {
            return .blurDetected
        }
        if glareStatus == .glareDetected {
            return .glareDetected
        }
        if occlusionStatus == .occluded {
            return .occludedByHand
        }
        return .unknown
    }

}

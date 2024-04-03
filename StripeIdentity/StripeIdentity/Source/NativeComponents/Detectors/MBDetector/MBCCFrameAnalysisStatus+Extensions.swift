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

        switch framingStatus {
        case .noDocument:
            return .documentFramingNoDocument
        case .cameraTooFar:
            return .documentFramingCameraTooFar
        case .cameraTooClose:
            return .documentFramingCameraTooClose
        case .cameraOrientationUnsuitable:
            return .documentFramingCameraOrientationUnsuitable
        case .cameraAngleTooSteep:
            return .documentFramingCameraAngleTooSteep
        case .documentTooCloseToFrameEdge:
            return .documentTooCloseToFrameEdge
        default:
            break
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

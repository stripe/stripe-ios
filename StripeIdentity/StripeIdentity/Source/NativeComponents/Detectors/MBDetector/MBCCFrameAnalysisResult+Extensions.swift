//
//  MBCCaptureState+Extensions.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/18/24.
//

import CaptureCore
import Foundation

extension MBCCFrameAnalysisResult {

    func toDetectorResult() -> MBDetector.DetectorResult {
        switch self.captureState {
        case .sideCaptured:
            // we never have this
            return .error(.unexpectedSideCaptured)
        case .documentCaptured:
            let analyzerResult = MBCCAnalyzerRunner.shared().detachResult()
            guard
                let captureResult = analyzerResult.firstCapture,
                let original = captureResult.capturedImage?.image?.unrotate(),
                let transformed = captureResult.transformedImage?.image,
                let side: DocumentSide = captureResult.side == .front ? .front : .back // Per MB's feedback
            else {
                return .error(.noValidResult)
            }

            return .captured(original, transformed, side)
        case .firstSideCaptureInProgress:
            return .capturing(frameAnalysisStatus.toCaptureFeedback())
        case .secondSideCaptureInProgress:
            return .error(.unexpectedSideCaptured)
        @unknown default:
            return .error(.unknown)
        }
    }

}

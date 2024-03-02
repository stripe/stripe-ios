//
//  DocumentScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CaptureCore
import Foundation
@_spi(STP) import StripeCameraCore

/// Consolidated output from all ML models / detectors that make up document
/// scanning. The combination of this output will determine if the image captured
/// is high enough quality to accept and whether the result matches a document side.
enum DocumentScannerOutput: Equatable {
    // Result with legacy detectors
    case legacy(IDDetectorOutput, BarcodeDetectorOutput?, MotionBlurDetector.Output, CameraSession.DeviceProperties?, LaplacianBlurDetector.Output)
    // Result with MBDetector and IDDetector
    case modern(IDDetectorOutput, MBDetector.DetectorResult, CameraSession.DeviceProperties?)

    var idDetectorOutput: IDDetectorOutput {
        switch self {
        case .legacy(let detectorOutput, _, _, _, _):
            return detectorOutput
        case .modern(let detectorOutput, _, _):
            return detectorOutput
        }
    }

    var cameraProperties: CameraSession.DeviceProperties? {
        switch self {
        case .legacy(_, _, _, let cameraProperties, _):
            return cameraProperties
        case .modern(_, _, let cameraProperties):
            return cameraProperties
        }
    }

    var barcode: BarcodeDetectorOutput? {
        switch self {
        case .legacy(_, let barcode, _, _, _):
            return barcode
        case .modern:
            return nil
        }
    }

    /// Determines if the document is high quality and matches the desired
    /// document type and side.
    /// - Parameters:
    ///   - side: Side of the desired document.
    func isHighQuality(
        side: DocumentSide
    ) -> Bool {
        switch self {
        case let .legacy(idDetectorOutput, barcode, motionBlur, cameraProperties, blurResult):
            if barcode?.hasBarcode == true {
                // If the barcode is clear enough to decode, then that's good enough and
                // it doesn't matter if the MotionBlurDetector believes there's motion blur
                // just need to make sure the zoom level is ok
                return idDetectorOutput.computeZoomLevel() == .ok
            } else {
                return idDetectorOutput.classification.matchesDocument(side: side)
                    && cameraProperties?.isAdjustingFocus != true
                    && !motionBlur.hasMotionBlur
                    && blurResult.isBlurry != true
                    && idDetectorOutput.computeZoomLevel() == .ok
            }
        case let .modern(_, mbResult, _):
            if case let .captured(_, _, mbSide) = mbResult {
                return mbSide == side
            } else {
                return false
            }
        }

    }

    func matchesDocument(
        side: DocumentSide
    ) -> Bool {
        return idDetectorOutput.classification.matchesDocument(side: side)
    }

    func getDocumentBounds() -> CGRect {
        return idDetectorOutput.documentBounds
    }

    func getAllClassificationScores() -> [IDDetectorOutput.Classification: Float] {
        return idDetectorOutput.allClassificationScores
    }
}

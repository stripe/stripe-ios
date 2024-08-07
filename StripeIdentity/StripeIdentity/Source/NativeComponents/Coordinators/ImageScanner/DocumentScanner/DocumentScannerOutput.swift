//
//  DocumentScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore

/// Consolidated output from all ML models / detectors that make up document
/// scanning. The combination of this output will determine if the image captured
/// is high enough quality to accept and whether the result matches a document side.
enum DocumentScannerOutput: Equatable {
    // Result with legacy detectors
    case legacy(IDDetectorOutput, BarcodeDetectorOutput?, MotionBlurDetector.Output, CameraSession.DeviceProperties?, LaplacianBlurDetector.Output)

    var idDetectorOutput: IDDetectorOutput {
        switch self {
        case .legacy(let detectorOutput, _, _, _, _):
            return detectorOutput
        }
    }

    var cameraProperties: CameraSession.DeviceProperties? {
        switch self {
        case .legacy(_, _, _, let cameraProperties, _):
            return cameraProperties
        }
    }

    var barcode: BarcodeDetectorOutput? {
        switch self {
        case .legacy(_, let barcode, _, _, _):
            return barcode
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
            return checkWithDetectorResults(side, idDetectorOutput, barcode, motionBlur, cameraProperties, blurResult)
        }

    }

    private func checkWithDetectorResults(
        _ side: DocumentSide,
        _ idDetectorOutput: IDDetectorOutput,
        _ barcode: BarcodeDetectorOutput?,
        _ motionBlur: MotionBlurDetector.Output,
        _ cameraProperties: CameraSession.DeviceProperties?,
        _ blurResult: LaplacianBlurDetector.Output
    ) -> Bool {
        if barcode?.hasBarcode == true {
            // If the barcode is clear enough to decode, then that's good enough and
            // it doesn't matter if the MotionBlurDetector believes there's motion blur
            // just need to make sure the zoom level is ok
            return blurResult.isBlurry != true
                && idDetectorOutput.computeZoomLevel() == .ok
        } else {
            return idDetectorOutput.classification.matchesDocument(side: side)
                && cameraProperties?.isAdjustingFocus != true
                && !motionBlur.hasMotionBlur
                && blurResult.isBlurry != true
                && idDetectorOutput.computeZoomLevel() == .ok
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

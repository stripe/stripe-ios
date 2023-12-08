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
/// is high enough quality to accept.
struct DocumentScannerOutput: Equatable {
    let idDetectorOutput: IDDetectorOutput
    let barcode: BarcodeDetectorOutput?
    let motionBlur: MotionBlurDetector.Output
    let cameraProperties: CameraSession.DeviceProperties?
    let blurResult: LaplacianBlurDetector.Output

    /// Determines if the document is high quality and matches the desired
    /// document type and side.
    /// - Parameters:
    ///   - side: Side of the desired document.
    func isHighQuality(
        side: DocumentSide
    ) -> Bool {
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
    }
}

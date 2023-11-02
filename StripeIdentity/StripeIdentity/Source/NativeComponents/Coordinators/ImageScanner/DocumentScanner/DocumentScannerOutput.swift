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
        // Don't check barcode result as it would end up returning fast and collecting a blury image
        // that fails to decode on backend
        // TODO(ccen|IDPROD-4697): Implement better heuristic to decode the back of ID.
        return idDetectorOutput.classification.matchesDocument(side: side)
            && cameraProperties?.isAdjustingFocus != true
            && !motionBlur.hasMotionBlur
            && blurResult.isBlurry != true
    }
}

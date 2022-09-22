//
//  DocumentScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/1/22.
//

import Foundation
@_spi(STP) import StripeCameraCore

/**
 Consolidated output from all ML models / detectors that make up document
 scanning. The combination of this output will determine if the image captured
 is high enough quality to accept.
 */
struct DocumentScannerOutput: Equatable {
    let idDetectorOutput: IDDetectorOutput
    let barcode: BarcodeDetectorOutput?
    let motionBlur: MotionBlurDetector.Output
    let cameraProperties: CameraSession.DeviceProperties?

    /**
     Determines if the document is high quality and matches the desired
     document type and side.
     - Parameters:
       - type: Type of the desired document
       - side: Side of the desired document.
     */
    func isHighQuality(
        matchingDocumentType type: DocumentType,
        side: DocumentSide
    ) -> Bool {
        // Even if barcode is clear enough to decode, still wait for a non blur image
        let hasNoBlur: Bool
        if let barcode = barcode {
            let hasGoodBarcode = barcode.hasBarcode && !barcode.isTimedOut
            hasNoBlur = !motionBlur.hasMotionBlur && hasGoodBarcode
        } else {
            hasNoBlur = !motionBlur.hasMotionBlur
        }
        return idDetectorOutput.classification.matchesDocument(type: type, side: side)
        && cameraProperties?.isAdjustingFocus != true
        && hasNoBlur
    }
}

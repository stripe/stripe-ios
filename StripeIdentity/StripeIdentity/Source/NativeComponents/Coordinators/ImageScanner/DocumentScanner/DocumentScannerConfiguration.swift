//
//  DocumentScannerConfiguration.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/1/22.
//

import Foundation
import Vision

@available(iOS 13, *)
extension DocumentScanner {
    struct Configuration {
        // MARK: ID Detector
        
        /// Score threshold for IDDetector
        let idDetectorMinScore: Float
        /// IOU threshold used for NMS for IDDetector
        let idDetectorMinIOU: Float

        // MARK: Motion blur

        /// IOU threshold of document bounding box between camera frames
        let motionBlurMinIOU: Float
        /// Amount of time the camera frames the IOU must stay under the threshold for
        let motionBlurMinDuration: TimeInterval

        // MARK: Barcode

        /// If the DocumentScanner should check for a barcode with this symbology
        /// on the back of ID cards
        let backIdCardBarcodeSymbology: VNBarcodeSymbology?
        /// The amount of time the scanner should look for a barcode on the ID
        /// back before accepting images without a readable barcode
        let backIdCardBarcodeTimeout: TimeInterval
    }
}

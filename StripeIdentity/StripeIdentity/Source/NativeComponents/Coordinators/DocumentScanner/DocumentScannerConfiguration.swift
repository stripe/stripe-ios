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
        /// Score threshold for IDDetector
        let idDetectorMinScore: Float
        /// IOU threshold used for NMS for IDDetector
        let idDetectorMinIOU: Float

        /// IOU threshold of document bounding box between camera frames
        let motionBlurMinIOU: Float
        /// Amount of time the camera frames the IOU must stay under the threshold for
        let motionBlurMinDuration: TimeInterval

        /// If the DocumentScanner should check for a barcode with this symbology
        /// on the back of ID cards
        let backIdCardBarcodeSymbology: VNBarcodeSymbology?
        /// The amount of time the scanner should look for a barcode on the ID
        /// back before accepting images without a readable barcode
        let backIdCardBarcodeTimeout: TimeInterval

        // TODO(mludowise|IDPROD-3269): Use values from the API instead of hardcoding
        static let `default` = Configuration(
            idDetectorMinScore: 0.4,
            idDetectorMinIOU: 0.5,
            motionBlurMinIOU: 0.95,
            motionBlurMinDuration: 0.5,
            backIdCardBarcodeSymbology: backIdCardBarcodeSymbology(forRegion: Locale.autoupdatingCurrent.regionCode),
            backIdCardBarcodeTimeout: 3
        )

        // TODO(mludowise|IDPROD-3269): Lookup region from API response instead of hardcoding
        static func backIdCardBarcodeSymbology(forRegion regionCode: String?) -> VNBarcodeSymbology? {
            switch regionCode {
            case "US",
                "CA":
                return .PDF417
            default:
                return nil
            }
        }
    }
}

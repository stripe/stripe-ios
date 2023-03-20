//
//  ScannedCardDetails.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 3/10/22.
//

import Foundation
import CoreGraphics
@testable import StripeCardScan

struct ScannedCardDetails {
    let number: String
    let iin: String
    let last4: String
    let scannedImageData: ScannedCardImageData

    init(number: String) {
        self.number = number
        self.iin = String(number.prefix(6))
        self.last4 = String(number.suffix(4))

        /// Create discernable `ScannedCardImageData` by setting the preview layer rect to the iin & last4
        self.scannedImageData = ScannedCardImageData(
            previewLayerImage: ImageHelpers.createBlankCGImage(),
            previewLayerViewfinderRect: CGRect(x: 0, y: 0, width: Int(iin)!, height: Int(last4)!)
        )
    }
}

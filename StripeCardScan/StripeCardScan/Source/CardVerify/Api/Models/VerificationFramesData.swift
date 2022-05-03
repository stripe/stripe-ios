//
//  VerificationFramesData.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/19/21.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

struct VerificationFramesData: Encodable {
    /// A base64 encoding of a scanned card image
    let imageData: Data?
    /// The bounds of the card view finder (measured in pixels)
    let viewfinderMargins: ViewFinderMargins
}

/*
 Bounds of the scanner's card viewfinder (measured in pixels)
 ----------------------------------------------
 |                     |                      |
 |                   upper                    |
 |                    300                     |
 |                     |                      |
 |        ------------300------------         |
 |        |                         |         |
 |        1                         |         |
 |--left--0                         |--right--|
 |   100  0---4242 4242 4242 4242---|   400   |
 |        |          05/23          |         |
 |        ---------------------------         |
 |                     |                      |
 |                   lower                    |
 |                    400                     |
 |                     |                      |
 ----------------------------------------------
 */
struct ViewFinderMargins: Encodable {
    /// The amount of pixels from the left-most bound of the image to the left-most bound of the viewfinder
    let left: Int
    /// The amount of pixels from the top-most bound of the image to the top-most bound of the viewfinder
    let upper: Int
    /// The amount of pixels from the left-most bound of the image to the right-most bound of the viewfinder
    let right: Int
    /// The amount of pixels from the top-most bound of the image to the bottom-most bound of the viewfinder
    let lower: Int
}

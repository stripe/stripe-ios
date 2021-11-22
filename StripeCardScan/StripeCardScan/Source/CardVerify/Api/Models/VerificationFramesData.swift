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
    let imageData: String
    /// The bounds of the card view finder (measured in pixels) as a percent
    let viewfinderMargins: ViewFinderMargins
}

/*
 Bounds of the card view finder (measured in pixels) as a percent
 For example: Left can 20 which means the left bound is 20% of the total width

 ---------------------------------------
 |                   |                  |
 |                 upper                |
 |                   |                  |
 |      -------------------------       |
 |      |                       |       |
 |      |                       |       |
 |-left-|                       |-right-|
 |      |--4242 4242 4242 4242--|       |
 |      |          05/23        |       |
 |      -------------------------       |
 |                   |                  |
 |                 lower                |
 |                   |                  |
 ----------------------------------------
 */
struct ViewFinderMargins: Encodable {
    let left: Int
    let upper: Int
    let right: Int
    let lower: Int
}

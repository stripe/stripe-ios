//
//  IDDetectorConstants.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/27/22.
//

import Foundation
import Vision

/// Constants used by the IDDetector
struct IDDetectorConstants {
    /**
     Images must adhere to this pixel format to be interpreted correctly by
     the document scanning models
     */
    static let requiredPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
}

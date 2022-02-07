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

    /**
     Minimum score threshold used when performing non-maximum suppression on
     the model's output
     */
    static let scoreThreshold: Float = 0.4

    /**
     Minimum intersection-over-union threshold used when performing
     non-maximum suppression on the model's output
     */
    static let iouThreshold: Float = 0.5

}

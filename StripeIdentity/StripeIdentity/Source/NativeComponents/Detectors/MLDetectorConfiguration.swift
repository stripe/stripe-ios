//
//  MLDetectorConfiguration.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import Foundation

struct MLDetectorConfiguration {
    /**
     Minimum score threshold used when performing non-maximum suppression
     on the model's output
     */
    let minScore: Float

    /**
     Minimum IOU threshold used when performing non-maximum suppression on
     the model's output
     */
    let minIOU: Float
}

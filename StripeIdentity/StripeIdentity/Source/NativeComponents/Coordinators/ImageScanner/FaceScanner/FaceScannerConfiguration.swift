//
//  FaceScannerConfiguration.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import Foundation
import CoreGraphics

@available(iOS 13, *)
extension FaceScanner {
    struct Configuration: Equatable {
        // MARK: Face Detector

        /// Score threshold for FaceDetector
        let faceDetectorMinScore: Float
        /// IOU threshold used for NMS for FaceDetector
        let faceDetectorMinIOU: Float

        // MARK: Image Quality

        /// Threshold of how centered the face bounding box is in the image
        let maxCenteredThreshold: CGPoint
        /// Min distance the face bounding box is from the edge of the image
        let minEdgeThreshold: CGFloat
        /// Min portion of the image the face bounding should cover
        let minCoverageThreshold: CGFloat
        /// Max portion of the image the face bounding should cover
        let maxCoverageThreshold: CGFloat

        // TODO(mludowise|IDPROD-3824): Use values from server response
        static let `default` = Configuration(
            faceDetectorMinScore: 0.8,
            faceDetectorMinIOU: 0.5,
            maxCenteredThreshold: .init(x: 0.2, y: 0.2),
            minEdgeThreshold: 0.05,
            minCoverageThreshold: 0.07,
            maxCoverageThreshold: 0.8
        )
    }
}

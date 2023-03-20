//
//  FaceScanner+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/2/22.
//

import Foundation
@_spi(STP) import StripeCore

@available(iOS 13, *)
extension FaceScanner.Configuration {
    init(from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage) {
        self.init(
            faceDetectorMinScore: selfiePageConfig.models.faceDetectorMinScore.floatValue,
            faceDetectorMinIOU: selfiePageConfig.models.faceDetectorMinIou.floatValue,
            maxCenteredThreshold: .init(
                x: selfiePageConfig.maxCenteredThresholdX,
                y: selfiePageConfig.maxCenteredThresholdY
            ),
            minEdgeThreshold: selfiePageConfig.minEdgeThreshold,
            minCoverageThreshold: selfiePageConfig.minCoverageThreshold,
            maxCoverageThreshold: selfiePageConfig.maxCoverageThreshold
        )
    }
}

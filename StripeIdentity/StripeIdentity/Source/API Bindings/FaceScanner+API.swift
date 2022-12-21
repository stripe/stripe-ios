//
//  FaceScanner+API.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension FaceScanner.Configuration {
    init(
        from selfiePageConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    ) {
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

//
//  MLDetectorMetricsTrackerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@testable import StripeIdentity

final class MLDetectorMetricsTrackerMock: MLDetectorMetricsTrackerProtocol {
    var modelName: String
    var mockAverageMetrics: MLDetectorMetricsTracker.Metrics
    var mockNumFrames: Int
    var getPerformanceMetricsCallback: (() -> Void)?

    init(
        modelName: String,
        mockAverageMetrics: MLDetectorMetricsTracker.Metrics,
        mockNumFrames: Int
    ) {
        self.modelName = modelName
        self.mockAverageMetrics = mockAverageMetrics
        self.mockNumFrames = mockNumFrames
    }

    func trackScan(inferenceStart: Date, inferenceEnd: Date, postProcessEnd: Date) {}

    func reset() {}

    func getPerformanceMetrics() async -> (
        averageMetrics: MLDetectorMetricsTracker.Metrics,
        numFrames: Int
    ) {
        getPerformanceMetricsCallback?()
        return (mockAverageMetrics, mockNumFrames)
    }
}

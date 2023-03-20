//
//  MLDetectorMetricsTrackerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 6/17/22.
//

import Foundation
@testable import StripeIdentity

final class MLDetectorMetricsTrackerMock: MLDetectorMetricsTrackerProtocol {
    var modelName: String
    var mockAverageMetrics: MLDetectorMetricsTracker.Metrics
    var mockNumFrames: Int

    init(
        modelName: String,
        mockAverageMetrics: MLDetectorMetricsTracker.Metrics,
        mockNumFrames: Int
    ) {
        self.modelName = modelName
        self.mockAverageMetrics = mockAverageMetrics
        self.mockNumFrames = mockNumFrames
    }

    func trackScan(inferenceStart: Date, inferenceEnd: Date, postProcessEnd: Date) { }

    func reset() { }

    func getPerformanceMetrics(
        completeOn queue: DispatchQueue,
        completion: @escaping (_ averageMetrics: MLDetectorMetricsTracker.Metrics, _ numFrames: Int) -> Void
    ) {
        completion(mockAverageMetrics, mockNumFrames)
    }
}

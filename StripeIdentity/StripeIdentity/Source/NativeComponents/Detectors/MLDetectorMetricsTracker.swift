//
//  MLDetectorMetricsTracker.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Dependency-injectable protocol for DetectorMetricsTracker
protocol MLDetectorMetricsTrackerProtocol {
    var modelName: String { get }

    func trackScan(
        inferenceStart: Date,
        inferenceEnd: Date,
        postProcessEnd: Date
    )

    func reset()

    /// Synchronous, so a read made before `reset()` sees the metrics from before the reset.
    func getPerformanceMetrics() -> (
        averageMetrics: MLDetectorMetricsTracker.Metrics,
        numFrames: Int
    )
}

/// Helper class to track performance metrics for detectors using ML models
final class MLDetectorMetricsTracker: MLDetectorMetricsTrackerProtocol {

    struct Metrics {
        /// Time it takes to perform inference
        let inference: TimeInterval
        /// Time it takes to perform post-processing
        let postProcess: TimeInterval
    }

    /// Owns and serializes all mutable metrics state.
    private final class State: @unchecked Sendable {
        private let queue = DispatchQueue(
            label: "com.stripe.identity.metrics-tracker",
            target: .global(qos: .userInitiated)
        )
        private var scanMetrics: [Metrics] = []

        func trackScan(
            inferenceStart: Date,
            inferenceEnd: Date,
            postProcessEnd: Date
        ) {
            queue.async {
                self.scanMetrics.append(
                    .init(
                        inference: inferenceEnd.timeIntervalSince(inferenceStart),
                        postProcess: postProcessEnd.timeIntervalSince(inferenceEnd)
                    )
                )
            }
        }

        func reset() {
            queue.async {
                self.scanMetrics = []
            }
        }

        func getPerformanceMetrics() -> (
            averageMetrics: Metrics,
            numFrames: Int
        ) {
            queue.sync {
                let averageMetrics = Metrics(
                    inference: self.scanMetrics.average(with: { $0.inference }),
                    postProcess: self.scanMetrics.average(with: { $0.postProcess })
                )
                return (averageMetrics, self.scanMetrics.count)
            }
        }
    }

    private let state = State()

    /// Name of the model used for logging purposes
    let modelName: String

    init(
        modelName: String
    ) {
        self.modelName = modelName
    }

    func trackScan(
        inferenceStart: Date,
        inferenceEnd: Date,
        postProcessEnd: Date
    ) {
        state.trackScan(
            inferenceStart: inferenceStart,
            inferenceEnd: inferenceEnd,
            postProcessEnd: postProcessEnd
        )
    }

    func reset() {
        state.reset()
    }

    func getPerformanceMetrics() -> (
        averageMetrics: Metrics,
        numFrames: Int
    ) {
        state.getPerformanceMetrics()
    }
}

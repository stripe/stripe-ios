//
//  MLDetectorMetricsTracker.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/15/22.
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

    func getPerformanceMetrics(
        completeOn queue: DispatchQueue,
        completion: @escaping (_ averageMetrics: MLDetectorMetricsTracker.Metrics, _ numFrames: Int) -> Void
    )
}

/**
 Helper class to track performance metrics for detectors using ML models
 */
final class MLDetectorMetricsTracker: MLDetectorMetricsTrackerProtocol {

    struct Metrics {
        /// Time it takes to perform inference
        let inference: TimeInterval
        /// Time it takes to perform post-processing
        let postProcess: TimeInterval
    }

    /// Manages metrics array
    private let dispatchQueue = DispatchQueue(label: "com.stripe.identity.metrics-tracker", target: .global(qos: .userInitiated))
    /// A metric for each frame scanned by the detector
    private var scanMetrics: [Metrics] = []

    /// Name of the model used for logging purposes
    let modelName: String

    init(modelName: String) {
        self.modelName = modelName
    }

    func trackScan(
        inferenceStart: Date,
        inferenceEnd: Date,
        postProcessEnd: Date
    ) {
        dispatchQueue.async { [weak self] in
            self?.scanMetrics.append(.init(
                inference: inferenceEnd.timeIntervalSince(inferenceStart),
                postProcess: postProcessEnd.timeIntervalSince(inferenceEnd)
            ))
        }
    }

    func reset() {
        dispatchQueue.async { [weak self] in
            self?.scanMetrics = []
        }
    }

    func getPerformanceMetrics(
        completeOn completeOnQueue: DispatchQueue,
        completion: @escaping (_ averageMetrics: Metrics, _ numFrames: Int) -> Void
    ) {
        dispatchQueue.async {
            let averageMetrics = Metrics(
                inference: self.scanMetrics.average(with: { $0.inference }),
                postProcess: self.scanMetrics.average(with: { $0.postProcess })
            )
            let numFrames = self.scanMetrics.count

            completeOnQueue.async {
                completion(averageMetrics, numFrames)
            }
        }
    }
}

//
//  VisionBasedDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import Vision

// MARK: - VisionBasedDetector

/// A Detector that scans an image using a VisionRequest

protocol VisionBasedDetector {
    associatedtype Configuration
    associatedtype Output: VisionBasedDetectorOutput where Output.Detector == Self

    /// Configuration for this detector
    var configuration: Configuration { get }

    /// Tracks performance metrics for this detector
    var metricsTracker: MLDetectorMetricsTracker? { get }

    /// Called every time a scan is attempted. If a scan should be skipped, returns
    /// the output that should be used. If a scan should not be skipped, returns nil.
    func visionBasedDetectorOutputIfSkipping() -> Output?

    /// Create a vision request for this detector
    func visionBasedDetectorMakeRequest() -> VNImageBasedRequest
}

extension VisionBasedDetector {

    /// Scans a given image and returns a future that will resolve to the
    /// detector's output.
    ///
    /// - Note:
    /// This method may take significant time to complete and will block the
    /// current thread until it's done processing the image. Never call this method
    /// from the main thread but instead dispatch to a worker queue before calling
    /// this method.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The image to scan
    ///   - regionOfInterest: A region of interest to scan within the image
    ///
    /// - Returns: The detector's output
    ///
    /// - Throws: An error if the image could not be scanned
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        regionOfInterest: CGRect? = nil
    ) throws -> Output {
        if let output = visionBasedDetectorOutputIfSkipping() {
            return output
        }

        let imageSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer
        )
        let request = visionBasedDetectorMakeRequest()
        if let regionOfInterest = regionOfInterest {
            request.regionOfInterest = regionOfInterest
        }

        // Track when inference started
        let inferenceStart = Date()

        try handler.perform([request])

        // Track when inference ended
        let inferenceEnd = Date()

        let outputResult = Result {
            try Output(
                detector: self,
                observations: request.results ?? [],
                originalImageSize: imageSize
            )
        }
        // Track when post-processing ended
        let postProcessEnd = Date()

        metricsTracker?.trackScan(
            inferenceStart: inferenceStart,
            inferenceEnd: inferenceEnd,
            postProcessEnd: postProcessEnd
        )

        return try outputResult.get()
    }
}

// MARK: - VisionBasedDetectorOutput

/// Output protocol for VisionBasedDetector

protocol VisionBasedDetectorOutput {
    associatedtype Detector: VisionBasedDetector

    init(
        detector: Detector,
        observations: [VNObservation],
        originalImageSize: CGSize
    ) throws
}

// MARK: - OptionalVisionBasedDetectorOutput

/// Optional variation of VisionBasedDetectorOutput

protocol OptionalVisionBasedDetectorOutput {
    associatedtype Detector: VisionBasedDetector

    init?(
        detector: Detector,
        observations: [VNObservation],
        originalImageSize: CGSize
    ) throws
}

extension Optional: VisionBasedDetectorOutput where Wrapped: OptionalVisionBasedDetectorOutput {
    typealias Detector = Wrapped.Detector

    init(
        detector: Detector,
        observations: [VNObservation],
        originalImageSize: CGSize
    ) throws {
        self = try Wrapped(
            detector: detector,
            observations: observations,
            originalImageSize: originalImageSize
        )
    }
}

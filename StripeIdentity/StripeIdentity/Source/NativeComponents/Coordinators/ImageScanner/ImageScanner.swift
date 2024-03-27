//
//  ImageScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import CoreMedia

/// Scans an image and returns results
protocol ImageScanner {
    associatedtype Output

    /// Metrics trackers for all of the ML models used by this scanner
    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] { get }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output

    func reset()
}

/// Type-erased ImageScanner
struct AnyImageScanner<Output> {
    typealias Completion = (Output) -> Void

    private let _getModelMetricsTrackers: () -> [MLDetectorMetricsTrackerProtocol]

    private let _scanImage:
        (
            _ pixelBuffer: CVPixelBuffer,
            _ sampleBuffer: CMSampleBuffer,
            _ cameraProperties: CameraSession.DeviceProperties?
        ) throws -> Output

    private let _reset: () -> Void

    init<ImageScannerType: ImageScanner>(
        _ imageScanner: ImageScannerType
    ) where ImageScannerType.Output == Output {
        _getModelMetricsTrackers = {
            return imageScanner.mlModelMetricsTrackers
        }
        _scanImage = { pixelBuffer, sampleBuffer, cameraProperties in
            try imageScanner.scanImage(
                pixelBuffer: pixelBuffer,
                sampleBuffer: sampleBuffer,
                cameraProperties: cameraProperties
            )
        }
        _reset = {
            imageScanner.reset()
        }
    }

    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] {
        return _getModelMetricsTrackers()
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output {
        return try _scanImage(pixelBuffer, sampleBuffer, cameraProperties)
    }

    func reset() {
        _reset()
    }
}

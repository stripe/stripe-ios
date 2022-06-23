//
//  ImageScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import Foundation

import CoreVideo
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

/// Scans an image and returns results
protocol ImageScanner {
    associatedtype Output

    /// Metrics trackers for all of the ML models used by this scanner
    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] { get }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output

    func reset()
}

/// Type-erased ImageScanner
struct AnyImageScanner<Output> {
    typealias Completion = (Output) -> Void

    private let _getModelMetricsTrackers: () -> [MLDetectorMetricsTrackerProtocol]

    private let _scanImage: (
        _ pixelBuffer: CVPixelBuffer,
        _ cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output
    
    private let _reset: () -> Void


    init<ImageScannerType: ImageScanner>(
        _ imageScanner: ImageScannerType
    ) where ImageScannerType.Output == Output {
        _getModelMetricsTrackers = {
            return imageScanner.mlModelMetricsTrackers
        }
        _scanImage = { pixelBuffer, cameraProperties in
            try imageScanner.scanImage(
                pixelBuffer: pixelBuffer,
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
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output {
        return try _scanImage(pixelBuffer, cameraProperties)
    }

    func reset() {
        _reset()
    }
}

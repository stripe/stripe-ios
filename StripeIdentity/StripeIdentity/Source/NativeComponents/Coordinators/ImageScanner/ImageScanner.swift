//
//  ImageScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreMedia
import CoreVideo
import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore

/// Scans an image and returns results
protocol ImageScanner {
    associatedtype Output

    /// Metrics trackers for all of the ML models used by this scanner
    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] { get }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) -> Future<Output>

    func reset()
}

/// Type-erased ImageScanner
struct AnyImageScanner<Output> {
    typealias Completion = (Output) -> Void

    // Model loading caches this wrapper. All copies must share frame admission
    // and reset ordering, even when capture screens use different managers.
    let processingCoordinator = ImageScannerProcessingCoordinator()

    private let _getModelMetricsTrackers: () -> [MLDetectorMetricsTrackerProtocol]

    private let _scanImage:
        (
            _ pixelBuffer: CVPixelBuffer,
            _ sampleBuffer: CMSampleBuffer,
            _ cameraProperties: CameraSession.DeviceProperties?
        ) -> Future<Output>

    private let _reset: () -> Void

    init<ImageScannerType: ImageScanner>(
        _ imageScanner: ImageScannerType
    ) where ImageScannerType.Output == Output {
        _getModelMetricsTrackers = {
            return imageScanner.mlModelMetricsTrackers
        }
        _scanImage = { pixelBuffer, sampleBuffer, cameraProperties in
            return imageScanner.scanImage(
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
    ) -> Future<Output> {
        return _scanImage(pixelBuffer, sampleBuffer, cameraProperties)
    }

    func reset() {
        _reset()
    }
}

/// Coordinates work for a scanner shared between capture sessions.
final class ImageScannerProcessingCoordinator {
    let processingQueue = DispatchQueue(
        label: "com.stripe.identity.image-scanner.processing",
        qos: .userInitiated,
        autoreleaseFrequency: .workItem
    )

    // Keep admission closed through result delivery so a busy UI cannot
    // accumulate images. Only short state transitions take this lock.
    private let admissionLock = NSLock()
    private var isProcessingFrame = false
    private var pendingResetCount = 0
    private let frameGroup = DispatchGroup()
    private let resetGroup = DispatchGroup()

    func beginFrame() -> Bool {
        admissionLock.lock()
        defer { admissionLock.unlock() }

        guard !isProcessingFrame, pendingResetCount == 0 else {
            return false
        }
        isProcessingFrame = true
        frameGroup.enter()
        return true
    }

    func finishFrame() {
        admissionLock.lock()
        defer { admissionLock.unlock() }

        isProcessingFrame = false
        frameGroup.leave()
    }

    func reset(
        work: @escaping () -> Void,
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        admissionLock.lock()
        pendingResetCount += 1
        resetGroup.enter()
        admissionLock.unlock()

        frameGroup.notify(queue: processingQueue) {
            work()

            self.admissionLock.lock()
            self.pendingResetCount -= 1
            self.resetGroup.leave()
            self.admissionLock.unlock()

            queue.async(execute: completion)
        }
    }

    func whenReady(completeOn queue: DispatchQueue, completion: @escaping () -> Void) {
        resetGroup.notify(queue: queue) {
            // Another session can request a reset while this notification waits
            // for its delivery queue. Recheck before reporting readiness.
            self.admissionLock.lock()
            let isReady = self.pendingResetCount == 0
            self.admissionLock.unlock()

            if isReady {
                completion()
            } else {
                self.whenReady(completeOn: queue, completion: completion)
            }
        }
    }
}

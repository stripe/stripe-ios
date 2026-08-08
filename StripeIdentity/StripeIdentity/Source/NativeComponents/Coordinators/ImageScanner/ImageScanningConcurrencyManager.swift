//
//  ImageScanningConcurrencyManager.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreMedia
import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore

let kConcurrentImageScannerDefaultMaxConcurrentScans: Int = 2

/// Dependency-injectable protocol for ImageScanningConcurrencyManager
protocol ImageScanningConcurrencyManagerProtocol {
    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        completion: @escaping (ScannerOutput) -> Void
    )

    func reset()

    func getPerformanceMetrics() async -> (
        averageFPS: Double?,
        numFramesScanned: Int
    )
}

/// Manages scanning images using an ImageScanner concurrently while optimizing the
/// maximum number of concurrent image scans.
final class ImageScanningConcurrencyManager: ImageScanningConcurrencyManagerProtocol {

    /// Owns and serializes all mutable performance metrics state.
    private final class PerformanceMetricsTracker: @unchecked Sendable {
        private let queue = DispatchQueue(
            label: "com.stripe.identity.concurrent-image-scanner.perf",
            target: .global(qos: .userInitiated)
        )
        private var firstScanStartTime: Date?
        private var lastScanEndTime: Date?
        private var numFramesScanned = 0

        func trackScanStarted(at startTime: Date) {
            queue.async {
                self.firstScanStartTime = self.firstScanStartTime ?? startTime
            }
        }

        func trackScanEnded(at endTime: Date) {
            queue.async {
                self.lastScanEndTime = endTime
                self.numFramesScanned += 1
            }
        }

        func reset() {
            queue.async {
                self.firstScanStartTime = nil
                self.lastScanEndTime = nil
                self.numFramesScanned = 0
            }
        }

        func getPerformanceMetrics() async -> (
            averageFPS: Double?,
            numFramesScanned: Int
        ) {
            await withCheckedContinuation { continuation in
                queue.async {
                    var averageFPS: Double?
                    if let firstScanStartTime = self.firstScanStartTime,
                        let lastScanEndTime = self.lastScanEndTime
                    {
                        averageFPS =
                            Double(self.numFramesScanned)
                            / lastScanEndTime.timeIntervalSince(firstScanStartTime)
                    }

                    continuation.resume(
                        returning: (averageFPS, self.numFramesScanned)
                    )
                }
            }
        }
    }

    private let performanceMetricsTracker = PerformanceMetricsTracker()

    /// Detectors will perform scans concurrently to optimize CPU and GPU overlap.
    /// No more than `maxConcurrentScans` tasks will run on this queue.
    let concurrentQueue = DispatchQueue(
        label: "com.stripe.identity.concurrent-image-scanner",
        attributes: .concurrent
    )

    /// Semaphore used to block the current thread until detectors have completed
    private let semaphore: DispatchSemaphore

    private let analyticsClient: IdentityAnalyticsClient
    private let scannerName: IdentityAnalyticsClient.ScannerName
    private let screenName: IdentityAnalyticsClient.ScreenName
    private let sheetController: VerificationSheetControllerProtocol

    init(
        sheetController: VerificationSheetControllerProtocol,
        scannerName: IdentityAnalyticsClient.ScannerName,
        screenName: IdentityAnalyticsClient.ScreenName,
        maxConcurrentScans: Int = kConcurrentImageScannerDefaultMaxConcurrentScans
    ) {
        self.analyticsClient = sheetController.analyticsClient
        self.scannerName = scannerName
        self.screenName = screenName
        self.sheetController = sheetController
        self.semaphore = DispatchSemaphore(value: maxConcurrentScans)
    }

    /// Scans a camera frame and calls a completion block with the scanned output
    ///
    /// - Note:
    /// This can potentially block the current thread until the scan is complete.
    ///
    /// If `scanImage` is called concurrently multiple times, it will block the
    /// caller thread until the previous calls have completed such that no more
    /// than `maxConcurrentScans` are performing concurrently.
    ///
    /// This method is meant to be called from a concurrent video capture thread
    /// (e.g. `AVCaptureVideoDataOutputSampleBufferDelegate.captureOutput`) so that
    /// camera frames are dropped while the scanner is blocking the video capture
    /// thread, ensuring only `maxConcurrentScans` number of pixel buffers are
    /// being retained.
    ///
    /// - Parameters:
    ///   - scanner: An image scanner to scan the image with
    ///   - pixelBuffer: Image to scan
    ///   - cameraSession: The CameraSession that the image was captured from
    ///   - completionQueue: DispatchQueue to call the completion block on
    ///   - completion: Executed after the image has been analyzed
    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        completion: @escaping (ScannerOutput) -> Void
    ) {
        assert(!Thread.isMainThread, "`scanImage` should not be called from the main thread")

        // Get camera session properties immediately before the camera state changes
        let cameraProperties = cameraSession.getCameraProperties()

        let wrappedCompletion: (ScannerOutput) -> Void = { output in
            completionQueue.async {
                completion(output)
            }
        }

        // Track when the scan started
        let scanStartTime = Date()
        performanceMetricsTracker.trackScanStarted(at: scanStartTime)

        semaphore.wait()
        concurrentQueue.async {
            defer { self.semaphore.signal() }

            do {
                let scannerOutput = try scanner.scanImage(
                    pixelBuffer: pixelBuffer,
                    sampleBuffer: sampleBuffer,
                    cameraProperties: cameraProperties
                )
                wrappedCompletion(scannerOutput)
            } catch {
                self.analyticsClient.logGenericError(
                    error: error,
                    additionalMetadata: [
                        "error_context": "image_scan",
                        "scanner_name": self.scannerName.rawValue,
                        "screen_name": self.screenName.rawValue,
                    ],
                    sheetController: self.sheetController
                )
            }

            // Track when the scan ended
            let scanEndTime = Date()
            self.performanceMetricsTracker.trackScanEnded(at: scanEndTime)
        }
    }

    func reset() {
        performanceMetricsTracker.reset()
    }

    func getPerformanceMetrics() async -> (
        averageFPS: Double?,
        numFramesScanned: Int
    ) {
        await performanceMetricsTracker.getPerformanceMetrics()
    }
}

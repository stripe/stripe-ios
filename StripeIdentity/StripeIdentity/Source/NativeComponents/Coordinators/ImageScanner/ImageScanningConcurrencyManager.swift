//
//  ImageScanningConcurrencyManager.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import Foundation
import Vision
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

let kConcurrentImageScannerDefaultMaxConcurrentScans: Int = 2

/// Dependency-injectable protocol for ImageScanningConcurrencyManager
protocol ImageScanningConcurrencyManagerProtocol {
    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        completion: @escaping (ScannerOutput) -> Void
    )

    func reset()

    func getPerformanceMetrics(
        completeOn queue: DispatchQueue,
        completion: @escaping (_ averageFPS: Double?, _ numFramesScanned: Int) -> Void
    )
}

/**
 Manages scanning images using an ImageScanner concurrently while optimizing the
 maximum number of concurrent image scans.
 */
final class ImageScanningConcurrencyManager: ImageScanningConcurrencyManagerProtocol {

    /// Manages stateful properties used to track performance metrics
    private let perfQueue = DispatchQueue(label: "com.stripe.identity.concurrent-image-scanner.perf", target: .global(qos: .userInitiated))

    // Properties used to track performance metrics.
    // These should only be modified from the perfQueue
    private var perfFirstScanStartTime: Date?
    private var perfLastScanEndTime: Date?
    private var perfNumFramesScanned = 0

    /// Detectors will perform scans concurrently to optimize CPU and GPU overlap.
    /// No more than `maxConcurrentScans` tasks will run on this queue.
    let concurrentQueue = DispatchQueue(
        label: "com.stripe.identity.concurrent-image-scanner",
        attributes: .concurrent
    )
    /// Semaphore used to block the current thread until detectors have completed
    private let semaphore: DispatchSemaphore

    private let analyticsClient: IdentityAnalyticsClient

    init(
        analyticsClient: IdentityAnalyticsClient,
        maxConcurrentScans: Int = kConcurrentImageScannerDefaultMaxConcurrentScans
    ) {
        self.analyticsClient = analyticsClient
        self.semaphore = DispatchSemaphore(value: maxConcurrentScans)
    }

    /**
     Scans a camera frame and calls a completion block with the scanned output

     - Note:
     This can potentially block the current thread until the scan is complete.

     If `scanImage` is called concurrently multiple times, it will block the
     caller thread until the previous calls have completed such that no more
     than `maxConcurrentScans` are performing concurrently.

     This method is meant to be called from a concurrent video capture thread
     (e.g. `AVCaptureVideoDataOutputSampleBufferDelegate.captureOutput`) so that
     camera frames are dropped while the scanner is blocking the video capture
     thread, ensuring only `maxConcurrentScans` number of pixel buffers are
     being retained.

     - Parameters:
       - scanner: An image scanner to scan the image with
       - pixelBuffer: Image to scan
       - cameraSession: The CameraSession that the image was captured from
       - completionQueue: DispatchQueue to call the completion block on
       - completion: Executed after the image has been analyzed
     */
    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
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
        perfQueue.async { [weak self] in
            self?.perfFirstScanStartTime = self?.perfFirstScanStartTime ?? scanStartTime
        }

        semaphore.wait()
        concurrentQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let output = try scanner.scanImage(
                    pixelBuffer: pixelBuffer,
                    cameraProperties: cameraProperties
                )
                wrappedCompletion(output)
            } catch {
                self.analyticsClient.logGenericError(error: error)
            }

            // Track when the scan ended
            let scanEndTime = Date()

            // Update stateful properties on perfQueue
            self.perfQueue.async { [weak self] in
                self?.perfLastScanEndTime = scanEndTime
                self?.perfNumFramesScanned += 1
            }

            self.semaphore.signal()
        }
    }

    func reset() {
        perfQueue.async { [weak self] in
            self?.perfFirstScanStartTime = nil
            self?.perfLastScanEndTime = nil
            self?.perfNumFramesScanned = 0
        }
    }

    func getPerformanceMetrics(
        completeOn completeOnQueue: DispatchQueue,
        completion: @escaping (_ averageFPS: Double?, _ numFramesScanned: Int) -> Void
    ) {
        perfQueue.async {
            var averageFPS: Double?
            if let perfFirstScanStartTime = self.perfFirstScanStartTime,
               let perfLastScanEndTime = self.perfLastScanEndTime {
                averageFPS = Double(self.perfNumFramesScanned) / perfLastScanEndTime.timeIntervalSince(perfFirstScanStartTime)
            }
            let perfNumFramesScanned = self.perfNumFramesScanned

            completeOnQueue.async {
                completion(
                    averageFPS,
                    perfNumFramesScanned
                )
            }
        }
    }
}

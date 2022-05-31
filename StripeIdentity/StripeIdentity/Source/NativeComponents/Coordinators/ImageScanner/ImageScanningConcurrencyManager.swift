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
}

/**
 Manages scanning images using an ImageScanner concurrently while optimizing the
 maximum number of concurrent image scans.
 */
final class ImageScanningConcurrencyManager: ImageScanningConcurrencyManagerProtocol {
    #if DEBUG
    /// Manages stateful properties used to log analytics
    private let analyticsQueue = DispatchQueue(label: "com.stripe.identity.concurrent-image-scanner.analytics")

    private var firstScanStartTime: Date?
    private var lastScanEndTime: Date?
    private var processedFrames = 0
    #endif

    /// Detectors will perform scans concurrently to optimize CPU and GPU overlap.
    /// No more than `maxConcurrentScans` tasks will run on this queue.
    let concurrentQueue = DispatchQueue(
        label: "com.stripe.identity.concurrent-image-scanner",
        attributes: .concurrent
    )
    /// Semaphore used to block the current thread until detectors have completed
    private let semaphore: DispatchSemaphore


    init(maxConcurrentScans: Int = kConcurrentImageScannerDefaultMaxConcurrentScans) {
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

        #if DEBUG
        let startScan = Date()
        analyticsQueue.async { [weak self] in
            self?.firstScanStartTime = self?.firstScanStartTime ?? startScan
        }
        #endif

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
                // TODO(mludowise|IDPROD-2816): log error
            }

            #if DEBUG
            // TODO(mludowise|IDPROD-3302): Log performance metrics instead of print
            let lastScanEndTime = Date()
            let scanTime = lastScanEndTime.timeIntervalSince(startScan)
            print("ScanTime: \(scanTime)")

            // Update stateful properties on analyticsQueue
            self.analyticsQueue.async { [weak self] in
                self?.lastScanEndTime = lastScanEndTime
                self?.processedFrames += 1
            }
            #endif

            self.semaphore.signal()
        }
    }

    func reset() {
        #if DEBUG
        analyticsQueue.async { [weak self] in
            // TODO(IDPROD-3302): Log this as an analytic
            guard let self = self,
                  let firstScanStartTime = self.firstScanStartTime,
                  let lastScanEndTime = self.lastScanEndTime
            else {
                return
            }
            let framesPerSecond = Float(self.processedFrames) / Float(lastScanEndTime.timeIntervalSince(firstScanStartTime))
            print("Frames per second: \(framesPerSecond)")

            self.firstScanStartTime = nil
            self.lastScanEndTime = nil
            self.processedFrames = 0
        }
        #endif
    }
}

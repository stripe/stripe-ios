//
//  ImageScanningConcurrencyManager.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore
import Vision

/// Dependency-injectable protocol for ImageScanningConcurrencyManager
protocol ImageScanningConcurrencyManagerProtocol {
    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        shouldScan: @escaping () -> Bool,
        completion: @escaping (ScannerOutput, CGImage, CameraExifMetadata?) -> Void
    )

    func reset<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    )

    func getPerformanceMetrics(
        completeOn queue: DispatchQueue,
        completion: @escaping (_ averageFPS: Double?, _ numFramesScanned: Int) -> Void
    )
}

/// Processes one camera frame at a time without blocking camera session operations.
final class ImageScanningConcurrencyManager: ImageScanningConcurrencyManagerProtocol {

    /// Manages stateful properties used to track performance metrics
    private let perfQueue = DispatchQueue(
        label: "com.stripe.identity.concurrent-image-scanner.perf",
        target: .global(qos: .userInitiated)
    )

    // Properties used to track performance metrics.
    // These should only be modified from the perfQueue
    private var perfFirstScanStartTime: Date?
    private var perfLastScanEndTime: Date?
    private var perfNumFramesScanned = 0

    private let processingQueue = DispatchQueue(
        label: "com.stripe.identity.image-scanner.processing",
        qos: .userInitiated
    )
    // Admission stays closed until result delivery finishes, so a busy UI cannot
    // accumulate images either. Only these short state transitions take the lock.
    private let admissionLock = NSLock()
    private var isProcessingFrame = false
    private var pendingResetCount = 0
    private let frameGroup = DispatchGroup()

    private let analyticsClient: IdentityAnalyticsClient
    private let scannerName: IdentityAnalyticsClient.ScannerName
    private let screenName: IdentityAnalyticsClient.ScreenName
    private let sheetController: VerificationSheetControllerProtocol

    init(
        sheetController: VerificationSheetControllerProtocol,
        scannerName: IdentityAnalyticsClient.ScannerName,
        screenName: IdentityAnalyticsClient.ScreenName
    ) {
        self.analyticsClient = sheetController.analyticsClient
        self.scannerName = scannerName
        self.screenName = screenName
        self.sheetController = sheetController
    }

    /// Attempts to scan a frame, dropping it immediately if a frame or reset is
    /// already in progress. Call from the camera session's capture callback so
    /// device properties can be captured before handing work to another queue.
    ///
    /// - Parameters:
    ///   - scanner: An image scanner to scan the image with
    ///   - pixelBuffer: Image to scan
    ///   - cameraSession: The CameraSession that the image was captured from
    ///   - completionQueue: Queue for the admission predicate and completion
    ///   - shouldScan: Checks whether this frame still belongs to an active scan
    ///   - completion: Executed after the image has been analyzed
    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        shouldScan: @escaping () -> Bool,
        completion: @escaping (ScannerOutput, CGImage, CameraExifMetadata?) -> Void
    ) {
        assert(!Thread.isMainThread, "`scanImage` should not be called from the main thread")

        guard beginFrame() else {
            return
        }

        // This accessor must remain on the camera session queue.
        let cameraProperties = cameraSession.getCameraProperties()

        completionQueue.async {
            guard shouldScan() else {
                self.finishFrame()
                return
            }

            self.processingQueue.async {
                guard let image = pixelBuffer.cgImage() else {
                    self.finishFrame()
                    return
                }
                let exifMetadata = CameraExifMetadata(sampleBuffer: sampleBuffer)

                let scanStartTime = Date()
                self.perfQueue.async {
                    self.perfFirstScanStartTime = self.perfFirstScanStartTime ?? scanStartTime
                }

                let future = scanner.scanImage(
                    pixelBuffer: pixelBuffer,
                    sampleBuffer: sampleBuffer,
                    cameraProperties: cameraProperties
                )

                future.observe(on: self.processingQueue) { result in
                    let scanEndTime = Date()
                    self.perfQueue.async {
                        self.perfLastScanEndTime = scanEndTime
                        self.perfNumFramesScanned += 1
                    }

                    switch result {
                    case .success(let scannerOutput):
                        completionQueue.async {
                            defer { self.finishFrame() }
                            completion(scannerOutput, image, exifMetadata)
                        }
                    case .failure(let error):
                        self.finishFrame()
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
                }
            }
        }
    }

    private func beginFrame() -> Bool {
        admissionLock.lock()
        defer { admissionLock.unlock() }

        guard !isProcessingFrame, pendingResetCount == 0 else {
            return false
        }
        isProcessingFrame = true
        frameGroup.enter()
        return true
    }

    private func finishFrame() {
        admissionLock.lock()
        defer { admissionLock.unlock() }

        isProcessingFrame = false
        frameGroup.leave()
    }

    /// Closes admission immediately, then resets only after the accepted frame's
    /// future and result delivery finish. Nothing waits on the camera or UI queue.
    func reset<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        admissionLock.lock()
        pendingResetCount += 1
        admissionLock.unlock()

        frameGroup.notify(queue: processingQueue) {
            scanner.reset()
            self.perfQueue.async {
                self.perfFirstScanStartTime = nil
                self.perfLastScanEndTime = nil
                self.perfNumFramesScanned = 0

                self.admissionLock.lock()
                self.pendingResetCount -= 1
                self.admissionLock.unlock()

                queue.async(execute: completion)
            }
        }
    }

    func getPerformanceMetrics(
        completeOn completeOnQueue: DispatchQueue,
        completion: @escaping (_ averageFPS: Double?, _ numFramesScanned: Int) -> Void
    ) {
        perfQueue.async {
            var averageFPS: Double?
            if let perfFirstScanStartTime = self.perfFirstScanStartTime,
                let perfLastScanEndTime = self.perfLastScanEndTime
            {
                averageFPS =
                    Double(self.perfNumFramesScanned)
                    / perfLastScanEndTime.timeIntervalSince(perfFirstScanStartTime)
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

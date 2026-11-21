//
//  ImageScanningConcurrencyManagerTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import AVFoundation
import ImageIO
@_spi(InternalOnlyAPI) import StripeCore
import UIKit
import XCTest

@testable @_spi(InternalOnlyAPI) import StripeCameraCore
@testable import StripeIdentity

final class ImageScanningConcurrencyManagerTest: XCTestCase {
    private let captureQueue = DispatchQueue(label: "ImageScanningConcurrencyManagerTest.capture")
    private let completionQueue = DispatchQueue(label: "ImageScanningConcurrencyManagerTest.completion")
    private let captureQueueKey = DispatchSpecificKey<Bool>()
    private let completionQueueKey = DispatchSpecificKey<Bool>()
    private var sampleBuffer: CMSampleBuffer!
    private var pixelBuffer: CVPixelBuffer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        captureQueue.setSpecific(key: captureQueueKey, value: true)
        completionQueue.setSpecific(key: completionQueueKey, value: true)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        sampleBuffer = try XCTUnwrap(image.convertToSampleBuffer())
        pixelBuffer = try XCTUnwrap(CMSampleBufferGetImageBuffer(sampleBuffer))
    }

    func testSlowScannerDoesNotBlockCameraControlsOrQueueAdditionalFrames() {
        // Given a detector that is still processing the first frame
        let manager = makeManager()
        let camera = CameraSessionSpy()
        let scanStarted = expectation(description: "First detector invocation started")
        let releaseScan = DispatchSemaphore(value: 0)
        defer { releaseScan.signal() }
        let scanner = ScannerSpy { [captureQueueKey, completionQueueKey] invocation, _ in
            XCTAssertNil(DispatchQueue.getSpecific(key: captureQueueKey))
            XCTAssertNil(DispatchQueue.getSpecific(key: completionQueueKey))
            XCTAssertFalse(Thread.isMainThread)
            if invocation == 1 {
                scanStarted.fulfill()
                XCTAssertEqual(releaseScan.wait(timeout: .now() + 5), .success)
            }
            return Promise(value: invocation)
        }
        let anyScanner = AnyImageScanner(scanner)
        let firstDelivered = expectation(description: "First frame delivered")
        submitFrame(to: manager, scanner: anyScanner, camera: camera) { output, _, _ in
            XCTAssertEqual(output, 1)
            firstDelivered.fulfill()
        }
        wait(for: [scanStarted], timeout: 2)

        // When more frames and a camera control operation arrive during detection
        let submittedFrames = (0..<20).map { _ in
            submitFrame(to: manager, scanner: anyScanner, camera: camera)
        }
        let controlCompleted = expectation(description: "Camera control ran while detection was blocked")
        captureQueue.async { controlCompleted.fulfill() }
        wait(for: submittedFrames + [controlCompleted], timeout: 2)

        // Then camera operations remain responsive and busy frames are discarded before metadata access
        XCTAssertEqual(scanner.scanCount, 1)
        XCTAssertEqual(camera.propertyReadCount, 1)
        releaseScan.signal()
        wait(for: [firstDelivered], timeout: 2)
        completionQueue.sync {}

        let nextDelivered = expectation(description: "Next available frame delivered")
        submitFrame(to: manager, scanner: anyScanner, camera: camera) { output, _, _ in
            XCTAssertEqual(output, 2)
            nextDelivered.fulfill()
        }
        wait(for: [nextDelivered], timeout: 2)
        XCTAssertEqual(scanner.scanCount, 2)
    }

    func testSlowResultDeliveryKeepsFrameProcessingBounded() {
        // Given a completed scan whose consumer is still using its image
        let manager = makeManager()
        let camera = CameraSessionSpy()
        let scanner = ScannerSpy { invocation, _ in Promise(value: invocation) }
        let anyScanner = AnyImageScanner(scanner)
        let deliveryStarted = expectation(description: "Result delivery started")
        let releaseDelivery = DispatchSemaphore(value: 0)
        defer { releaseDelivery.signal() }
        submitFrame(to: manager, scanner: anyScanner, camera: camera) { _, _, _ in
            deliveryStarted.fulfill()
            XCTAssertEqual(releaseDelivery.wait(timeout: .now() + 5), .success)
        }
        wait(for: [deliveryStarted], timeout: 2)

        // When new frames arrive faster than results can be consumed
        let submittedFrames = (0..<20).map { _ in
            submitFrame(to: manager, scanner: anyScanner, camera: camera)
        }
        wait(for: submittedFrames, timeout: 2)

        // Then neither new scans nor retained result images accumulate
        XCTAssertEqual(scanner.scanCount, 1)
        XCTAssertEqual(camera.propertyReadCount, 1)
        releaseDelivery.signal()
        completionQueue.sync {}

        let nextDelivered = expectation(description: "Scanning resumes after delivery returns")
        submitFrame(to: manager, scanner: anyScanner, camera: camera) { output, _, _ in
            XCTAssertEqual(output, 2)
            nextDelivered.fulfill()
        }
        wait(for: [nextDelivered], timeout: 2)
    }

    func testResetWaitsForFutureAndDeliveryAndBlocksFramesUntilResetFinishes() {
        // Given a scanner whose asynchronous result has not completed
        let manager = makeManager()
        let camera = CameraSessionSpy()
        let pendingResult = Promise<Int>()
        let scanStarted = expectation(description: "Asynchronous scan started")
        let firstDelivered = expectation(description: "Outstanding result delivered before reset")
        let resetStarted = expectation(description: "Scanner reset started after delivery")
        let releaseReset = DispatchSemaphore(value: 0)
        defer { releaseReset.signal() }
        let scanner = ScannerSpy(
            onScan: { invocation, _ in
                if invocation == 1 {
                    scanStarted.fulfill()
                    return pendingResult
                }
                return Promise(value: invocation)
            },
            onReset: {
                resetStarted.fulfill()
                XCTAssertEqual(releaseReset.wait(timeout: .now() + 5), .success)
            }
        )
        let anyScanner = AnyImageScanner(scanner)
        submitFrame(to: manager, scanner: anyScanner, camera: camera) { output, _, _ in
            XCTAssertEqual(scanner.resetCount, 0)
            XCTAssertEqual(output, 1)
            firstDelivered.fulfill()
        }
        wait(for: [scanStarted], timeout: 2)

        // When reset is requested while the future is unresolved
        let resetFinished = expectation(description: "Reset completed")
        manager.reset(with: anyScanner, completeOn: completionQueue) {
            resetFinished.fulfill()
        }
        let submittedWhileWaiting = submitFrame(to: manager, scanner: anyScanner, camera: camera)
        wait(for: [submittedWhileWaiting], timeout: 2)
        XCTAssertEqual(camera.propertyReadCount, 1)
        XCTAssertEqual(scanner.resetCount, 0)

        // Then reset follows result delivery, and admission stays closed during reset itself
        pendingResult.resolve(with: 1)
        wait(for: [firstDelivered, resetStarted], timeout: 2, enforceOrder: true)
        let submittedDuringReset = submitFrame(to: manager, scanner: anyScanner, camera: camera)
        wait(for: [submittedDuringReset], timeout: 2)
        XCTAssertEqual(scanner.scanCount, 1)
        XCTAssertEqual(camera.propertyReadCount, 1)
        releaseReset.signal()
        wait(for: [resetFinished], timeout: 2)

        let nextDelivered = expectation(description: "Fresh scan accepted after reset")
        submitFrame(to: manager, scanner: anyScanner, camera: camera) { output, _, _ in
            XCTAssertEqual(output, 2)
            nextDelivered.fulfill()
        }
        wait(for: [nextDelivered], timeout: 2)
        XCTAssertEqual(scanner.resetCount, 1)
    }

    func testSnapshotsCameraPropertiesOnCaptureQueueAndDeliversImageAndExif() {
        // Given camera properties and EXIF belonging to this captured frame
        let manager = makeManager()
        let camera = CameraSessionSpy()
        let originalProperties = camera.deviceProperties
        camera.onReadProperties = { [captureQueueKey] in
            XCTAssertEqual(DispatchQueue.getSpecific(key: captureQueueKey), true)
        }
        let exif: [CFString: Any] = [kCGImagePropertyExifBrightnessValue: 1.5]
        CMSetAttachment(
            sampleBuffer,
            key: kCGImagePropertyExifDictionary,
            value: exif as CFDictionary,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        )
        let scanner = ScannerSpy { _, properties in
            XCTAssertEqual(properties, originalProperties)
            return Promise(value: 42)
        }
        let anyScanner = AnyImageScanner(scanner)
        let metadataChanged = DispatchSemaphore(value: 0)
        defer { metadataChanged.signal() }
        let delivered = expectation(description: "Image and metadata delivered on requested queue")

        // When camera properties change after submission but before processing
        submitFrame(
            to: manager,
            scanner: anyScanner,
            camera: camera,
            shouldScan: { [completionQueueKey] in
                XCTAssertEqual(DispatchQueue.getSpecific(key: completionQueueKey), true)
                XCTAssertEqual(metadataChanged.wait(timeout: .now() + 5), .success)
                return true
            }
        ) { [completionQueueKey] output, image, metadata in
            // Then processing uses the captured properties and returns the matching image and EXIF
            XCTAssertEqual(DispatchQueue.getSpecific(key: completionQueueKey), true)
            XCTAssertEqual(output, 42)
            XCTAssertEqual(image.width, CVPixelBufferGetWidth(self.pixelBuffer))
            XCTAssertEqual(image.height, CVPixelBufferGetHeight(self.pixelBuffer))
            XCTAssertEqual(metadata?.brightnessValue, 1.5)
            delivered.fulfill()
        }
        captureQueue.async {
            camera.deviceProperties = CameraSession.DeviceProperties(
                exposureDuration: CMTime(value: 1, timescale: 60),
                cameraDeviceType: .builtInWideAngleCamera,
                isVirtualDevice: false,
                lensPosition: 1,
                exposureISO: 800,
                isAdjustingFocus: true
            )
            metadataChanged.signal()
        }
        wait(for: [delivered], timeout: 2)
        XCTAssertEqual(camera.propertyReadCount, 1)
    }

    func testRejectedFrameDoesNotRunScannerAndReleasesAdmission() {
        // Given a frame that is no longer eligible for scanning
        let manager = makeManager()
        let scanner = ScannerSpy { invocation, _ in Promise(value: invocation) }
        let anyScanner = AnyImageScanner(scanner)
        let submitted = submitFrame(to: manager, scanner: anyScanner, shouldScan: { false })
        wait(for: [submitted], timeout: 2)
        completionQueue.sync {}
        XCTAssertEqual(scanner.scanCount, 0)

        // When the next eligible frame arrives
        let delivered = expectation(description: "Frame after rejection delivered")
        submitFrame(to: manager, scanner: anyScanner) { output, _, _ in
            // Then the rejected frame has not occupied the processing slot
            XCTAssertEqual(output, 1)
            delivered.fulfill()
        }
        wait(for: [delivered], timeout: 2)
    }

    func testScannerFailureReleasesAdmissionAndLogsError() {
        // Given a scanner whose first frame fails
        let errorLogged = expectation(description: "Scanner failure logged")
        let analytics = AnalyticsSpy { eventName, _ in
            XCTAssertEqual(eventName, "generic_error")
            errorLogged.fulfill()
        }
        let manager = makeManager(analytics: analytics)
        let scanner = ScannerSpy { invocation, _ in
            if invocation == 1 {
                return Promise(error: NSError(domain: "ImageScanningConcurrencyManagerTest", code: 1))
            }
            return Promise(value: invocation)
        }
        let anyScanner = AnyImageScanner(scanner)
        submitFrame(to: manager, scanner: anyScanner)
        wait(for: [errorLogged], timeout: 2)

        // When another frame arrives after the failure
        let delivered = expectation(description: "Frame after failure delivered")
        submitFrame(to: manager, scanner: anyScanner) { output, _, _ in
            // Then scanning recovers without needing a reset
            XCTAssertEqual(output, 2)
            delivered.fulfill()
        }
        wait(for: [delivered], timeout: 2)
        XCTAssertEqual(scanner.scanCount, 2)
    }

    func testSharedScannerKeepsDifferentManagersFromOverlappingFramesAndReset() {
        // Given two capture screens using copies of the same cached scanner
        let firstManager = makeManager()
        let secondManager = makeManager()
        let camera = CameraSessionSpy()
        let pendingResult = Promise<Int>()
        let scanStarted = expectation(description: "First screen's scan started")
        let resetStarted = expectation(description: "First screen's reset started")
        let releaseReset = DispatchSemaphore(value: 0)
        defer { releaseReset.signal() }
        let scanner = ScannerSpy(
            onScan: { invocation, _ in
                if invocation == 1 {
                    scanStarted.fulfill()
                    return pendingResult
                }
                return Promise(value: invocation)
            },
            onReset: {
                resetStarted.fulfill()
                XCTAssertEqual(releaseReset.wait(timeout: .now() + 5), .success)
            }
        )
        let anyScanner = AnyImageScanner(scanner)
        let scannerCopy = anyScanner
        let firstDelivered = expectation(description: "First screen's outstanding result delivered")
        submitFrame(to: firstManager, scanner: anyScanner, camera: camera) { _, _, _ in
            firstDelivered.fulfill()
        }
        wait(for: [scanStarted], timeout: 2)

        // When the second screen tries to scan while the first still owns a frame
        let overlappingFrame = submitFrame(to: secondManager, scanner: scannerCopy, camera: camera)
        wait(for: [overlappingFrame], timeout: 2)
        XCTAssertEqual(scanner.scanCount, 1)
        XCTAssertEqual(camera.propertyReadCount, 1)

        let resetFinished = expectation(description: "First screen's reset finished")
        firstManager.reset(with: anyScanner, completeOn: completionQueue) {
            resetFinished.fulfill()
        }
        pendingResult.resolve(with: 1)
        wait(for: [firstDelivered, resetStarted], timeout: 2, enforceOrder: true)
        let frameDuringReset = submitFrame(to: secondManager, scanner: scannerCopy, camera: camera)
        wait(for: [frameDuringReset], timeout: 2)

        // Then shared admission stays closed through reset, and reopens for the next screen
        XCTAssertEqual(scanner.scanCount, 1)
        XCTAssertEqual(camera.propertyReadCount, 1)
        releaseReset.signal()
        wait(for: [resetFinished], timeout: 2)
        let nextDelivered = expectation(description: "Second screen's fresh frame delivered")
        submitFrame(to: secondManager, scanner: scannerCopy, camera: camera) { output, _, _ in
            XCTAssertEqual(output, 2)
            nextDelivered.fulfill()
        }
        wait(for: [nextDelivered], timeout: 2)
    }

    func testReadinessWaitsForEveryPendingResetOfSharedScanner() {
        // Given resets requested by two screens sharing a scanner
        let firstManager = makeManager()
        let secondManager = makeManager()
        let resetStarted = expectation(description: "Both scanner resets started")
        resetStarted.expectedFulfillmentCount = 2
        let releaseReset = DispatchSemaphore(value: 0)
        defer {
            releaseReset.signal()
            releaseReset.signal()
        }
        let scanner = ScannerSpy(
            onScan: { invocation, _ in Promise(value: invocation) },
            onReset: {
                resetStarted.fulfill()
                XCTAssertEqual(releaseReset.wait(timeout: .now() + 5), .success)
            }
        )
        let anyScanner = AnyImageScanner(scanner)
        let firstResetFinished = expectation(description: "First reset finished")
        firstManager.reset(with: anyScanner, completeOn: completionQueue) {
            firstResetFinished.fulfill()
        }
        let secondResetFinished = expectation(description: "Second reset finished")
        secondManager.reset(with: anyScanner, completeOn: completionQueue) {
            secondResetFinished.fulfill()
        }
        let ready = expectation(description: "Scanner ready after every reset")
        let readinessDelivered = DispatchSemaphore(value: 0)
        secondManager.whenReady(with: anyScanner, completeOn: completionQueue) {
            readinessDelivered.signal()
            ready.fulfill()
        }

        // When only the first reset completes
        releaseReset.signal()
        wait(for: [firstResetFinished, resetStarted], timeout: 2)

        // Then readiness remains pending until the second reset also completes
        XCTAssertEqual(readinessDelivered.wait(timeout: .now()), .timedOut)
        XCTAssertEqual(scanner.resetCount, 2)
        releaseReset.signal()
        wait(for: [secondResetFinished, ready], timeout: 2)
    }

    func testPerformanceMetricsCountCompletedFramesAndClearBeforeResetCompletes() {
        // Given two completed scans
        let manager = makeManager()
        let scanner = AnyImageScanner(ScannerSpy { invocation, _ in Promise(value: invocation) })
        for _ in 0..<2 {
            let delivered = expectation(description: "Frame delivered")
            submitFrame(to: manager, scanner: scanner) { _, _, _ in delivered.fulfill() }
            wait(for: [delivered], timeout: 2)
            completionQueue.sync {}
        }
        let beforeReset = expectation(description: "Metrics include both completed scans")
        manager.getPerformanceMetrics(completeOn: completionQueue) { averageFPS, count in
            XCTAssertEqual(count, 2)
            XCTAssertGreaterThan(averageFPS ?? 0, 0)
            beforeReset.fulfill()
        }
        wait(for: [beforeReset], timeout: 2)

        // When reset reports completion
        let resetFinished = expectation(description: "Scanner and metrics reset")
        manager.reset(with: scanner, completeOn: completionQueue) { resetFinished.fulfill() }
        wait(for: [resetFinished], timeout: 2)

        // Then no metrics from the previous attempt remain
        let afterReset = expectation(description: "Metrics cleared before completion")
        manager.getPerformanceMetrics(completeOn: completionQueue) { averageFPS, count in
            XCTAssertEqual(count, 0)
            XCTAssertNil(averageFPS)
            afterReset.fulfill()
        }
        wait(for: [afterReset], timeout: 2)

        let delivered = expectation(description: "First frame of new attempt delivered")
        submitFrame(to: manager, scanner: scanner) { _, _, _ in delivered.fulfill() }
        wait(for: [delivered], timeout: 2)
        let restarted = expectation(description: "New attempt has independent metrics")
        manager.getPerformanceMetrics(completeOn: completionQueue) { averageFPS, count in
            XCTAssertEqual(count, 1)
            XCTAssertGreaterThan(averageFPS ?? 0, 0)
            restarted.fulfill()
        }
        wait(for: [restarted], timeout: 2)
    }

    func testReadinessRechecksResetRequestedBeforeNotificationDelivery() {
        // Given a readiness notification waiting behind a busy delivery queue
        let manager = makeManager()
        let deliveryBlocked = expectation(description: "Delivery queue blocked")
        let releaseDelivery = DispatchSemaphore(value: 0)
        defer { releaseDelivery.signal() }
        completionQueue.async {
            deliveryBlocked.fulfill()
            XCTAssertEqual(releaseDelivery.wait(timeout: .now() + 5), .success)
        }
        wait(for: [deliveryBlocked], timeout: 2)
        let resetStarted = expectation(description: "Reset started before notification delivery")
        let releaseReset = DispatchSemaphore(value: 0)
        defer { releaseReset.signal() }
        let scanner = AnyImageScanner(ScannerSpy(
            onScan: { invocation, _ in Promise(value: invocation) },
            onReset: {
                resetStarted.fulfill()
                XCTAssertEqual(releaseReset.wait(timeout: .now() + 5), .success)
            }
        ))
        let ready = expectation(description: "Readiness delivered after reset")
        let readinessDelivered = DispatchSemaphore(value: 0)
        manager.whenReady(with: scanner, completeOn: completionQueue) {
            readinessDelivered.signal()
            ready.fulfill()
        }

        // When reset begins before that notification can be delivered
        let resetFinished = expectation(description: "Reset finished")
        manager.reset(with: scanner, completeOn: completionQueue) { resetFinished.fulfill() }
        wait(for: [resetStarted], timeout: 2)
        let initialNotificationProcessed = expectation(description: "Initial readiness notification rechecked")
        completionQueue.async { initialNotificationProcessed.fulfill() }
        releaseDelivery.signal()
        wait(for: [initialNotificationProcessed], timeout: 2)

        // Then readiness is deferred until the intervening reset finishes
        XCTAssertEqual(readinessDelivered.wait(timeout: .now()), .timedOut)
        releaseReset.signal()
        wait(for: [ready, resetFinished], timeout: 2)
    }

    private func makeManager(analytics: AnalyticsClientV2Protocol? = nil) -> ImageScanningConcurrencyManager {
        let sheetController: VerificationSheetControllerMock
        if let analytics {
            sheetController = VerificationSheetControllerMock(
                analyticsClient: IdentityAnalyticsClient(verificationSessionId: "", analyticsClient: analytics)
            )
        } else {
            sheetController = VerificationSheetControllerMock()
        }
        return ImageScanningConcurrencyManager(
            sheetController: sheetController,
            scannerName: .document,
            screenName: .documentCapture
        )
    }

    @discardableResult
    private func submitFrame(
        to manager: ImageScanningConcurrencyManager,
        scanner: AnyImageScanner<Int>,
        camera: CameraSessionSpy = CameraSessionSpy(),
        shouldScan: @escaping () -> Bool = { true },
        completion: @escaping (Int, CGImage, CameraExifMetadata?) -> Void = { _, _, _ in
            XCTFail("A dropped or failed frame must not be delivered")
        }
    ) -> XCTestExpectation {
        let submitted = XCTestExpectation(description: "Frame submission returned")
        let pixelBuffer = self.pixelBuffer!
        let sampleBuffer = self.sampleBuffer!
        captureQueue.async { [completionQueue] in
            manager.scanImage(
                with: scanner,
                pixelBuffer: pixelBuffer,
                sampleBuffer: sampleBuffer,
                cameraSession: camera,
                completeOn: completionQueue,
                shouldScan: shouldScan,
                completion: completion
            )
            submitted.fulfill()
        }
        return submitted
    }
}

private final class ScannerSpy: ImageScanner {
    let mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] = []
    private let lock = NSLock()
    private var recordedScanCount = 0
    private var recordedResetCount = 0
    private let onScan: (Int, CameraSession.DeviceProperties?) -> Future<Int>
    private let onReset: () -> Void

    var scanCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return recordedScanCount
    }

    var resetCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return recordedResetCount
    }

    init(
        onScan: @escaping (Int, CameraSession.DeviceProperties?) -> Future<Int>,
        onReset: @escaping () -> Void = {}
    ) {
        self.onScan = onScan
        self.onReset = onReset
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) -> Future<Int> {
        lock.lock()
        recordedScanCount += 1
        let invocation = recordedScanCount
        lock.unlock()
        return onScan(invocation, cameraProperties)
    }

    func reset() {
        lock.lock()
        recordedResetCount += 1
        lock.unlock()
        onReset()
    }
}

private final class CameraSessionSpy: CameraSessionProtocol {
    var previewView: CameraPreviewView?
    var onReadProperties: (() -> Void)?
    private let lock = NSLock()
    private var recordedPropertyReadCount = 0
    private var properties = CameraSession.DeviceProperties(
        exposureDuration: CMTime(value: 1, timescale: 30),
        cameraDeviceType: .builtInDualCamera,
        isVirtualDevice: true,
        lensPosition: 0.5,
        exposureISO: 100,
        isAdjustingFocus: false
    )

    var propertyReadCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return recordedPropertyReadCount
    }

    var deviceProperties: CameraSession.DeviceProperties {
        get {
            lock.lock()
            defer { lock.unlock() }
            return properties
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            properties = newValue
        }
    }

    func getCameraProperties() -> CameraSession.DeviceProperties? {
        onReadProperties?()
        lock.lock()
        defer { lock.unlock() }
        recordedPropertyReadCount += 1
        return properties
    }

    func configureSession(
        configuration: CameraSession.Configuration,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    ) {
        queue.async { completion(.success) }
    }

    func setVideoOrientation(orientation: AVCaptureVideoOrientation) {}

    func toggleCamera(
        to position: CameraSession.CameraPosition,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    ) {
        queue.async { completion(.success) }
    }

    func toggleTorch() {}

    func startSession(completeOn queue: DispatchQueue, completion: @escaping () -> Void) {
        queue.async(execute: completion)
    }

    func stopSession(completeOn queue: DispatchQueue, completion: @escaping () -> Void) {
        queue.async(execute: completion)
    }
}

private final class AnalyticsSpy: AnalyticsClientV2Protocol {
    let clientId = "ImageScanningConcurrencyManagerTest"
    private let onLog: (String, [String: Any]) -> Void

    init(onLog: @escaping (String, [String: Any]) -> Void) {
        self.onLog = onLog
    }

    func log(eventName: String, parameters: [String: Any]) {
        onLog(eventName, parameters)
    }
}

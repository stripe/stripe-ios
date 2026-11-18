//
//  ImageScanningSessionTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import AVKit
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCameraCoreTestUtils
import XCTest

@testable import StripeIdentity

final class ImageScanningSessionTest: XCTestCase {
    private typealias Session = ImageScanningSession<Int, Int?, Int, Int>

    private let camera = MockTestCameraSession()
    private let manager = ImageScanningConcurrencyManagerMock()
    private let scanner = ImageScannerMock<Int>(scanResult: .success(1))
    private let delegate = Delegate()

    func testStopRejectsInFlightResultsAndNewFrames() throws {
        // Given a frame captured before stopping
        let session = makeSession()
        try captureFrame(session)

        // When the result arrives while the camera is still stopping
        session.stopScanning()
        manager.respondToScan(output: 1)
        try captureFrame(session)

        // Then neither the old result nor another frame is accepted
        XCTAssertEqual(delegate.outputs, [])
        XCTAssertEqual(manager.scanCallCount, 1)
    }

    func testRestartSameClassificationRejectsPreviousAttempt() throws {
        // Given an in-flight result for the same classification as the next attempt
        let session = makeSession()
        try captureFrame(session)

        // When scanning restarts before the old result is delivered
        session.reset(to: 1)
        manager.respondToScan(output: 1)
        XCTAssertEqual(delegate.outputs, [])

        // Then a frame from the new attempt is still delivered
        try captureFrame(session)
        manager.respondToScan(output: 2)
        XCTAssertEqual(delegate.outputs, [2])
    }

    func testLateStartCompletionDoesNotStartTimeoutAfterStop() {
        // Given a camera start that has not completed
        let session = makeSession()
        session.startScanning(expectedClassification: 1)

        // When scanning stops before the camera reports it has started
        session.stopScanning()
        camera.respondToStartSession()
        drainMainQueue()

        // Then no timeout is started for the stopped attempt
        XCTAssertNil(session.timeoutTimer)
    }

    func testLateStopCompletionDoesNotNotifyRestartedSession() {
        // Given an outstanding camera stop
        let session = makeSession()
        session.stopScanning()

        // When the same classification restarts before stop completes
        session.startScanning(expectedClassification: 1)
        camera.respondToStopSession()
        drainMainQueue()

        // Then old cleanup cannot change the new attempt's UI
        XCTAssertEqual(delegate.didStopCount, 0)
        camera.respondToStartSession()
        drainMainQueue()
        XCTAssertEqual(session.timeoutTimer?.isValid, true)
        session.stopTimeoutTimer()
    }

    func testRestartInvalidatesOldTimeoutBeforeCameraStarts() throws {
        // Given an existing attempt's timeout
        let session = makeSession()
        session.startTimeoutTimer(expectedClassification: 1)
        let oldTimer = try XCTUnwrap(session.timeoutTimer)

        // When another attempt begins but its camera start has not completed
        session.startScanning(expectedClassification: 1)
        oldTimer.fire()

        // Then the previous timeout cannot end the new attempt
        XCTAssertFalse(oldTimer.isValid)
        XCTAssertEqual(session.state, .scanning(1, nil))
    }

    func testStopNotificationWaitsForCameraAndScannerReset() {
        // Given a scanner reset that is still draining its accepted frame
        manager.automaticallyCompletesReset = false
        let session = makeSession()
        session.stopScanning()

        // When the camera finishes stopping first
        camera.respondToStopSession()
        drainMainQueue()
        XCTAssertEqual(delegate.didStopCount, 0)

        // Then stop is reported only after scanner reset also finishes
        manager.completePendingResets()
        drainMainQueue()
        XCTAssertEqual(delegate.didStopCount, 1)
    }

    func testBackgroundAndForegroundRejectPreviousAttempt() throws {
        let session = makeSession()
        try captureFrame(session)

        session.appDidEnterBackground()
        session.appDidEnterForeground()
        manager.respondToScan(output: 1)

        XCTAssertEqual(delegate.outputs, [])
        try captureFrame(session)
        manager.respondToScan(output: 2)
        XCTAssertEqual(delegate.outputs, [2])
    }

    func testDelegateCanDeclineFrame() throws {
        let session = makeSession()
        delegate.shouldScan = false

        try captureFrame(session)

        XCTAssertEqual(manager.scanCallCount, 0)
        XCTAssertEqual(delegate.outputs, [])
    }

    func testDeinitResetsScannerThroughManager() {
        var session: Session? = makeSession()
        weak var releasedSession = session

        session = nil

        XCTAssertNil(releasedSession)
        XCTAssertTrue(manager.didReset)
        XCTAssertTrue(scanner.didReset)
    }

    func testQueuedFrameIsRejectedBeforeScanningAfterRestart() throws {
        // Given a real manager and a camera frame awaiting the main-thread predicate
        let realManager = ImageScanningConcurrencyManager(
            sheetController: VerificationSheetControllerMock(),
            scannerName: .document,
            screenName: .documentCapture
        )
        let session = makeSession(concurrencyManager: realManager)
        let sampleBuffer = try makeSampleBuffer()
        let captureQueue = DispatchQueue(label: "ImageScanningSessionTest.camera")
        let submitted = DispatchSemaphore(value: 0)
        captureQueue.async {
            self.captureFrame(session, sampleBuffer: sampleBuffer)
            submitted.signal()
        }
        // Keep main occupied until the frame is queued, without relying on a delay.
        XCTAssertEqual(submitted.wait(timeout: .now() + 2), .success)

        // When the same classification restarts before that predicate runs
        session.reset(to: 1)
        let reset = expectation(description: "Old frame drained and scanner reset")
        realManager.reset(with: .init(scanner), completeOn: .main) {
            reset.fulfill()
        }
        wait(for: [reset], timeout: 2)

        // Then the obsolete frame never reaches the scanner
        XCTAssertEqual(scanner.scanCallCount, 0)
        XCTAssertEqual(delegate.outputs, [])

        // ...and a new background camera callback delivers through the main-thread delegate
        let delivered = expectation(description: "New attempt delivers its frame")
        delegate.didScan = { delivered.fulfill() }
        captureQueue.async {
            self.captureFrame(session, sampleBuffer: sampleBuffer)
        }
        wait(for: [delivered], timeout: 2)
        XCTAssertEqual(scanner.scanCallCount, 1)
        XCTAssertEqual(delegate.outputs, [1])
    }

    private func makeSession(concurrencyManager: ImageScanningConcurrencyManagerProtocol? = nil) -> Session {
        let session = Session(
            initialState: .scanning(1, nil),
            initialCameraPosition: .back,
            autocaptureTimeout: 60,
            cameraSession: camera,
            scanner: .init(scanner),
            concurrencyManager: concurrencyManager ?? manager,
            cameraPermissionsManager: MockCameraPermissionsManager(),
            appSettingsHelper: MockAppSettingsHelper()
        )
        session.setDelegate(delegate: delegate)
        return session
    }

    private func captureFrame(_ session: Session) throws {
        captureFrame(session, sampleBuffer: try makeSampleBuffer())
    }

    private func makeSampleBuffer() throws -> CMSampleBuffer {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        return try XCTUnwrap(image.convertToSampleBuffer())
    }

    private func captureFrame(_ session: Session, sampleBuffer: CMSampleBuffer) {
        let output = AVCaptureVideoDataOutput()
        session.captureOutput(
            output,
            didOutput: sampleBuffer,
            from: AVCaptureConnection(inputPorts: [], output: output)
        )
    }

    private func drainMainQueue() {
        let drained = expectation(description: "Camera callbacks and their notifications delivered")
        DispatchQueue.main.async {
            DispatchQueue.main.async {
                drained.fulfill()
            }
        }
        wait(for: [drained], timeout: 2)
    }

    private final class Delegate: ImageScanningSessionDelegate {
        typealias ExpectedClassificationType = Int
        typealias ScanningStateType = Int?
        typealias CapturedDataType = Int
        typealias ScannerOutput = Int

        var shouldScan = true
        var outputs: [Int] = []
        var didStopCount = 0
        var didScan: (() -> Void)?

        func imageScanningSessionShouldScanCameraOutput(_ scanningSession: ScanningSession) -> Bool {
            XCTAssertTrue(Thread.isMainThread)
            return shouldScan
        }

        func imageScanningSessionDidScanImage(
            _ scanningSession: ScanningSession,
            image: CGImage,
            scannerOutput: Int,
            exifMetadata: CameraExifMetadata?,
            expectedClassification: Int
        ) {
            XCTAssertTrue(Thread.isMainThread)
            outputs.append(scannerOutput)
            didScan?()
        }

        func imageScanningSessionDidStopScanning(_ scanningSession: ScanningSession) {
            didStopCount += 1
        }

        func imageScanningSession(_ scanningSession: ScanningSession, cameraDidError: Error) {}
        func imageScanningSession(_ scanningSession: ScanningSession, didRequestCameraAccess isGranted: Bool?) {}
        func imageScanningSessionDidUpdate(_ scanningSession: ScanningSession) {}
        func imageScanningSessionDidReset(_ scanningSession: ScanningSession) {}
        func imageScanningSession(_ scanningSession: ScanningSession, didTimeoutForClassification classification: Int) {}
        func imageScanningSession(_ scanningSession: ScanningSession, willStartScanningForClassification classification: Int) {}
        func imageScanningSessionWillStopScanning(_ scanningSession: ScanningSession) {}
    }
}

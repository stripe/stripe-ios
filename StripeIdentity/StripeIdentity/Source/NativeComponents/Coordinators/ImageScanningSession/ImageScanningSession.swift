//
//  ImageScanningSession.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import AVKit
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

// MARK: - ScanningState

protocol ScanningState {
    static func initialValue() -> Self
}

extension Array: ScanningState {
    static func initialValue() -> [Element] {
        return []
    }
}

extension Optional: ScanningState {
    static func initialValue() -> Wrapped? {
        return nil
    }
}

// MARK: - ImageScanningSession

final class ImageScanningSession<
    ExpectedClassificationType: Equatable,
    ScanningStateType: Equatable & ScanningState,
    CapturedDataType: Equatable,
    ScannerOutput
>: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    typealias ScannerType = AnyImageScanner<ScannerOutput>

    enum State: Equatable {
        /// The user has not yet granted or denied camera access yet
        case initial
        /// Actively scanning the camera feed for a high quality image of the expected classification
        case scanning(ExpectedClassificationType, ScanningStateType)
        /// Successfully scanned the camera feed for the expected classification
        case scanned(ExpectedClassificationType, CapturedDataType)
        /// Saving the captured data
        case saving(ExpectedClassificationType, CapturedDataType)
        /// The app does not have camera access
        case noCameraAccess
        /// There was an error accessing the camera
        case cameraError
        /// Scanning timed out
        case timeout(ExpectedClassificationType)
    }

    private(set) var state: State {
        didSet {
            guard state != oldValue else {
                return
            }

            delegate?.imageScanningSessionDidUpdate(self)
        }
    }

    // MARK: Configuration Properties

    let initialCameraPosition: CameraSession.CameraPosition
    let autocaptureTimeout: TimeInterval

    // MARK: Instance Properties

    private(set) var timeoutTimer: Timer?
    private var delegate: AnyDelegate?

    // State and delegate callbacks belong to the main thread. Only this token
    // crosses into the camera callback, so it can reject frames while stopped.
    private let scanningLock = NSLock()
    private var scanningGeneration: UUID?
    private var lifecycleGeneration = UUID()
    private var pendingSetupClassification: ExpectedClassificationType?
    private var setupToResumeOnForeground: ExpectedClassificationType?
    private var needsScannerReset = false
    private var shouldStartTimeoutWhenReady = false

    // MARK: Coordinators
    let concurrencyManager: ImageScanningConcurrencyManagerProtocol
    let scanner: ScannerType
    let permissionsManager: CameraPermissionsManagerProtocol
    let cameraSession: CameraSessionProtocol
    let appSettingsHelper: AppSettingsHelperProtocol

    // MARK: Init

    init(
        initialState: State,
        initialCameraPosition: CameraSession.CameraPosition,
        autocaptureTimeout: TimeInterval,
        cameraSession: CameraSessionProtocol,
        scanner: ScannerType,
        concurrencyManager: ImageScanningConcurrencyManagerProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol,
        appSettingsHelper: AppSettingsHelperProtocol
    ) {
        self.state = initialState
        self.initialCameraPosition = initialCameraPosition
        self.autocaptureTimeout = autocaptureTimeout
        self.cameraSession = cameraSession
        self.scanner = scanner
        self.concurrencyManager = concurrencyManager
        self.permissionsManager = cameraPermissionsManager
        self.appSettingsHelper = appSettingsHelper

        super.init()

        if case .scanning = initialState {
            scanningGeneration = lifecycleGeneration
            needsScannerReset = true
        }

        addObservers()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // A frame may still be finishing after the session is released.
        if needsScannerReset {
            concurrencyManager.reset(with: scanner, completeOn: .main, completion: {})
        }
    }

    // MARK: - Internal

    func setDelegate<Delegate: ImageScanningSessionDelegate>(
        delegate: Delegate?
    )
    where
        Delegate.ExpectedClassificationType == ExpectedClassificationType,
        Delegate.ScanningStateType == ScanningStateType,
        Delegate.CapturedDataType == CapturedDataType,
        Delegate.ScannerOutput == ScannerOutput
    {
        self.delegate = delegate.map { .init($0) }
    }

    func updateScanningState(_ scanningState: ScanningStateType) {
        guard case .scanning(let expectedClassification, _) = state else {
            assertionFailure(
                "`updateScanningState` can only be called if current state is `scanning`"
            )
            return
        }

        state = .scanning(expectedClassification, scanningState)
    }

    func setStateScanned(
        expectedClassification: ExpectedClassificationType,
        capturedData: CapturedDataType
    ) {
        state = .scanned(expectedClassification, capturedData)
        stopScanning()
    }

    func setStateSaving(
        expectedClassification: ExpectedClassificationType,
        capturedData: CapturedDataType
    ) {
        state = .saving(expectedClassification, capturedData)
    }

    func reset(to classification: ExpectedClassificationType) {
        stopScanning()
        startScanning(expectedClassification: classification)

        delegate?.imageScanningSessionDidReset(self)
    }

    func stopTimeoutTimer() {
        shouldStartTimeoutWhenReady = false
        timeoutTimer?.invalidate()
    }

    func startIfNeeded(expectedClassification: ExpectedClassificationType) {
        if state == .initial, pendingSetupClassification == nil {
            setupCameraAndStartScanning(expectedClassification: expectedClassification)
        }
    }

    func startScanning(expectedClassification: ExpectedClassificationType) {
        let generation = UUID()
        lifecycleGeneration = generation
        pendingSetupClassification = nil
        setupToResumeOnForeground = nil
        needsScannerReset = true
        shouldStartTimeoutWhenReady = true
        setScanningGeneration(generation)
        timeoutTimer?.invalidate()
        self.state = .scanning(expectedClassification, .initialValue())
        guard currentScanningGeneration() == generation, case .scanning = state else { return }

        delegate?.imageScanningSession(
            self,
            willStartScanningForClassification: expectedClassification
        )
        guard currentScanningGeneration() == generation, case .scanning = state else { return }

        cameraSession.startSession(completeOn: .main) { [weak self] in
            guard let self = self,
                self.currentScanningGeneration() == generation
            else { return }
            self.concurrencyManager.whenReady(with: self.scanner, completeOn: .main) { [weak self] in
                guard let self = self,
                    self.currentScanningGeneration() == generation,
                    self.shouldStartTimeoutWhenReady
                else { return }
                self.startTimeoutTimer(expectedClassification: expectedClassification)
            }
        }
    }

    func stopScanning() {
        let generation = UUID()
        lifecycleGeneration = generation
        pendingSetupClassification = nil
        setupToResumeOnForeground = nil
        setScanningGeneration(nil)
        stopTimeoutTimer()
        delegate?.imageScanningSessionWillStopScanning(self)
        guard lifecycleGeneration == generation else { return }

        // Close frame admission immediately, including during an immediate
        // restart. Reset waits for the accepted frame without delaying the camera.
        let stopped = DispatchGroup()
        stopped.enter()
        needsScannerReset = false
        concurrencyManager.reset(with: scanner, completeOn: .main) {
            stopped.leave()
        }
        stopped.enter()
        cameraSession.stopSession(completeOn: .main) {
            stopped.leave()
        }
        stopped.notify(queue: .main) { [weak self] in
            guard let self = self,
                self.lifecycleGeneration == generation
            else { return }
            self.delegate?.imageScanningSessionDidStopScanning(self)
        }
    }

    private func currentScanningGeneration() -> UUID? {
        scanningLock.lock()
        defer { scanningLock.unlock() }
        return scanningGeneration
    }

    private func setScanningGeneration(_ generation: UUID?) {
        scanningLock.lock()
        defer { scanningLock.unlock() }
        scanningGeneration = generation
    }

    func startTimeoutTimer(expectedClassification: ExpectedClassificationType) {
        shouldStartTimeoutWhenReady = false
        timeoutTimer?.invalidate()
        let generation = lifecycleGeneration

        timeoutTimer = Timer.scheduledTimer(
            withTimeInterval: autocaptureTimeout,
            repeats: false
        ) { [weak self] _ in
            guard let self = self,
                self.currentScanningGeneration() == generation
            else { return }
            self.handleTimeout(expectedClassification: expectedClassification)
        }
    }

    // MARK: - Notifications

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - App Backgrounding

    @objc func appDidEnterBackground() {
        let interruptedSetup = pendingSetupClassification
        stopScanning()
        if state == .initial {
            setupToResumeOnForeground = interruptedSetup
        }
    }

    @objc func appDidEnterForeground() {
        let interruptedSetup = setupToResumeOnForeground
        setupToResumeOnForeground = nil
        if case .scanning(let expectedClassification, _) = state {
            startScanning(expectedClassification: expectedClassification)
        } else if state == .initial, let interruptedSetup {
            setupCameraAndStartScanning(expectedClassification: interruptedSetup)
        }
    }

    // MARK: - State Transitions

    private func setupCameraAndStartScanning(
        expectedClassification: ExpectedClassificationType
    ) {
        let generation = UUID()
        lifecycleGeneration = generation
        pendingSetupClassification = expectedClassification
        permissionsManager.requestCameraAccess(completeOnQueue: .main) { [weak self] granted in
            guard let self = self, self.lifecycleGeneration == generation else {
                return
            }

            self.delegate?.imageScanningSession(self, didRequestCameraAccess: granted)
            guard self.lifecycleGeneration == generation else { return }

            guard granted == true else {
                self.pendingSetupClassification = nil
                self.state = .noCameraAccess
                return
            }

            // Configure camera session
            // Tell the camera to automatically adjust focus to the center of
            // the image and restrict autofocus range to .near.
            self.cameraSession.configureSession(
                configuration: .init(
                    initialCameraPosition: self.initialCameraPosition,
                    initialOrientation: UIDevice.current.orientation.videoOrientation,
                    focusMode: .continuousAutoFocus,
                    focusPointOfInterest: CGPoint(x: 0.5, y: 0.5),
                    sessionPreset: .hd4K3840x2160,
                    outputSettings: [
                        (kCVPixelBufferPixelFormatTypeKey as String): Int(
                            IDDetectorConstants.mbRequiredPixelFormat
                        ),
                    ],
                    autoFocusRangeRestriction: .near
                ),
                delegate: self,
                completeOn: .main
            ) { [weak self] result in
                // A cached CameraSession configuration can complete on its
                // session queue. Keep all lifecycle and delegate work on main.
                let handleResult: () -> Void = { [weak self] in
                    self?.handleCameraSetupResult(
                        result,
                        generation: generation,
                        expectedClassification: expectedClassification
                    )
                }
                if Thread.isMainThread {
                    handleResult()
                } else {
                    DispatchQueue.main.async(execute: handleResult)
                }
            }
        }
    }

    private func handleCameraSetupResult(
        _ result: CameraSession.SetupResult,
        generation: UUID,
        expectedClassification: ExpectedClassificationType
    ) {
        guard lifecycleGeneration == generation else { return }
        pendingSetupClassification = nil

        switch result {
        case .success:
            startScanning(expectedClassification: expectedClassification)
        case .failed(let error):
            delegate?.imageScanningSession(self, cameraDidError: error)
            guard lifecycleGeneration == generation else { return }
            state = .cameraError
        }
    }

    private func handleTimeout(expectedClassification: ExpectedClassificationType) {
        stopScanning()
        state = .timeout(expectedClassification)
        delegate?.imageScanningSession(self, didTimeoutForClassification: expectedClassification)
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let generation = currentScanningGeneration(),
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }

        concurrencyManager.scanImage(
            with: scanner,
            pixelBuffer: pixelBuffer,
            sampleBuffer: sampleBuffer,
            cameraSession: cameraSession,
            completeOn: .main,
            shouldScan: { [weak self] in
                guard let self = self,
                    self.currentScanningGeneration() == generation,
                    case .scanning = self.state
                else { return false }
                let shouldScan = self.delegate?.imageScanningSessionShouldScanCameraOutput(self) != false
                guard shouldScan,
                    self.currentScanningGeneration() == generation,
                    case .scanning = self.state
                else { return false }
                return true
            }
        ) { [weak self] scannerOutput, image, exifMetadata in
            // Classification alone cannot distinguish a stopped scan from a
            // new attempt at the same document side (or another selfie attempt).
            guard let self = self,
                self.currentScanningGeneration() == generation,
                case .scanning(let expectedClassification, _) = self.state
            else {
                return
            }
            self.delegate?.imageScanningSessionDidScanImage(
                self,
                image: image,
                scannerOutput: scannerOutput,
                exifMetadata: exifMetadata,
                expectedClassification: expectedClassification
            )
        }
    }
}

// MARK: - EmptyClassificationType

/// Used as ExpectedClassificationType where expected classification doesn't apply
enum EmptyClassificationType: Equatable {
    case empty
}

extension ImageScanningSession where ExpectedClassificationType == EmptyClassificationType {

    func startIfNeeded() {
        startIfNeeded(expectedClassification: .empty)
    }

    func startScanning() {
        startScanning(expectedClassification: .empty)
    }

    func startTimeoutTimer() {
        startTimeoutTimer(expectedClassification: .empty)
    }

    func reset() {
        reset(to: .empty)
    }
}

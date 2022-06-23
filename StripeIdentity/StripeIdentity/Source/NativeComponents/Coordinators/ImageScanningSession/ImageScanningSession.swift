//
//  ImageScanningSession.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import UIKit
import AVKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

// MARK: - ScanningState

protocol ScanningState {
    static func initialValue() -> Self
}

extension Array: ScanningState {
    static func initialValue() -> Array<Element> {
        return []
    }
}

extension Optional: ScanningState {
    static func initialValue() -> Optional<Wrapped> {
        return nil
    }
}

// MARK: - ImageScanningSession

@available(iOSApplicationExtension, unavailable)
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
        case saving(CapturedDataType)
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

        addObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Reset coordinators that may be reused
        self.concurrencyManager.reset()
        self.scanner.reset()
    }

    // MARK: - Internal

    func setDelegate<Delegate: ImageScanningSessionDelegate>(
        delegate: Delegate?
    ) where Delegate.ExpectedClassificationType == ExpectedClassificationType,
            Delegate.ScanningStateType == ScanningStateType,
            Delegate.CapturedDataType == CapturedDataType,
            Delegate.ScannerOutput == ScannerOutput
    {
        self.delegate = delegate.map { .init($0) }
    }

    func updateScanningState(_ scanningState: ScanningStateType) {
        guard case let .scanning(expectedClassification, _) = state else {
            assertionFailure("`updateScanningState` can only be called if current state is `scanning`")
            return
        }

        state = .scanning(expectedClassification, scanningState)
    }

    func setStateScanned(expectedClassification: ExpectedClassificationType, capturedData: CapturedDataType) {
        state = .scanned(expectedClassification, capturedData)
        stopScanning()
    }

    func setStateSaving(_ capturedData: CapturedDataType) {
        state = .saving(capturedData)
    }

    func reset(to classification: ExpectedClassificationType) {
        stopScanning()
        startScanning(expectedClassification: classification)

        delegate?.imageScanningSessionDidReset(self)
    }

    func stopTimeoutTimer() {
        timeoutTimer?.invalidate()
    }

    func startIfNeeded(expectedClassification: ExpectedClassificationType) {
        if state == .initial {
            setupCameraAndStartScanning(expectedClassification: expectedClassification)
        }
    }

    func startScanning(expectedClassification: ExpectedClassificationType) {
        // Update the state of the PreviewView before starting the camera session,
        // otherwise the PreviewView may not update due to the DocumentScanner
        // hogging the CameraSession's sessionQueue.
        self.state = .scanning(expectedClassification, .initialValue())

        delegate?.imageScanningSession(self, willStartScanningForClassification: expectedClassification)

        cameraSession.startSession(completeOn: .main) { [weak self] in
            guard let self = self else { return }
            self.startTimeoutTimer(expectedClassification: expectedClassification)
        }
    }

    func stopScanning() {
        delegate?.imageScanningSessionWillStopScanning(self)
        timeoutTimer?.invalidate()
        cameraSession.stopSession(completeOn: .main) { [weak self] in
            guard let self = self else { return }
            self.scanner.reset()
            self.concurrencyManager.reset()
            self.delegate?.imageScanningSessionDidStopScanning(self)
        }
    }

    func startTimeoutTimer(expectedClassification: ExpectedClassificationType) {
        timeoutTimer?.invalidate()

        timeoutTimer = Timer.scheduledTimer(
            withTimeInterval: autocaptureTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.handleTimeout(expectedClassification: expectedClassification)
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
        stopScanning()
    }

    @objc func appDidEnterForeground() {
        if case let .scanning(expectedClassification, _) = state {
            startScanning(expectedClassification: expectedClassification)
        }
    }

    // MARK: - State Transitions

    private func setupCameraAndStartScanning(
        expectedClassification: ExpectedClassificationType
    ) {
        permissionsManager.requestCameraAccess(completeOnQueue: .main) { [weak self] granted in
            guard let self = self else {
                return
            }

            self.delegate?.imageScanningSession(self, didRequestCameraAccess: granted)

            guard granted == true else {
                self.state = .noCameraAccess
                return
            }

            // Configure camera session
            // Tell the camera to automatically adjust focus to the center of
            // the image
            self.cameraSession.configureSession(
                configuration: .init(
                    initialCameraPosition: self.initialCameraPosition,
                    initialOrientation: UIDevice.current.orientation.videoOrientation,
                    focusMode: .continuousAutoFocus,
                    focusPointOfInterest: CGPoint(x: 0.5, y: 0.5),
                    outputSettings: [
                        (kCVPixelBufferPixelFormatTypeKey as String): Int(IDDetectorConstants.requiredPixelFormat)
                    ]
                ),
                delegate: self,
                completeOn: .main
            ) { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                case .success:
                    self.startScanning(expectedClassification: expectedClassification)
                case .failed(let error):
                    self.delegate?.imageScanningSession(self, cameraDidError: error)
                    self.state = .cameraError
                }
            }
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
        guard delegate?.imageScanningSessionShouldScanCameraOutput(self) != false,
              case let .scanning(expectedClassification, _) = state,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let cgImage = pixelBuffer.cgImage()
        else {
            return
        }

        let exifMetadata = CameraExifMetadata(sampleBuffer: sampleBuffer)

        concurrencyManager.scanImage(
            with: scanner,
            pixelBuffer: pixelBuffer,
            cameraSession: cameraSession,
            completeOn: .main
        ) { [weak self] scannerOutput in
            // The completion block could get called after we've already found
            // a high quality image for this document side or timed out, so
            // verify that we're still scanning for the same document side
            // before handling the image.
            guard let self = self,
                  case .scanning(expectedClassification, _) = self.state
            else {
                return
            }
            self.delegate?.imageScanningSessionDidScanImage(
                self,
                image: cgImage,
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

@available(iOSApplicationExtension, unavailable)
extension ImageScanningSession where ExpectedClassificationType == EmptyClassificationType {

    func setStateScanned(capturedData: CapturedDataType) {
        setStateScanned(expectedClassification: .empty, capturedData: capturedData)
    }

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

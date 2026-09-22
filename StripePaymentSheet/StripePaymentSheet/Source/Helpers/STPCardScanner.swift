//
//  STPCardScanner.swift
//  StripePaymentSheet
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
#if !os(visionOS)

import AVFoundation
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
import UIKit
import Vision

@available(macCatalyst 14.0, *)
protocol STPCardScannerDelegate: AnyObject {
    // Called when card scanner fetches card details successfully
    func cardScanner(_ scanner: STPCardScanner, didCompleteWith cardParams: STPPaymentMethodCardParams)
    // Called when an error occurs
    func cardScannerDidError(_ scanner: STPCardScanner)
}

@available(macCatalyst 14.0, *)
@objc(STPCardScanner)
class STPCardScanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: - Constants
    private static let minimumValidScans = 2
    private static let scanningTimeout: TimeInterval = 0.6

    // iOS will kill the app if it tries to request the camera without an NSCameraUsageDescription
    private static let cardScanningAvailableCameraHasUsageDescription = {
        return
            (Bundle.main.infoDictionary?["NSCameraUsageDescription"] != nil
            || Bundle.main.localizedInfoDictionary?["NSCameraUsageDescription"] != nil)
    }()

    static var cardScanningAvailable: Bool {
        // Always allow in tests:
        if NSClassFromString("XCTest") != nil {
            return true
        }
        return cardScanningAvailableCameraHasUsageDescription
    }

    // MARK: - Properties
    weak var cameraView: STPCameraView?

    private var feedbackGenerator: UINotificationFeedbackGenerator?

    @objc var deviceOrientation: UIDeviceOrientation {
        get {
            return stp_deviceOrientation
        }
        set(newDeviceOrientation) {
            stp_deviceOrientation = newDeviceOrientation

            // This is an optimization for portrait mode: The card will be centered in the screen,
            // so we can ignore the top and bottom. We'll use the whole frame in landscape.
            let kSTPCardScanningScreenCenter = CGRect(
                x: 0, y: CGFloat(0.3), width: 1, height: CGFloat(0.4))

            // iOS camera image data is returned in LandcapeLeft orientation by default. We'll flip it as needed:
            switch newDeviceOrientation {
            case .portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
                textOrientation = .left
                regionOfInterest = kSTPCardScanningScreenCenter
            case .landscapeLeft:
                videoOrientation = .landscapeRight
                textOrientation = .up
                regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
            case .landscapeRight:
                videoOrientation = .landscapeLeft
                textOrientation = .down
                regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
            case .portrait, .faceUp, .faceDown, .unknown:
                fallthrough
            default:
                videoOrientation = .portrait
                textOrientation = .right
                regionOfInterest = kSTPCardScanningScreenCenter
            }
            cameraView?.videoPreviewLayer.connection?.videoOrientation = videoOrientation
        }
    }

    private weak var delegate: STPCardScannerDelegate?
    private var captureSession: AVCaptureSession?
    private let captureSessionQueue = DispatchQueue(label: "com.stripe.CardScanning.CaptureSessionQueue")
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?
    private var textRequest: VNRecognizeTextRequest?
    // Cancellation must be visible even while the camera queue is busy. Never do camera or UI work under this lock.
    private let scanningStateLock = NSLock()
    private var isScanning = false

    private var timeoutTime: Date?
    private var didTimeout: Bool {
        if let timeoutTime = timeoutTime {
            return timeoutTime <= Date()
        }
        return false
    }

    private var stp_deviceOrientation: UIDeviceOrientation!
    private var videoOrientation: AVCaptureVideoOrientation!
    private var textOrientation: CGImagePropertyOrientation!
    private var regionOfInterest = CGRect.zero
    private var detectedNumbers = NSCountedSet()
    private var detectedExpirations = NSCountedSet()
    private var startTime: Date?

    // MARK: - Initialization
    init(delegate: STPCardScannerDelegate?) {
        super.init()
        self.delegate = delegate
        deviceOrientation = UIDevice.current.orientation
    }

    deinit {
        // Releasing the last scanner reference can happen on the main queue too.
        // Retain only the camera objects until shutdown completes; deinit must not capture self.
        let captureSession = captureSession
        let videoDataOutput = videoDataOutput
        captureSessionQueue.async {
            videoDataOutput?.setSampleBufferDelegate(nil, queue: nil)
            captureSession?.stopRunning()
        }
    }

    // MARK: - Public Methods
    func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        scanningStateLock.lock()
        guard !isScanning else {
            scanningStateLock.unlock()
            return
        }

        isScanning = true
        startTime = Date()
        timeoutTime = nil

        // Updating state and enqueueing must happen under the same lock. Otherwise a new start could
        // observe that the old scan finished and enter the queue before the old scan's stop operation.
        captureSessionQueue.async { [weak self] in
            guard let self, self.scanIsActive() else { return }

            #if targetEnvironment(simulator)
            // Camera not supported on Simulator
            self.finishWithError()
            return
            #else
            self.detectedNumbers = NSCountedSet()
            self.detectedExpirations = NSCountedSet()
            guard self.setupCamera(), let captureSession = self.captureSession else {
                self.finishWithError()
                return
            }
            // Keep startup separate from configuration so setup failures cannot attach a partial session.
            // Cancellation during setup skips startup. If startRunning is already in progress, the queued stop handles it.
            guard self.scanIsActive() else { return }

            captureSession.startRunning()
            guard self.scanIsActive() else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self, self.scanIsActive() else { return }
                // Capture this session instead of reading a property that a later setup can replace.
                self.cameraView?.captureSession = captureSession
                self.cameraView?.videoPreviewLayer.connection?.videoOrientation = self.videoOrientation
            }
            #endif
        }
        scanningStateLock.unlock()

        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPCardScanner.self)
        feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        finish(didSucceed: false)
    }

    private func finishWithError() {
        finish(didSucceed: false) { [weak self] in
            guard let self else { return }
            self.delegate?.cardScannerDidError(self)
        }
    }

    // MARK: - Camera Setup
    private func setupCamera() -> Bool {
        dispatchPrecondition(condition: .onQueue(captureSessionQueue))
        textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self, self.scanIsActive() else { return }

            if error != nil {
                self.finishWithError()
                return
            }
            self.processVNRequest(request)
        }

        // The triple and dualWide cameras have a 0.5x lens for better macro focus.
        // If neither are available, use the default wide angle camera.
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
                                                                    [.builtInTripleCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
                                                                mediaType: .video, position: .back)
        guard let captureDevice = discoverySession.devices.first else {
            return false
        }
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1920x1080

        var deviceInput: AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            return false
        }

        if let deviceInput = deviceInput {
            if captureSession?.canAddInput(deviceInput) ?? false {
                captureSession?.addInput(deviceInput)
            } else {
                return false
            }
        }

        videoDataOutputQueue = DispatchQueue(label: "com.stripe.CardScanning.VideoDataOutputQueue")
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        // This is the recommended pixel buffer format for Vision:
        videoDataOutput?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        ]

        if let videoDataOutput = videoDataOutput {
            if captureSession?.canAddOutput(videoDataOutput) ?? false {
                captureSession?.addOutput(videoDataOutput)
            } else {
                return false
            }
        }

        // This improves recognition quality, but means the VideoDataOutput buffers won't match what we're seeing on screen.
        videoDataOutput?.connection(with: .video)?.preferredVideoStabilizationMode = .auto

        do {
            // The device lock only protects changes to camera settings. Holding it for the whole scan
            // makes teardown responsible for unlocking a device that setup may not have locked yet.
            try captureDevice.lockForConfiguration()
            defer { captureDevice.unlockForConfiguration() }
            if captureDevice.isAutoFocusRangeRestrictionSupported {
                captureDevice.autoFocusRangeRestriction = .near
            }
        } catch {
        }
        return true
    }

    // MARK: - Video Processing
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if !scanIsActive() {
            return
        }
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        if pixelBuffer == nil {
            return
        }
        textRequest?.recognitionLevel = .accurate
        textRequest?.usesLanguageCorrection = false
        textRequest?.regionOfInterest = regionOfInterest
        var handler: VNImageRequestHandler?
        if let pixelBuffer = pixelBuffer {
            handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
        }
        do {
            try handler?.perform([textRequest].compactMap { $0 })
        } catch {
        }
    }

    private func processVNRequest(_ request: VNRequest) {
        var allNumbers: [String] = []
        for observation in request.results ?? [] {
            guard let observation = observation as? VNRecognizedTextObservation else {
                continue
            }
            let candidates = observation.topCandidates(5)
            let topCandidate = candidates.first?.string
            if STPCardValidator.sanitizedNumericString(for: topCandidate ?? "").count >= 4 {
                allNumbers.append(topCandidate ?? "")
            }
            for recognizedText in candidates {
                let possibleNumber = STPCardValidator.sanitizedNumericString(
                    for: recognizedText.string)
                if possibleNumber.count < 4 {
                    continue  // This probably isn't something we're interested in, so don't bother processing it.
                }

                // First strategy: We check if Vision sent us a number in a group on its own. If that fails, we'll try
                // to catch it later when we iterate over all the numbers.
                if STPCardValidator.validationState(
                    forNumber: possibleNumber, validatingCardBrand: true)
                    == .valid
                {
                    addDetectedNumber(possibleNumber)
                } else if let sanitizedExpiration = STPStringUtils.sanitizedExpirationDateFromOCRString(recognizedText.string) {
                    handlePossibleExpirationDate(sanitizedExpiration)
                } else if possibleNumber.count >= 4 && possibleNumber.count <= 6
                    && STPStringUtils.stringMayContainExpirationDate(recognizedText.string)
                {
                    // Try to parse anything that looks like an expiration date.
                    let expirationString = STPStringUtils.expirationDateString(
                        from: recognizedText.string)
                    let sanitizedExpiration = STPCardValidator.sanitizedNumericString(
                        for: expirationString ?? "")
                    handlePossibleExpirationDate(sanitizedExpiration)
                }
            }
        }
        // Second strategy: We look for consecutive groups of 4/4/4/4 or 4/6/5
        // Vision is sending us groups like ["1234 565", "1234 1"], so we'll normalize these into groups with spaces:
        let allGroups = allNumbers.joined(separator: " ").components(separatedBy: " ")
        if allGroups.count < 3 {
            return
        }
        for i in 0..<(allGroups.count - 3) {
            let string1 = allGroups[i]
            let string2 = allGroups[i + 1]
            let string3 = allGroups[i + 2]
            var string4 = ""
            if i + 3 < allGroups.count {
                string4 = allGroups[i + 3]
            }
            // Then we'll go through each group and build a potential match:
            let potentialCardString = "\(string1)\(string2)\(string3)\(string4)"
            let potentialAmexString = "\(string1)\(string2)\(string3)"

            // Then we'll add valid matches. It's okay if we add a number a second time after doing so above, as the success of that first pass means it's more likely to be a good match.
            if STPCardValidator.validationState(
                forNumber: potentialCardString, validatingCardBrand: true)
                == .valid
            {
                addDetectedNumber(potentialCardString)
            } else if STPCardValidator.validationState(
                forNumber: potentialAmexString, validatingCardBrand: true) == .valid
            {
                addDetectedNumber(potentialAmexString)
            }
        }
    }

    private func handlePossibleExpirationDate(_ sanitizedExpiration: String) {
        let month = (sanitizedExpiration as NSString).substring(to: 2)
        let year = (sanitizedExpiration as NSString).substring(from: 2)

        // Ignore expiration dates 10+ years in the future, as they're likely to be incorrect recognitions
        let calendar = Calendar(identifier: .gregorian)
        let presentYear = calendar.component(.year, from: Date())
        let maxYear = (presentYear % 100) + 10

        if STPCardValidator.validationState(forExpirationYear: year, inMonth: month)
            == .valid
            && Int(year) ?? 0 < maxYear
        {
            addDetectedExpiration(sanitizedExpiration)
        }
    }

    private func addDetectedNumber(_ number: String) {
        detectedNumbers.add(number)

        // Set a timeout: If we don't get enough scans in the next 0.6 seconds, we'll use the best option we have.
        if timeoutTime == nil {
            timeoutTime = Date().addingTimeInterval(Self.scanningTimeout)
            DispatchQueue.main.async { [weak self] in
                self?.cameraView?.playSnapshotAnimation()
                self?.feedbackGenerator?.notificationOccurred(.success)
            }
            // Just in case we don't get any frames, add another call to `finishIfReady` after timeoutTime to check
            videoDataOutputQueue?.asyncAfter(deadline: DispatchTime.now() + Self.scanningTimeout) { [weak self] in
                guard let self = self, self.scanIsActive() else { return }
                self.completeScanIfReady()
            }
        }

        if detectedNumbers.count(for: number) >= Self.minimumValidScans {
            completeScanIfReady()
        }
    }

    private func addDetectedExpiration(_ expiration: String) {
        detectedExpirations.add(expiration)
        if detectedExpirations.count(for: expiration) >= Self.minimumValidScans {
            completeScanIfReady()
        }
    }

    // Check if card scanning has completed and finish if so
    private func completeScanIfReady() {
        guard scanIsActive() else { return }

        let detectedNumbers = self.detectedNumbers
        let detectedExpirations = self.detectedExpirations

        let topNumber = (detectedNumbers.allObjects as NSArray).sortedArray(comparator: {
            obj1, obj2 in
            let c1 = detectedNumbers.count(for: obj1)
            let c2 = detectedNumbers.count(for: obj2)
            if c1 < c2 {
                return .orderedAscending
            } else if c1 > c2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }).last
        let topExpiration = (detectedExpirations.allObjects as NSArray).sortedArray(comparator: {
            obj1, obj2 in
            let c1 = detectedExpirations.count(for: obj1)
            let c2 = detectedExpirations.count(for: obj2)
            if c1 < c2 {
                return .orderedAscending
            } else if c1 > c2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }).last

        var didSeeEnoughScans = false
        if let topNumber = topNumber, let topExpiration = topExpiration {
            didSeeEnoughScans = detectedNumbers.count(for: topNumber) >= Self.minimumValidScans &&
                detectedExpirations.count(for: topExpiration) >= Self.minimumValidScans
        }
        if didTimeout || didSeeEnoughScans {
            let params = STPPaymentMethodCardParams()
            params.number = topNumber as? String
            if let topExpiration = topExpiration {
                params.expMonth = NSNumber(
                    value: Int((topExpiration as! NSString).substring(to: 2)) ?? 0)
                params.expYear = NSNumber(
                    value: Int((topExpiration as! NSString).substring(from: 2)) ?? 0)
            }
            finish(didSucceed: true) { [weak self] in
                guard let self else { return }
                self.delegate?.cardScanner(self, didCompleteWith: params)
            }
        }
    }

    // Finish the scanning session
    private func finish(didSucceed: Bool, completion: (() -> Void)? = nil) {
        scanningStateLock.lock()
        guard isScanning else {
            scanningStateLock.unlock()
            return
        }

        var duration: TimeInterval = 0.0
        if let startTime {
            duration = Date().timeIntervalSince(startTime)
        }
        // Mark the request finished immediately, even though the camera may take time to stop.
        // This also ensures repeated cancellation or recognition callbacks only enqueue one shutdown.
        isScanning = false

        // stopRunning blocks. Always enqueue it, including when finishing from a frame callback,
        // so neither PaymentSheet dismissal nor the current frame callback has to wait for it.
        captureSessionQueue.async {
            self.videoDataOutput?.setSampleBufferDelegate(nil, queue: nil)
            self.captureSession?.stopRunning()

            DispatchQueue.main.async {
                if didSucceed {
                    STPAnalyticsClient.sharedClient.logCardScanSucceeded(withDuration: duration)
                } else {
                    STPAnalyticsClient.sharedClient.logCardScanCancelled(withDuration: duration)
                }
                self.feedbackGenerator = nil
                self.cameraView?.captureSession = nil
                // Successful scans and errors must be delivered after capture shutdown and UI cleanup.
                completion?()
            }
        }
        scanningStateLock.unlock()
    }

    private func scanIsActive() -> Bool {
        scanningStateLock.lock()
        defer { scanningStateLock.unlock() }
        return isScanning
    }
}

@available(macCatalyst 14.0, *)
extension STPCardScanner: STPAnalyticsProtocol {
    static var stp_analyticsIdentifier = "STPCardScanner"
}

#endif

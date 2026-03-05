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
    // Called when an error occurs
    func cardScannerDidError(_ scanner: STPCardScanner)
}

@available(macCatalyst 14.0, *)
@objc(STPCardScanner)
class STPCardScanner: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

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
    private var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession?
    private var captureSessionQueue: DispatchQueue?
    private var textRequest: VNRecognizeTextRequest?
    private var isScanning = false

    private var stp_deviceOrientation: UIDeviceOrientation!
    private var videoOrientation: AVCaptureVideoOrientation!
    private var textOrientation: CGImagePropertyOrientation!
    private var regionOfInterest = CGRect.zero
    private var startTime: Date?

    // MARK: - Initialization
    init(delegate: STPCardScannerDelegate?) {
        super.init()
        self.delegate = delegate
        captureSessionQueue = DispatchQueue(label: "com.stripe.CardScanning.CaptureSessionQueue")
        deviceOrientation = UIDevice.current.orientation
    }

    deinit {
        if isScanning {
            captureDevice?.unlockForConfiguration()
            captureSession?.stopRunning()
        }
    }

    // MARK: - Public Methods
    func start() {
        guard !isScanning else { return }

        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPCardScanner.self)
        startTime = Date()

        isScanning = true
        feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()

        captureSessionQueue?.async { [weak self] in
            guard let self = self else { return }

            #if targetEnvironment(simulator)
            // Camera not supported on Simulator
            self.finishWithError()
            return
            #else
            DispatchQueue.main.async {
                self.cameraView?.captureSession = self.captureSession
                self.cameraView?.videoPreviewLayer.connection?.videoOrientation = self.videoOrientation
            }
            #endif
        }
    }

    func stop() {
        finish(didSucceed: false)
    }

    private func finishWithError() {
        finish(didSucceed: false)
        DispatchQueue.main.async {
            self.delegate?.cardScannerDidError(self)
        }
    }

    // MARK: - Video Processing
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if !isScanning {
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

    // Finish the scanning session
    private func finish(didSucceed: Bool) {
        guard isScanning else { return }

        var duration: TimeInterval = 0.0
        if let startTime {
            duration = Date().timeIntervalSince(startTime)
        }
        isScanning = false
        captureDevice?.unlockForConfiguration()
        captureSession?.stopRunning()

        DispatchQueue.main.async {
            if didSucceed {
                STPAnalyticsClient.sharedClient.logCardScanSucceeded(withDuration: duration)
            } else {
                STPAnalyticsClient.sharedClient.logCardScanCancelled(withDuration: duration)
            }
            self.feedbackGenerator = nil
            self.cameraView?.captureSession = nil
        }
    }
}

@available(macCatalyst 14.0, *)
extension STPCardScanner: STPAnalyticsProtocol {
    static var stp_analyticsIdentifier = "STPCardScanner"
}

#endif

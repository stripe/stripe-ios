//
//  MockSimulatorCameraSession.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

// Ignoring file formatt becase of compiler directive which would force the whole file to be
// indented, including import statements.
// swift-format-ignore-file

#if targetEnvironment(simulator)

import AVKit
import Foundation
@_spi(STP) import StripeCore

/// Mocks a CameraSession on the simulator.
@_spi(STP) public final class MockSimulatorCameraSession: CameraSessionProtocol {

    enum Error: Swift.Error {
        case sessionNotConfigured
        case noImages
    }

    static let mockSampleBufferTimeInterval: TimeInterval = 0.1

    private let images: [UIImage]
    private var nextImageToReturn: Int = 0
    private var currentImage: UIImage?
    private let sessionQueue = DispatchQueue(label: "com.stripe.mock-simulator-camera-session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private lazy var captureConnection = AVCaptureConnection(
        inputPorts: [],
        output: videoOutput
    )
    private var mockSampleBufferTimer: Timer?
    weak private var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    // MARK: - Public

    private var isConfigured: Bool = false
    private var cameraPosition: CameraSession.CameraPosition = .front

    public weak var previewView: CameraPreviewView? {
        didSet {
            setPreviewViewToCurrentImage()
        }
    }

    public init(
        images: [UIImage]
    ) {
        self.images = images
    }

    public func configureSession(
        configuration: CameraSession.Configuration,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    ) {
        sessionQueue.async { [weak self] in
            let wrappedCompletion = { setupResult in
                queue.async {
                    completion(setupResult)
                }
            }

            guard let self = self else { return }
            self.delegate = delegate

            guard !self.images.isEmpty else {
                self.isConfigured = false
                wrappedCompletion(.failed(error: Error.noImages))
                return
            }

            self.cameraPosition = configuration.initialCameraPosition
            self.isConfigured = true
            wrappedCompletion(.success)
        }
    }

    public func setVideoOrientation(orientation: AVCaptureVideoOrientation) {
        // no-op
    }

    public func toggleCamera(
        to position: CameraSession.CameraPosition,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let wrappedCompletion = { setupResult in
                queue.async {
                    completion(setupResult)
                }
            }

            guard self.isConfigured else {
                wrappedCompletion(.failed(error: Error.sessionNotConfigured))
                return
            }

            self.cameraPosition = position
            wrappedCompletion(.success)
        }
    }

    public func getCameraProperties() -> CameraSession.DeviceProperties? {
        return .init(
            exposureDuration: CMTime(value: 0, timescale: 1),
            cameraDeviceType: .builtInDualCamera,
            isVirtualDevice: nil,
            lensPosition: 0,
            exposureISO: 0,
            isAdjustingFocus: false
        )
    }

    public func toggleTorch() {
        // no-op
    }

    public func startSession(
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            defer {
                queue.async {
                    completion()
                }
            }

            if self.isConfigured && self.currentImage == nil {
                self.currentImage = self.images.stp_boundSafeObject(at: self.nextImageToReturn)
                self.setPreviewViewToCurrentImage()
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.mockSampleBufferTimer = Timer.scheduledTimer(
                    timeInterval: MockSimulatorCameraSession.mockSampleBufferTimeInterval,
                    target: self,
                    selector: #selector(self.mockSampleBufferDelegateCallback),
                    userInfo: nil,
                    repeats: true
                )
            }
        }
    }

    public func stopSession(
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            defer {
                queue.async {
                    completion()
                }
            }

            self.mockSampleBufferTimer?.invalidate()

            if self.currentImage != nil {
                self.nextImageToReturn += 1
            }
            self.currentImage = nil
        }
    }
}

extension MockSimulatorCameraSession {
    @objc fileprivate func mockSampleBufferDelegateCallback() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                var image = self.currentImage
            else {
                return
            }

            // Flip image horizontally if mocking front-facing camera
            if self.cameraPosition == .front,
                let cgImage = image.cgImage
            {
                image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .upMirrored)
            }

            guard let sampleBuffer = image.convertToSampleBuffer() else {
                return
            }

            self.delegate?.captureOutput?(
                self.videoOutput,
                didOutput: sampleBuffer,
                from: self.captureConnection
            )
        }
    }

    fileprivate func setPreviewViewToCurrentImage() {
        DispatchQueue.main.async { [weak self, weak currentImage] in
            guard let self = self else { return }
            self.previewView?.layer.contents = currentImage?.cgImage
            self.previewView?.layer.contentsGravity = .resizeAspectFill
        }
    }
}

#endif

//
//  VideoFeed.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/1/21.
//

import AVKit
import VideoToolbox

/// A helper class to manage a video feed from the camera
@_spi(STP) public final class VideoFeed {

    /**
     Completion block called when done setting up video capture session.

     - Parameter success: If the camera feed was setup successfully
     */
    public typealias SetupCompletionBlock = (_ success: Bool) -> Void

    private enum SessionSetupResult {
        case success
        case configurationFailed
    }

    public let session = AVCaptureSession()
    public var videoDeviceConnection: AVCaptureConnection?

    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "com.stripe.VideoFeed.sessionQueue")
    private let captureSessionQueue = DispatchQueue(label: "com.stripe.VideoFeed.cameraOutputQueue")
    private var setupResult: SessionSetupResult = .success
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDevice: AVCaptureDevice?
    private var torch: Torch?

    // MARK: - Init

    public init() {
        // This is needed to expose init publicly
    }

    // MARK: - Setup

    public func setup(
        captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        initialVideoOrientation: AVCaptureVideoOrientation,
        completeOnQueue queue: DispatchQueue = .main,
        completion: @escaping SetupCompletionBlock
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession(
                captureDelegate: captureDelegate,
                initialVideoOrientation: initialVideoOrientation,
                completeOnQueue: queue,
                completion: completion
            )
        }
    }


    private func configureSession(
        captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        initialVideoOrientation: AVCaptureVideoOrientation,
        completeOnQueue completionQueue: DispatchQueue,
        completion: @escaping SetupCompletionBlock
    ) {
        let wrappedCompletion: SetupCompletionBlock = { success in
            completionQueue.async {
                completion(success)
            }
        }

        if setupResult != .success {
            wrappedCompletion(false)
            return
        }

        session.beginConfiguration()

        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                /*
                 In some cases where users break their phones, the back wide angle camera is not available.
                 In this case, we should default to the front wide angle camera.
                 */
                defaultVideoDevice = frontCameraDevice
            }

            guard let myVideoDevice = defaultVideoDevice else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                wrappedCompletion(false)
                return
            }

            self.videoDevice = myVideoDevice
            self.torch = Torch(device: myVideoDevice)
            let videoDeviceInput = try AVCaptureDeviceInput(device: myVideoDevice)

            self.setupVideoDeviceDefaults()

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                wrappedCompletion(false)
                return
            }

            let videoDeviceOutput = AVCaptureVideoDataOutput()
            videoDeviceOutput.videoSettings = [
                (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]

            videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
            videoDeviceOutput.setSampleBufferDelegate(captureDelegate, queue: captureSessionQueue)
            guard session.canAddOutput(videoDeviceOutput) else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                wrappedCompletion(false)
                return
            }
            session.addOutput(videoDeviceOutput)

            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }

            self.videoDeviceConnection = videoDeviceOutput.connection(with: .video)
            if self.videoDeviceConnection?.isVideoOrientationSupported ?? false {
                self.videoDeviceConnection?.videoOrientation = initialVideoOrientation
            }
        } catch {
            setupResult = .configurationFailed
            session.commitConfiguration()
            wrappedCompletion(false)
            return
        }

        session.commitConfiguration()
        wrappedCompletion(true)
    }

    private func setupVideoDeviceDefaults() {
        guard let videoDevice = self.videoDevice else {
            return
        }

        guard let _ = try? videoDevice.lockForConfiguration() else {
            return
        }

        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            videoDevice.focusMode = .continuousAutoFocus
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = true
            }
        }

        if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
            videoDevice.exposureMode = .continuousAutoExposure
        }

        if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
        }

        if videoDevice.isLowLightBoostSupported {
            videoDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
        }
        videoDevice.unlockForConfiguration()
    }

    // MARK: - Torch Logic

    public func toggleTorch() {
        self.torch?.toggle()
    }

    public func isTorchOn() -> Bool {
        return self.torch?.state == Torch.State.on
    }

    public func hasTorchAndIsAvailable() -> Bool {
        let hasTorch = self.torch?.device?.hasTorch ?? false
        let isTorchAvailable = self.torch?.device?.isTorchAvailable ?? false
        return hasTorch && isTorchAvailable
    }

    public func setTorchLevel(level: Float) {
        self.torch?.level = level
    }

    // MARK: - Session Lifecycle

    public func pauseSession() {
        self.sessionQueue.suspend()
    }

    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case .configurationFailed:
                break
            }
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
}

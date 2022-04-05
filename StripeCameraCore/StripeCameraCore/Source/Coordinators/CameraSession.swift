//
//  CameraSession.swift
//  StripeCameraCore
//
//  Created by Jaime Park on 12/16/21.
//

import AVKit
@_spi(STP) import StripeCore

@_spi(STP) @frozen public enum CameraSessionError: Error {
    /// Can't find capture device to add
    case captureDeviceNotFound
    /// Session configuration has failed
    case configurationFailed
}

@_spi(STP) public protocol CameraSessionProtocol: AnyObject {

    var previewView: CameraPreviewView? { get set }

    func configureSession(
        configuration: CameraSession.Configuration,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    )

    func setVideoOrientation(
        orientation: AVCaptureVideoOrientation
    )

    func toggleCamera(
        to position: CameraSession.CameraPosition,
        completeOn queue: DispatchQueue,
        completion: @escaping (CameraSession.SetupResult) -> Void
    )

    func toggleTorch()

    func getCameraProperties() -> CameraSession.DeviceProperties?

    func startSession(
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    )

    func stopSession()
}

@_spi(STP) public final class CameraSession: CameraSessionProtocol {
    @frozen public enum SetupResult {
        /// Session has successfully updated
        case success
        /// Session did not update due to an error
        case failed(error: Error)
    }

    public enum CameraPosition {
        case front
        case back
    }

    public struct Configuration {
        /// The initial position of camera: front or back
        public let initialCameraPosition: CameraPosition
        /// The initial video orientation of the camera session
        public let initialOrientation: AVCaptureVideoOrientation
        /**
         The capture device’s focus mode.
         - Seealso: https://developer.apple.com/documentation/avfoundation/avcapturedevice/focusmode
         */
        public let focusMode: AVCaptureDevice.FocusMode?
        /**
         The point of interest for focusing.
         - Seealso:
         https://developer.apple.com/documentation/avfoundation/avcapturedevice/focuspointofinterest
         */
        public let focusPointOfInterest: CGPoint?
        /// A preset value of the quality of the capture session
        public let sessionPreset: AVCaptureSession.Preset
        /**
         Video settings for the video output
         - Seealso: https://developer.apple.com/documentation/avfoundation/avcapturephotosettings/video_settings
         */
        public let outputSettings: [String: Any]

        /**
         - Parameters:
           - initialCameraPosition: The initial position of camera: front or back
           - initialOrientation: The initial video orientation of the camera session
           - focusMode: The focus mode of the camera session
           - focusPointOfInterest: The point of interest for focusing
           - sessionPreset: A preset value of the quality of the capture session
           - outputSettings: Video settings for the video output
         */
        public init(
            initialCameraPosition: CameraPosition,
            initialOrientation: AVCaptureVideoOrientation,
            focusMode: AVCaptureDevice.FocusMode? = nil,
            focusPointOfInterest: CGPoint? = nil,
            sessionPreset: AVCaptureSession.Preset = .high,
            outputSettings: [String: Any] = [:]
        ) {
            self.initialCameraPosition = initialCameraPosition
            self.initialOrientation = initialOrientation
            self.focusMode = focusMode
            self.focusPointOfInterest = focusPointOfInterest
            self.sessionPreset = sessionPreset
            self.outputSettings = outputSettings
        }
    }

    public struct DeviceProperties: Equatable {
        public let exposureDuration: CMTime
        public let cameraDeviceType: AVCaptureDevice.DeviceType
        public let isVirtualDevice: Bool?
        public let lensPosition: Float
        public let exposureISO: Float
        public let isAdjustingFocus: Bool
    }

    // MARK: - Properties

    public weak var previewView: CameraPreviewView? {
        didSet {
            guard oldValue !== previewView else {
                return
            }

            // Remove captureSession from previous view and add it to new one
            oldValue?.setCaptureSession(nil, on: sessionQueue)
            previewView?.setCaptureSession(session, on: sessionQueue)
        }
    }

    private let session: AVCaptureSession = AVCaptureSession()
    private var captureConnection: AVCaptureConnection?
    private let sessionQueue = DispatchQueue(label: "com.stripe.camera-session")
    private var torchDevice: Torch?
    private var setupResult: SetupResult?

    private var videoDeviceInput: AVCaptureDeviceInput? {
        didSet {
            if let videoDeviceInput = videoDeviceInput {
                // Set torch with new capture input
                self.torchDevice = Torch(device: videoDeviceInput.device)
            }
        }
    }

    // MARK: - Public

    public init() {
        // This is needed to expose init publicly
    }

    /**
     Configures the camera session with the initial inputs and outputs.

     If the camera session has been configured already, then the configuration
     is ignored and the previous setup result is passed to the completion block.

     - Parameters:
       - configuration: Configuration settings for the session
       - delegate:
       - queue: DispatchQueue the completion block should be called on
       - completion: A block executed when the session is done being configured
     */
    public func configureSession(
        configuration: Configuration,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        completeOn queue: DispatchQueue,
        completion: @escaping (SetupResult) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Check if already configured
            if let setupResult = self.setupResult {
                completion(setupResult)
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = configuration.sessionPreset
            self.session.commitConfiguration()

            self.configureSessionInput(with: configuration.initialCameraPosition).chained { [weak self] _ -> Future<Void> in
                guard let self = self else {
                    // If self has been deallocated before configuring output, return failure
                    let promise = Promise<Void>()
                    promise.reject(with: CameraSessionError.configurationFailed)
                    return promise
                }

                return self.configureSessionOutput(
                    with: configuration.outputSettings,
                    orientation: configuration.initialOrientation,
                    focusMode: configuration.focusMode,
                    focusPointOfInterest: configuration.focusPointOfInterest,
                    delegate: delegate
                )
            }.observe(on: queue) { [weak self] result in
                self?.setupResult = result.setupResult
                completion(result.setupResult)
            }
        }
    }

    public func setFocus(
        focusMode: AVCaptureDevice.FocusMode,
        focusPointOfInterest: CGPoint? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        sessionQueue.async { [weak self] in
            do {
                try self?.setFocusOnCurrentQueue(
                    focusMode: focusMode,
                    focusPointOfInterest: focusPointOfInterest
                )
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    /**
     Attempts to change the video orientation of both the session output
     and the preview view layer.

     - Parameters:
       - orientation: The desired video orientation
     */
    public func setVideoOrientation(
        orientation: AVCaptureVideoOrientation
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.captureConnection?.videoOrientation = orientation
            self.previewView?.videoPreviewLayer.connection?.videoOrientation = orientation
        }
    }

    /**
     Returns the properties from the camera device.

     - Note: This method can only be called on the camera session thread,
       meaning it's only meant to be called from the output delegate's
       `captureOutput` method.
     */
    public func getCameraProperties() -> CameraSession.DeviceProperties? {
        dispatchPrecondition(condition: .onQueue(sessionQueue))

        guard let device = videoDeviceInput?.device else {
            return nil
        }

        var isVirtualDevice: Bool?
        if #available(iOS 13, *) {
            isVirtualDevice = device.isVirtualDevice
        }

        return .init(
            exposureDuration: device.exposureDuration,
            cameraDeviceType: device.deviceType,
            isVirtualDevice: isVirtualDevice,
            lensPosition: device.lensPosition,
            exposureISO: device.iso,
            isAdjustingFocus: device.isAdjustingFocus
        )
    }

    /**
     Attempts to switch camera input to a new camera position.
     - Parameters:
       - position: The camera position to toggle to
       - queue: DispatchQueue the completion block should be called on
       - completion: A block executed when the camera has finished toggling
     */
    public func toggleCamera(
        to position: CameraPosition,
        completeOn queue: DispatchQueue,
        completion: @escaping (SetupResult) -> Void
    ) {
        configureSessionInput(with: position).observe(on: queue) { result in
            completion(result.setupResult)
        }
    }

    /// Attempts to toggle the torch on or off.
    public func toggleTorch() {
        self.torchDevice?.toggle()
    }

    /**
     Starts the camera session, calling a completion block when the session has
     been started.

     - Parameters:
       - queue: The queue to call the completion block on
       - completion: A block executed when the session has been started
     */
    public func startSession(
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        sessionQueue.async { [weak self] in
            defer {
                queue.async {
                    completion()
                }
            }

            guard let self = self,
                  case .success = self.setupResult else {
                      return
            }

            self.session.startRunning()
        }
    }

    /// Stop the camera session
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  case .success = self.setupResult else {
                      return
            }

            self.session.stopRunning()
        }
    }
}

// MARK: - Private

private extension CameraSession {
    func configureSessionInput(
        with position: CameraPosition
    ) -> Future<Void> {
        let promise = Promise<Void>()

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            defer {
                self.session.commitConfiguration()
            }

            do {
                // Remove inputs
                self.session.inputs.forEach {
                    self.session.removeInput($0)
                }

                let newVideoDeviceInput = try self.captureDeviceInput(position: position)

                // Add video input
                guard self.session.canAddInput(newVideoDeviceInput)
                else {
                    promise.reject(with: CameraSessionError.configurationFailed)
                    return
                }
                self.session.addInput(newVideoDeviceInput)

                // Keep reference to video device input
                self.videoDeviceInput = newVideoDeviceInput

                promise.resolve(with: ())
            } catch {
                promise.reject(with: error)
            }
        }

        return promise
    }

    func configureSessionOutput(
        with videoSettings: [String: Any],
        orientation: AVCaptureVideoOrientation,
        focusMode: AVCaptureDevice.FocusMode?,
        focusPointOfInterest: CGPoint?,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate
    ) -> Future<Void> {
        let promise = Promise<Void>()

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            defer {
                self.session.commitConfiguration()
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = videoSettings
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(delegate, queue: self.sessionQueue)

            guard self.session.canAddOutput(videoOutput) else {
                promise.reject(with: CameraSessionError.configurationFailed)
                return
            }

            // Add output to session
            self.session.addOutput(videoOutput)

            // Update output connection reference
            self.captureConnection = videoOutput.connection(with: .video)

            // Update new output and previewLayer orientation
            self.setVideoOrientation(orientation: orientation)

            // Set focus if needed
            guard let focusMode = focusMode else {
                promise.resolve(with: ())
                return
            }

            promise.fulfill { [weak self] in
                try self?.setFocusOnCurrentQueue(
                    focusMode: focusMode,
                    focusPointOfInterest: focusPointOfInterest
                )
            }
        }

        return promise
    }

    func captureDeviceInput(position: CameraPosition) throws -> AVCaptureDeviceInput {
        let captureDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: position.captureDeviceTypes,
            mediaType: .video,
            position: position.captureDevicePosition
        )

        guard let captureDevice = captureDevices.devices.first else {
            throw CameraSessionError.captureDeviceNotFound
        }

        return try AVCaptureDeviceInput(device: captureDevice)
    }

    func setFocusOnCurrentQueue(
        focusMode: AVCaptureDevice.FocusMode,
        focusPointOfInterest: CGPoint?
    ) throws {
        dispatchPrecondition(condition: .onQueue(sessionQueue))

        guard let device = videoDeviceInput?.device else {
            return
        }

        try device.lockForConfiguration()
        device.focusMode = focusMode

        if let focusPointOfInterest = focusPointOfInterest,
           device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = focusPointOfInterest
        }

        device.unlockForConfiguration()
    }
}

// MARK: - CameraPosition

extension CameraSession.CameraPosition {
    /**
     Returns a list of camera devices, ordered by preferred device, for this
     camera position.
     */
    var captureDeviceTypes: [AVCaptureDevice.DeviceType] {
        switch self {
        case .front:
            return [.builtInTrueDepthCamera, .builtInWideAngleCamera]

        case .back:
            if #available(iOS 13.0, *) {
                return [.builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
            } else {
                return [.builtInDualCamera, .builtInWideAngleCamera]
            }
        }
    }

    var captureDevicePosition: AVCaptureDevice.Position {
        switch self {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

// MARK: - Result

/// Helper to convert a Result into SetupResult
private extension Result where Success == Void, Failure == Error {
    var setupResult: CameraSession.SetupResult {
        switch self {
        case .success:
            return .success
        case .failure(let error):
            return .failed(error: error)
        }
    }
}

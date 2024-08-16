import AVKit
import VideoToolbox

protocol AfterPermissions {
    func permissionDidComplete(granted: Bool, showedPrompt: Bool)
}

class VideoFeed {
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult = .success
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDevice: AVCaptureDevice?
    var videoDeviceConnection: AVCaptureConnection?
    var torch: Torch?

    func pauseSession() {
        self.sessionQueue.suspend()
    }

    func requestCameraAccess(permissionDelegate: AfterPermissions?) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.sessionQueue.resume()
            DispatchQueue.main.async {
                permissionDelegate?.permissionDidComplete(granted: true, showedPrompt: false)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(
                for: .video,
                completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                    DispatchQueue.main.async {
                        permissionDelegate?.permissionDidComplete(
                            granted: granted,
                            showedPrompt: true
                        )
                    }
                }
            )

        default:
            // The user has previously denied access.
            self.setupResult = .notAuthorized
            DispatchQueue.main.async {
                permissionDelegate?.permissionDidComplete(granted: false, showedPrompt: false)
            }
        }
    }

    func setup(
        captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        initialVideoOrientation: AVCaptureVideoOrientation,
        completion: @escaping ((_ success: Bool) -> Void)
    ) {
        sessionQueue.async {
            self.configureSession(
                captureDelegate: captureDelegate,
                initialVideoOrientation: initialVideoOrientation,
                completion: completion
            )
        }
    }

    func configureSession(
        captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        initialVideoOrientation: AVCaptureVideoOrientation,
        completion: @escaping ((_ success: Bool) -> Void)
    ) {
        if setupResult != .success {
            DispatchQueue.main.async { completion(false) }
            return
        }

        session.beginConfiguration()

        do {
            var defaultVideoDevice: AVCaptureDevice? = getAvailableCaptureDevice()

            guard let myVideoDevice = defaultVideoDevice else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
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
                DispatchQueue.main.async { completion(false) }
                return
            }

            let videoDeviceOutput = AVCaptureVideoDataOutput()
            videoDeviceOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(
                    kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                ),
            ]

            videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
            let captureSessionQueue = DispatchQueue(label: "camera output queue")
            videoDeviceOutput.setSampleBufferDelegate(captureDelegate, queue: captureSessionQueue)
            guard session.canAddOutput(videoDeviceOutput) else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
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
            DispatchQueue.main.async { completion(false) }
            return
        }

        session.commitConfiguration()
        DispatchQueue.main.async { completion(true) }
    }

    func setupVideoDeviceDefaults() {
        guard let videoDevice = self.videoDevice else {
            return
        }

        guard (try? videoDevice.lockForConfiguration()) != nil else {
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
    func toggleTorch() {
        self.torch?.toggle()
    }

    func isTorchOn() -> Bool {
        return self.torch?.state == Torch.State.on
    }

    func hasTorchAndIsAvailable() -> Bool {
        let hasTorch = self.torch?.device?.hasTorch ?? false
        let isTorchAvailable = self.torch?.device?.isTorchAvailable ?? false
        return hasTorch && isTorchAvailable
    }

    func setTorchLevel(level: Float) {
        self.torch?.level = level
    }
    
    // MARK: - VC Lifecycle Logic
    func willAppear() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case _:
                break
            }
        }
    }

    func willDisappear() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
}

// MARK: - Capture Device

private extension VideoFeed {
    
    /// Retrieves the most suitable video capture device based on a prioritized list of back camera types.
    /// - Returns: The most appropriate `AVCaptureDevice` if found; otherwise, returns a fallback front camera device.
    ///
    func getAvailableCaptureDevice() -> AVCaptureDevice? {
        // Try to get the preferred back camera first
        if let preferredBackCamera = getPreferredBackCamera() {
            return preferredBackCamera
        }
        
        // Fallback to any available back camera if preferred types are not found
        if let fallbackBackCamera = getFallbackBackCamera() {
            return fallbackBackCamera
        }
        
        /// If no back-facing camera is available, defaults to the front wide-angle camera.
        return getFallbackFrontCamera()
    }

    /// Attempts to find the most suitable back camera from a prioritized list of preferred types.
    /// - Returns: The first available `AVCaptureDevice` from the list of preferred types, or `nil` if none are found.
    ///
    func getPreferredBackCamera() -> AVCaptureDevice? {
        let preferredBackCameraTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera
        ]
        
        return findCaptureDevice(for: .video, position: .back, preferredTypes: preferredBackCameraTypes)
    }

    /// Attempts to find any available back camera from a broader list of types.
    /// - Returns: The first available `AVCaptureDevice` from a comprehensive list of device types, or `nil` if none are found.
    ///
    func getFallbackBackCamera() -> AVCaptureDevice? {
        let fallbackBackCameraTypes: [AVCaptureDevice.DeviceType] = [
            .builtInDualCamera,
            .builtInTripleCamera,
            .builtInTelephotoCamera,
            .builtInDualWideCamera,
            .builtInTrueDepthCamera,
            .builtInWideAngleCamera,
            .builtInUltraWideCamera
        ]
        
        return findFirstAvailableCaptureDevice(for: .video, position: .back, types: fallbackBackCameraTypes)
    }

    /// Provides a fallback option by returning the front wide-angle camera.
    /// - Returns: The front wide-angle `AVCaptureDevice`, or `nil` if unavailable.
    ///
    func getFallbackFrontCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }

    /// Searches for the first available `AVCaptureDevice` that matches any of the provided types.
    /// - Parameters:
    ///   - mediaType: The media type, typically `.video`.
    ///   - position: The desired position of the camera, such as `.back` or `.front`.
    ///   - preferredTypes: A prioritized list of `AVCaptureDevice.DeviceType` to search for.
    /// - Returns: The first available `AVCaptureDevice` matching one of the preferred types, or `nil` if none are found.
    ///
    func findCaptureDevice(for mediaType: AVMediaType, position: AVCaptureDevice.Position, preferredTypes: [AVCaptureDevice.DeviceType]) -> AVCaptureDevice? {
        return preferredTypes.compactMap {
            AVCaptureDevice.default($0, for: mediaType, position: position)
        }.first
    }

    /// Searches for the first available `AVCaptureDevice` using a discovery session.
    /// - Parameters:
    ///   - mediaType: The media type, typically `.video`.
    ///   - position: The desired position of the camera, such as `.back` or `.front`.
    ///   - types: A list of `AVCaptureDevice.DeviceType` to include in the discovery session.
    /// - Returns: The first available `AVCaptureDevice` discovered, or `nil` if none are found.
    ///
    func findFirstAvailableCaptureDevice(for mediaType: AVMediaType, position: AVCaptureDevice.Position, types: [AVCaptureDevice.DeviceType]) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: mediaType, position: position)
        return discoverySession.devices.first
    }
}

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
            DispatchQueue.main.async { permissionDelegate?.permissionDidComplete(granted: true, showedPrompt: false) }
            break
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
                DispatchQueue.main.async { permissionDelegate?.permissionDidComplete(granted: granted, showedPrompt: true) }
            })
            
        default:
            // The user has previously denied access.
            self.setupResult = .notAuthorized
            DispatchQueue.main.async { permissionDelegate?.permissionDidComplete(granted: false, showedPrompt: false) }
        }
    }
    
    func setup(captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, initialVideoOrientation: AVCaptureVideoOrientation, completion: @escaping ((_ success: Bool) -> Void)) {
        sessionQueue.async { self.configureSession(captureDelegate: captureDelegate, initialVideoOrientation: initialVideoOrientation, completion: completion) }
    }
    
    
    func configureSession(captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, initialVideoOrientation: AVCaptureVideoOrientation, completion: @escaping ((_ success: Bool) -> Void)) {
        if setupResult != .success {
            DispatchQueue.main.async { completion(false) }
            return
        }
        
        session.beginConfiguration()
        
         do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if #available(iOS 10.2, *) {
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
            } else {
                // Fallback on earlier versions
            }
            
            guard let myVideoDevice = defaultVideoDevice else {
                print("Could not add video device input to the session")
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
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            let videoDeviceOutput = AVCaptureVideoDataOutput()
            videoDeviceOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            
            videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
            let captureSessionQueue = DispatchQueue(label: "camera output queue")
            videoDeviceOutput.setSampleBufferDelegate(captureDelegate, queue: captureSessionQueue)
            guard session.canAddOutput(videoDeviceOutput) else {
                print("Could not add video device output to the session")
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
            print("Could not create video device input: \(error)")
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
        
        guard let _ = try? videoDevice.lockForConfiguration() else {
            print("can't lock video device")
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
    
    //MARK: -Torch Logic
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
    
    //MARK: -VC Lifecycle Logic
    func willAppear() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case _:
                print("could not start session")
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

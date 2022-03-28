import UIKit
import AVKit
import Vision

protocol TestingImageDataSource: AnyObject {
    func nextSquareAndFullImage() -> (CGImage, CGImage)?
}

class ScanBaseViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AfterPermissions, OcrMainLoopDelegate {
    
    weak var testingImageDataSource: TestingImageDataSource?
    var includeCardImage = false
    var showDebugImageView = false
    
    var scanEventsDelegate: ScanEvents?
    
    static var isAppearing = false
    static var isPadAndFormsheet: Bool = false
    static  let machineLearningQueue = DispatchQueue(label: "CardScanMlQueue")
    private let machineLearningSemaphore = DispatchSemaphore(value: 1)
    
    private weak var debugImageView: UIImageView?
    private weak var previewView: PreviewView?
    private weak var regionOfInterestLabel: UIView?
    private weak var blurView: BlurView?
    private weak var cornerView: CornerView?
    private var regionOfInterestLabelFrame: CGRect?
    private var previewViewFrame: CGRect?
    
    var videoFeed = VideoFeed()
    var initialVideoOrientation: AVCaptureVideoOrientation {
        if ScanBaseViewController.isPadAndFormsheet {
            return AVCaptureVideoOrientation(interfaceOrientation: UIWindow.interfaceOrientation) ?? .portrait
        } else {
            return .portrait
        }
    }
    
    var scannedCardImage: UIImage?
    private var isNavigationBarHidden: Bool?
    var hideNavigationBar: Bool?
    var regionOfInterestCornerRadius = CGFloat(10.0)
    private var calledOnScannedCard = false

    /// The start of the scanning session
    let scanAnalyticsManager: ScanAnalyticsManager
    /// Flag to keep track of first time pan is observed
    private var firstPanObserved: Bool = false
    /// Flag to keep track of first time frame is processed
    private var firstImageProcessed: Bool = false
    
    var mainLoop: MachineLearningLoop? = OcrMainLoop()
    private func ocrMainLoop() -> OcrMainLoop? {
        return mainLoop.flatMap { $0 as? OcrMainLoop }
    }
    // this is a hack to avoid changing our  interface
    var predictedName: String?
    
    // Child classes should override these functions
    func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) { }
    func showCardNumber(_ number: String, expiry: String?) { }
    func showWrongCard(number: String?, expiry: String?, name: String?) { }
    func showNoCard() { }
    func onCameraPermissionDenied(showedPrompt: Bool) { }
    func useCurrentFrameNumber(errorCorrectedNumber: String?, currentFrameNumber: String) -> Bool { return true }

    // MARK: Inits
    init(configuration: CardImageVerificationSheet.Configuration) {
        self.scanAnalyticsManager = ScanAnalyticsManager(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    //MARK: -Torch Logic
    func toggleTorch() {
        self.ocrMainLoop()?.scanStats.torchOn = !(self.ocrMainLoop()?.scanStats.torchOn ?? false)
        self.videoFeed.toggleTorch()
    }
    
    func isTorchOn() -> Bool{
        return self.videoFeed.isTorchOn()
    }
    
    func hasTorchAndIsAvailable() -> Bool {
        return self.videoFeed.hasTorchAndIsAvailable()
    }
        
    func setTorchLevel(level: Float) {
        if 0.0...1.0 ~= level {
            self.videoFeed.setTorchLevel(level: level)
        }
    }
    
    static  func configure(apiKey: String? = nil) {
        // TODO: remove this and just use stripe's main configuration path
    }
    
    static func supportedOrientationMaskOrDefault() -> UIInterfaceOrientationMask {
        guard ScanBaseViewController.isAppearing else {
            // If the ScanBaseViewController isn't appearing then fall back
            // to getting the orientation mask from the infoDictionary, just like
            // the system would do if the user didn't override the
            // supportedInterfaceOrientationsFor method
            let supportedOrientations = (Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String]) ?? ["UIInterfaceOrientationPortrait"]
            
            let maskArray = supportedOrientations.map { option -> UIInterfaceOrientationMask in
                switch (option) {
                case "UIInterfaceOrientationPortrait":
                    return UIInterfaceOrientationMask.portrait
                case "UIInterfaceOrientationPortraitUpsideDown":
                    return UIInterfaceOrientationMask.portraitUpsideDown
                case "UIInterfaceOrientationLandscapeLeft":
                    return UIInterfaceOrientationMask.landscapeLeft
                case "UIInterfaceOrientationLandscapeRight":
                    return UIInterfaceOrientationMask.landscapeRight
                default:
                    return UIInterfaceOrientationMask.portrait
                }
            }
            
            let mask: UIInterfaceOrientationMask = maskArray.reduce(UIInterfaceOrientationMask.portrait) { result, element in
                return UIInterfaceOrientationMask(rawValue: result.rawValue | element.rawValue)
            }
            
            return mask
        }
        return ScanBaseViewController.isPadAndFormsheet ? .allButUpsideDown : .portrait
    }
    
    static  func isCompatible() -> Bool {
        return self.isCompatible(configuration: ScanConfiguration())
    }
    
    static  func isCompatible(configuration: ScanConfiguration) -> Bool {
        // check to see if the user has already denined camera permission
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus != .authorized && authorizationStatus != .notDetermined && configuration.setPreviouslyDeniedDevicesAsIncompatible {
            return false
        }
        
        // make sure that we don't run on iPhone 6 / 6plus or older
        if configuration.runOnOldDevices {
            return true
        }
        
        return true
    }
    
    func cancelScan() {
        guard let ocrMainLoop = ocrMainLoop()  else {
            return
        }
        ocrMainLoop.userCancelled()
    }
     
    func setupMask() {
        guard let roi = self.regionOfInterestLabel else { return }
        guard let blurView = self.blurView else { return }
        blurView.maskToRoi(roi: roi)
    }
    
    func setUpCorners() {
        guard let roi = self.regionOfInterestLabel else { return }
        guard let corners = self.cornerView else { return }
        corners.setFrameSize(roi: roi)
        corners.drawCorners()
    }

    func permissionDidComplete(granted: Bool, showedPrompt: Bool) {
        self.ocrMainLoop()?.scanStats.permissionGranted = granted
        if !granted {
            self.onCameraPermissionDenied(showedPrompt: showedPrompt)
        }
        scanAnalyticsManager.logCameraPermissionsTask(success: granted)
    }
    
    // you must call setupOnViewDidLoad before calling this function and you have to call
    // this function to get the camera going
    func startCameraPreview() {
        self.videoFeed.requestCameraAccess(permissionDelegate: self)
    }
    
    internal func invokeFakeLoop() {
        guard let dataSource = testingImageDataSource else {
            return
        }
        
        guard let (_, fullTestingImage) = dataSource.nextSquareAndFullImage() else {
            return
        }
        
        guard let roiFrame = self.regionOfInterestLabelFrame,
              let previewViewFrame = self.previewViewFrame,
              let roiRectInPixels = ScannedCardImageData.convertToPreviewLayerRect(
                captureDeviceImage: fullTestingImage,
                viewfinderRect: roiFrame,
                previewViewRect: previewViewFrame
              )
        else {
            return
        }

        mainLoop?.push(imageData: ScannedCardImageData(previewLayerImage: fullTestingImage, previewLayerViewfinderRect: roiRectInPixels))
    }
    
    internal func startFakeCameraLoop() {
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.invokeFakeLoop()
        }
        RunLoop.main.add(timer, forMode: .default)
    }
    
    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
    
    func setupOnViewDidLoad(
        regionOfInterestLabel: UIView,
        blurView: BlurView,
        previewView: PreviewView,
        cornerView: CornerView?,
        debugImageView: UIImageView?,
        torchLevel: Float?
    ) {
        
        self.regionOfInterestLabel = regionOfInterestLabel
        self.blurView = blurView
        self.previewView = previewView
        self.debugImageView = debugImageView
        self.debugImageView?.contentMode = .scaleAspectFit
        self.cornerView = cornerView
        ScanBaseViewController.isPadAndFormsheet = UIDevice.current.userInterfaceIdiom == .pad && self.modalPresentationStyle == .formSheet
        
        setNeedsStatusBarAppearanceUpdate()
        regionOfInterestLabel.layer.masksToBounds = true
        regionOfInterestLabel.layer.cornerRadius = self.regionOfInterestCornerRadius
        regionOfInterestLabel.layer.borderColor = UIColor.white.cgColor
        regionOfInterestLabel.layer.borderWidth = 2.0
        
        if !ScanBaseViewController.isPadAndFormsheet {
            UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        }
        
        if testingImageDataSource != nil {
            self.ocrMainLoop()?.imageQueueSize = 20
        }
        
        self.ocrMainLoop()?.mainLoopDelegate = self
        self.previewView?.videoPreviewLayer.session = self.videoFeed.session

        self.videoFeed.pauseSession()
        //Apple example app sets up in viewDidLoad: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
        self.videoFeed.setup(captureDelegate: self, initialVideoOrientation: self.initialVideoOrientation, completion: { success in
            if self.previewView?.videoPreviewLayer.connection?.isVideoOrientationSupported ?? false {
                self.previewView?.videoPreviewLayer.connection?.videoOrientation = self.initialVideoOrientation
            }
            if let level = torchLevel {
                self.setTorchLevel(level: level)
            }
            
            if !success && self.testingImageDataSource != nil && self.isSimulator() {
                self.startFakeCameraLoop()
            }
        })
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return ScanBaseViewController.isPadAndFormsheet ? .allButUpsideDown : .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return ScanBaseViewController.isPadAndFormsheet ? UIWindow.interfaceOrientation : .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoFeedConnection = self.videoFeed.videoDeviceConnection, videoFeedConnection.isVideoOrientationSupported {
            videoFeedConnection.videoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) ?? .portrait
        }
        if let previewViewConnection = self.previewView?.videoPreviewLayer.connection, previewViewConnection.isVideoOrientationSupported {
            previewViewConnection.videoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) ?? .portrait
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScanBaseViewController.isAppearing = true
        /// Set beginning of scan session
        scanAnalyticsManager.setScanSessionStartTime(time: Date())
        /// Check and log torch availability
        scanAnalyticsManager.logTorchSupportTask(supported: videoFeed.hasTorchAndIsAvailable())
        self.ocrMainLoop()?.reset()
        self.calledOnScannedCard = false
        self.videoFeed.willAppear()
        self.isNavigationBarHidden = self.navigationController?.isNavigationBarHidden ?? true
        let hideNavigationBar = self.hideNavigationBar ?? true
        self.navigationController?.setNavigationBarHidden(hideNavigationBar, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.view.layoutIfNeeded()
        guard let roiFrame = self.regionOfInterestLabel?.frame, let previewViewFrame = self.previewView?.frame else { return }
        // store .frame to avoid accessing UI APIs in the machineLearningQueue
        self.regionOfInterestLabelFrame = roiFrame
        self.previewViewFrame = previewViewFrame
        self.setUpCorners()
        self.setupMask()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.ocrMainLoop()?.scanStats.orientation = UIWindow.interfaceOrientationToString
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoFeed.willDisappear()
        self.navigationController?.setNavigationBarHidden(self.isNavigationBarHidden ?? false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ScanBaseViewController.isAppearing = false
    }
    
    func getScanStats() -> ScanStats {
        return self.ocrMainLoop()?.scanStats ?? ScanStats()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.machineLearningSemaphore.wait(timeout: .now()) == .success {
            ScanBaseViewController.machineLearningQueue.async {
                self.captureOutputWork(sampleBuffer: sampleBuffer)
                self.machineLearningSemaphore.signal()
            }
        }
    }

    func captureOutputWork(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        

        guard let fullCameraImage = pixelBuffer.cgImage() else {
            return
        }
        
        // confirm videoGravity settings in previewView. Calculations based on .resizeAspectFill
        DispatchQueue.main.async {
            assert(self.previewView?.videoPreviewLayer.videoGravity == .resizeAspectFill)
        }
        
        guard let roiFrame = self.regionOfInterestLabelFrame,
              let previewViewFrame = self.previewViewFrame,
              let scannedImageData = ScannedCardImageData(
                captureDeviceImage: fullCameraImage,
                viewfinderRect: roiFrame,
                previewViewRect: previewViewFrame
              )
        else {
            return
        }
        
        // we allow apps that integrate to supply their own sequence of images
        // for use in testing
        if let dataSource = self.testingImageDataSource {
            guard let (_, fullTestingImage) = dataSource.nextSquareAndFullImage() else {
                return
            }
            mainLoop?.push(imageData: ScannedCardImageData(previewLayerImage: fullTestingImage, previewLayerViewfinderRect: roiFrame))
        } else {
            mainLoop?.push(imageData: scannedImageData)
        }
    }
    
    func updateDebugImageView(image: UIImage) {
        self.debugImageView?.image = image
        if self.debugImageView?.isHidden ?? false {
            self.debugImageView?.isHidden = false
        }
    }

    // MARK: -OcrMainLoopComplete logic
    func complete(creditCardOcrResult: CreditCardOcrResult) {
        ocrMainLoop()?.mainLoopDelegate = nil
        /// Stop the previewing when we are done
        self.previewView?.videoPreviewLayer.session?.stopRunning()
        /// Log total frames processed
        scanAnalyticsManager.logMainLoopImageProcessedRepeatingTask(.init(executions: self.getScanStats().scans))
        scanAnalyticsManager.logScanActivityTaskFromStartTime(event: .cardScanned)

        ScanBaseViewController.machineLearningQueue.async {
            self.scanEventsDelegate?.onScanComplete(scanStats: self.getScanStats())
        }

        // hack to work around having to change our  interface
        predictedName = creditCardOcrResult.name
        self.onScannedCard(number: creditCardOcrResult.number, expiryYear: creditCardOcrResult.expiryYear, expiryMonth: creditCardOcrResult.expiryMonth, scannedImage: scannedCardImage)
    }

    func prediction(prediction: CreditCardOcrPrediction, imageData: ScannedCardImageData, state: MainLoopState) {
        if !firstImageProcessed {
            scanAnalyticsManager.logScanActivityTaskFromStartTime(event: .firstImageProcessed)
            firstImageProcessed = true
        }

        if self.showDebugImageView {
            let numberBoxes = prediction.numberBoxes?.map { (UIColor.blue, $0) } ?? []
            let expiryBoxes = prediction.expiryBoxes?.map { (UIColor.red, $0) } ?? []
            let nameBoxes = prediction.nameBoxes?.map { (UIColor.green, $0) } ?? []

            if self.debugImageView?.isHidden ?? false {
                self.debugImageView?.isHidden = false
            }

            self.debugImageView?.image = prediction.image.drawBoundingBoxesOnImage(boxes: numberBoxes + expiryBoxes + nameBoxes)
        }

        if prediction.number != nil && self.includeCardImage {
            self.scannedCardImage = UIImage(cgImage: prediction.image)
        }

        let isFlashForcedOn: Bool
        switch (state) {
        case .ocrForceFlash: isFlashForcedOn = true
        default: isFlashForcedOn = false
        }

        if let number = prediction.number {
            if !firstPanObserved {
                scanAnalyticsManager.logScanActivityTaskFromStartTime(event: .ocrPanObserved)
                firstPanObserved = true
            }

            let expiry = prediction.expiryObject()

            ScanBaseViewController.machineLearningQueue.async {
                self.scanEventsDelegate?.onNumberRecognized(number: number, expiry: expiry, imageData: imageData, centeredCardState: prediction.centeredCardState, flashForcedOn: isFlashForcedOn)
            }
        } else {
            ScanBaseViewController.machineLearningQueue.async {
                self.scanEventsDelegate?.onFrameDetected(imageData: imageData, centeredCardState: prediction.centeredCardState, flashForcedOn: isFlashForcedOn)
            }
        }
    }

    func showCardDetails(number: String?, expiry: String?, name: String?) {
        guard let number = number else { return }
        showCardNumber(number, expiry: expiry)
    }

    func showCardDetailsWithFlash(number: String?, expiry: String?, name: String?) {
        if !isTorchOn() { toggleTorch() }
        guard let number = number else { return }
        showCardNumber(number, expiry: expiry)
    }

    func shouldUsePrediction(errorCorrectedNumber: String?, prediction: CreditCardOcrPrediction) -> Bool {
        guard let predictedNumber = prediction.number else { return true }
        return useCurrentFrameNumber(errorCorrectedNumber: errorCorrectedNumber, currentFrameNumber: predictedNumber)
    }
}

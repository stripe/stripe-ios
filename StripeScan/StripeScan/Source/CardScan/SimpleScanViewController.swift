import UIKit

/*
 This class is all programmatic UI with a small bit of logic to handle
 the events that ScanBaseViewController expects subclasses to implement.
 Our goal is to have a fully featured Card Scan implementation with a
 minimal UI that people can customize fully. You can use this directly or
 you can subclass and customize it. If you'd like to use an off-the-shelf
 design as well, we suggest using the `ScanViewController`, which uses
 mature and well tested UI design patterns.
 
 The default UI looks something like this, with most of the constraints
 shown:
 
 ------------------------------------
 |   |                          |   |
 |-Cancel                     Torch-|
 |                                  |
 |                                  |
 |                                  |
 |                                  |
 |                                  |
 |------------Scan Card-------------|
 |                |                 |
 |  ------------------------------  |
 | |                              | |
 | |                              | |
 | |                              | |
 | |--4242    4242   4242   4242--| |
 | ||           05/23             | |
 | ||-Sam King                    | |
 | |     |                        | |
 |  ------------------------------  |
 | |              |               | |
 | |              |               | |
 | |   Enable camera permissions  | |
 | |              |               | |
 | |              |               | |
 | |---To scan your card you...---| |
 |                                  |
 |                                  |
 |                                  |
 ------------------------------------
 
 For the UI we separate out the key components into three parts:
 - Five `*String` variables that we use to set the copy
 - For each component or group of components we have:
   - `setup*Ui` functions for setting the visual look and feel
   - `setup*Constraints for setting up autolayout
 - We have top level `setupUiComponents` and `setupConstraints` functions that do
   a small bit of setup and call the appropriate setup functions for each
   components
 
 And to customize the UI you can either override any of these functions or you
 can access components directly to adjust. Also, you're welcome to copy and paste
 this code and customize it to fit your needs -- we're fine with whatever makes
 the most sense for your app.
 */

@available(iOS 11.2, *)
@objc public protocol SimpleScanDelegate {
    @objc func userDidCancelSimple(_ scanViewController: SimpleScanViewController)
    @objc func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard)
}

@available(iOS 11.2, *)
@objc open class SimpleScanViewController: ScanBaseViewController {

    // used by ScanBase
    public var previewView: PreviewView = PreviewView()
    public var blurView: BlurView = BlurView()
    public var roiView: UIView = UIView()
    public var cornerView: CornerView?

    // our UI components
    public var descriptionText = UILabel()
    
    @objc public var closeButton: UIButton = {
        var button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.setTitle(SimpleScanViewController.closeButtonString, for: .normal)
        return button
    }()
    
    @objc public var torchButton: UIButton = {
        var button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.setTitle(SimpleScanViewController.torchButtonString, for: .normal)
        return button
    }()
    
    private var debugView: UIImageView?
    public var enableCameraPermissionsButton = UIButton(type: .system)
    public var enableCameraPermissionsText = UILabel()
    
    // Dynamic card details
    public var numberText = UILabel()
    public var expiryText = UILabel()
    public var nameText = UILabel()
    public var expiryLayoutView = UIView()
    
    // String
    @objc public static var descriptionString = "Scan Card".localize()
    @objc public static var enableCameraPermissionString = "Enable camera access".localize()
    @objc public static var enableCameraPermissionsDescriptionString = "To scan your card you'll need to update your phone settings".localize()
    @objc public static var closeButtonString = "Close".localize()
    @objc public static var torchButtonString = "Torch".localize()
    
    @objc public weak var delegate: SimpleScanDelegate?
    @objc public var scanPerformancePriority: ScanPerformance = .fast
    @objc public var maxErrorCorrectionDuration: Double = 4.0
    
    @objc public static func createViewController() -> SimpleScanViewController {
        let vc = SimpleScanViewController()

        if UIDevice.current.userInterfaceIdiom == .pad {
            // For the iPad you can use the full screen style but you have to select "requires full screen" in
            // the Info.plist to lock it in portrait mode. For iPads, we recommend using a formSheet, which
            // handles all orientations correctly.
            vc.modalPresentationStyle = .formSheet
        } else {
            vc.modalPresentationStyle = .fullScreen
        }
 
        return vc
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUiComponents()
        setupConstraints()
        
        setupOnViewDidLoad(regionOfInterestLabel: roiView, blurView: blurView, previewView: previewView, cornerView: cornerView, debugImageView: debugView, torchLevel: 1.0)
        
        if #available(iOS 13.0, *) {
            setUpMainLoop(errorCorrectionDuration: maxErrorCorrectionDuration)
        }
        
        startCameraPreview()
    }
    
    /* TODO:
     Removing targets manually since we are allowing custom buttons which retains button reference ->
     ARC doesn't automatically decrement its reference count ->
     Targets gets added on every setUpUi call.

     Figure out a better way of allow custom buttons programmatically instead of whole UI buttons.
    */
    open override func viewDidDisappear(_ animated: Bool) {
        closeButton.removeTarget(self, action: #selector(cancelButtonPress), for: .touchUpInside)
        torchButton.removeTarget(self, action: #selector(torchButtonPress), for: .touchUpInside)
    }
    
    @available(iOS 13.0, *)
    func setUpMainLoop(errorCorrectionDuration: Double) {
        if scanPerformancePriority == .accurate {
            let mainLoop = self.mainLoop as? OcrMainLoop
            mainLoop?.errorCorrection = ErrorCorrection(stateMachine: OcrAccurateMainLoopStateMachine(maxErrorCorrection: maxErrorCorrectionDuration))
        }
    }
    
    // MARK: -Visual and UI event setup for UI components
    open func setupUiComponents() {
        view.backgroundColor = .white
        regionOfInterestCornerRadius = 15.0

        let children: [UIView] = [previewView, blurView, roiView, descriptionText, closeButton, torchButton, numberText, expiryText, nameText, expiryLayoutView, enableCameraPermissionsButton, enableCameraPermissionsText]
        for child in children {
            self.view.addSubview(child)
        }
        
        setupPreviewViewUi()
        setupBlurViewUi()
        setupRoiViewUi()
        setupCloseButtonUi()
        setupTorchButtonUi()
        setupDescriptionTextUi()
        setupCardDetailsUi()
        setupDenyUi()
        
        if showDebugImageView {
            setupDebugViewUi()
        }
    }
    
    open func setupPreviewViewUi() {
        // no ui setup
    }
    
    open func setupBlurViewUi() {
        blurView.backgroundColor = #colorLiteral(red: 0.2411109507, green: 0.271378696, blue: 0.3280351758, alpha: 0.7020547945)
    }
    
    open func setupRoiViewUi() {
        roiView.layer.borderColor = UIColor.white.cgColor
    }
    
    open func setupCloseButtonUi() {
        closeButton.addTarget(self, action: #selector(cancelButtonPress), for: .touchUpInside)
    }
    
    open func setupTorchButtonUi() {
        torchButton.addTarget(self, action: #selector(torchButtonPress), for: .touchUpInside)
    }
    
    open func setupDescriptionTextUi() {
        descriptionText.text = SimpleScanViewController.descriptionString
        descriptionText.textColor = .white
        descriptionText.textAlignment = .center
        descriptionText.font = descriptionText.font.withSize(30)
    }
    
    open func setupCardDetailsUi() {
        numberText.isHidden = true
        numberText.textColor = .white
        numberText.textAlignment = .center
        numberText.font = numberText.font.withSize(48)
        numberText.adjustsFontSizeToFitWidth = true
        numberText.minimumScaleFactor = 0.2
        
        expiryText.isHidden = true
        expiryText.textColor = .white
        expiryText.textAlignment = .center
        expiryText.font = expiryText.font.withSize(20)
        
        nameText.isHidden = true
        nameText.textColor = .white
        nameText.font = expiryText.font.withSize(20)
    }
    
    open func setupDenyUi() {
        let text = SimpleScanViewController.enableCameraPermissionString
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
        let font = enableCameraPermissionsButton.titleLabel?.font.withSize(20) ?? UIFont.systemFont(ofSize: 20.0)
        attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))
        enableCameraPermissionsButton.setAttributedTitle(attributedString, for: .normal)
        enableCameraPermissionsButton.isHidden = true
        
        enableCameraPermissionsButton.addTarget(self, action: #selector(enableCameraPermissionsPress), for: .touchUpInside)
        
        enableCameraPermissionsText.text = SimpleScanViewController.enableCameraPermissionsDescriptionString
        enableCameraPermissionsText.textColor = .white
        enableCameraPermissionsText.textAlignment = .center
        enableCameraPermissionsText.font = enableCameraPermissionsText.font.withSize(17)
        enableCameraPermissionsText.numberOfLines = 3
        enableCameraPermissionsText.isHidden = true
    }
    
    open func setupDebugViewUi() {
        debugView = UIImageView()
        guard let debugView = debugView else { return }
        self.view.addSubview(debugView)
    }
    
    // MARK: -Autolayout constraints
    open func setupConstraints() {
        let children: [UIView] = [previewView, blurView, roiView, descriptionText, closeButton, torchButton, numberText, expiryText, nameText, expiryLayoutView, enableCameraPermissionsButton, enableCameraPermissionsText]
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupPreviewViewConstraints()
        setupBlurViewConstraints()
        setupRoiViewConstraints()
        setupCloseButtonConstraints()
        setupTorchButtonConstraints()
        setupDescriptionTextConstraints()
        setupCardDetailsConstraints()
        setupDenyConstraints()
        
        if showDebugImageView {
            setupDebugViewConstraints()
        }
    }
    
    open func setupPreviewViewConstraints() {
        // make it full screen
        previewView.setAnchorsEqual(to: self.view)
    }
    
    open func setupBlurViewConstraints() {
        blurView.setAnchorsEqual(to: self.previewView)
    }
    
    open func setupRoiViewConstraints() {
        roiView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        roiView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        roiView.heightAnchor.constraint(equalTo: roiView.widthAnchor, multiplier: 1.0 / 1.586).isActive = true
        roiView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    open func setupCloseButtonConstraints() {
        let margins = view.layoutMarginsGuide
        closeButton.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16.0).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
    }
    
    open func setupTorchButtonConstraints() {
        let margins = view.layoutMarginsGuide
        torchButton.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16.0).isActive = true
        torchButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
    }
    
    open func setupDescriptionTextConstraints() {
        descriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        descriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32).isActive = true
        descriptionText.bottomAnchor.constraint(equalTo: roiView.topAnchor, constant: -16).isActive = true
    }
    
    open func setupCardDetailsConstraints() {
        numberText.leadingAnchor.constraint(equalTo: roiView.leadingAnchor, constant: 32).isActive = true
        numberText.trailingAnchor.constraint(equalTo: roiView.trailingAnchor, constant: -32).isActive = true
        numberText.centerYAnchor.constraint(equalTo: roiView.centerYAnchor).isActive = true
        
        nameText.leadingAnchor.constraint(equalTo: numberText.leadingAnchor).isActive = true
        nameText.bottomAnchor.constraint(equalTo: roiView.bottomAnchor, constant: -16).isActive = true
        
        expiryLayoutView.topAnchor.constraint(equalTo: numberText.bottomAnchor).isActive = true
        expiryLayoutView.bottomAnchor.constraint(equalTo: nameText.topAnchor).isActive = true
        expiryLayoutView.leadingAnchor.constraint(equalTo: numberText.leadingAnchor).isActive = true
        expiryLayoutView.trailingAnchor.constraint(equalTo: numberText.trailingAnchor).isActive = true
        
        expiryText.leadingAnchor.constraint(equalTo: expiryLayoutView.leadingAnchor).isActive = true
        expiryText.trailingAnchor.constraint(equalTo: expiryLayoutView.trailingAnchor).isActive = true
        expiryText.centerYAnchor.constraint(equalTo: expiryLayoutView.centerYAnchor).isActive = true
    }
    
    open func setupDenyConstraints() {
        enableCameraPermissionsButton.topAnchor.constraint(equalTo: roiView.bottomAnchor, constant: 32).isActive = true
        enableCameraPermissionsButton.centerXAnchor.constraint(equalTo: roiView.centerXAnchor).isActive = true
        
        enableCameraPermissionsText.topAnchor.constraint(equalTo: enableCameraPermissionsButton.bottomAnchor, constant: 32).isActive = true
        enableCameraPermissionsText.leadingAnchor.constraint(equalTo: roiView.leadingAnchor).isActive = true
        enableCameraPermissionsText.trailingAnchor.constraint(equalTo: roiView.trailingAnchor).isActive = true
    }
    
    open func setupDebugViewConstraints() {
        guard let debugView = debugView else { return }
        debugView.translatesAutoresizingMaskIntoConstraints = false
        
        debugView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        debugView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        debugView.widthAnchor.constraint(equalToConstant: 240).isActive = true
        debugView.heightAnchor.constraint(equalTo: debugView.widthAnchor, multiplier: 1.0).isActive = true
    }
    
    // MARK: -Override some ScanBase functions
    override open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        card.image = scannedImage
        
        delegate?.userDidScanCardSimple(self, creditCard: card)
    }
    
    open func showScannedCardDetails(prediction: CreditCardOcrPrediction) {
        guard let number = prediction.number else {
            return
        }
                   
       numberText.text = CreditCardUtils.format(number: number)
       if numberText.isHidden {
           numberText.fadeIn()
       }
       
       if let expiry = prediction.expiryForDisplay {
           expiryText.text = expiry
           if expiryText.isHidden {
               expiryText.fadeIn()
           }
       }
       
       if let name = prediction.name {
           nameText.text = name
           if nameText.isHidden {
               nameText.fadeIn()
           }
       }
    }
    
    override open func prediction(prediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage, state: MainLoopState) {
        super.prediction(prediction: prediction, squareCardImage: squareCardImage, fullCardImage: fullCardImage, state: state)
        
        showScannedCardDetails(prediction: prediction)
    }
    
    override open func onCameraPermissionDenied(showedPrompt: Bool) {
        descriptionText.isHidden = true
        torchButton.isHidden = true
        
        enableCameraPermissionsButton.isHidden = false
        enableCameraPermissionsText.isHidden = false
    }
    
    // MARK: -UI event handlers
    @objc open func cancelButtonPress() {
        delegate?.userDidCancelSimple(self)
        self.cancelScan()
    }
    
    @objc open func torchButtonPress() {
        toggleTorch()
    }
    
    /// Warning: if the user navigates to settings and updates the setting, it'll suspend your app.
    @objc open func enableCameraPermissionsPress() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) else {
            print("can't open settings")
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
}

public extension UIView {
    func setAnchorsEqual(to otherView: UIView) {
        self.topAnchor.constraint(equalTo: otherView.topAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: otherView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: otherView.trailingAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: otherView.bottomAnchor).isActive = true
    }
}

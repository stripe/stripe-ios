/**
Our high-level goal with this class is to implement the logic needed for our card verify check while
adding minimal UI effects, and for any UI effects that we do add make them easily customized
via overriding functions.

This class builds off of the `SimpleScanViewController` for the UI, see that class or
our [docs ](https://docs.getbouncer.com/card-scan/ios-integration-guide/ios-customization-guide)
for more information on how to customize the look and feel of this view controller.
*/
import UIKit

@available(iOS 11.2, *)
@objc public protocol VerifyCardResult: AnyObject {
    func userCanceledVerifyCard(viewController: VerifyCardViewController)
    func fraudModelResultsVerifyCard(viewController: VerifyCardViewController, creditCard: CreditCard, extraData: [String: Any])
}

@available(iOS 11.2, *)
open class VerifyCardViewController: SimpleScanViewController {
    
    // our UI components
    public var cardDescriptionText = UILabel()
    @objc public static var closeButton: UIButton?
    @objc public static var torchButton: UIButton?
    
    // configuration
    public var lastFour: String?
    public var bin: String?
    public var cardNetwork: CardNetwork?
    
    // String
    @objc public static var wrongCardString = "Card doesn't match".localize()
    
    // for debugging
    public var debugRetainCompletionLoopImages = false
    
    // for extra data
    static let extraDataIsCardValidKey = "isCardValid"
    static let extraDataValidationFailureReason = "validationFailureReason"
    
    @objc public weak var verifyCardDelegate: VerifyCardResult?
    
    private var lastWrongCard: Date?
    
    public var userId: String?
    
    public init(userId: String?, lastFour: String, bin: String?, cardNetwork: CardNetwork?) {
        self.userId = userId
        self.lastFour = lastFour
        self.bin = bin
        self.cardNetwork = cardNetwork
        
        super.init(nibName: nil, bundle: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // For the iPad you can use the full screen style but you have to select "requires full screen" in
            // the Info.plist to lock it in portrait mode. For iPads, we recommend using a formSheet, which
            // handles all orientations correctly.
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .fullScreen
        }
    }

    @objc public convenience init(userId: String?, lastFour: String, bin: String?) {
        self.init(userId: userId, lastFour: lastFour, bin: bin, cardNetwork: nil)
    }
    
    required public init?(coder: NSCoder) { fatalError("not supported") }
    
    open override func viewDidLoad() {
        // setup our ML so that we use the UX model + OCR in the main loop
        let fraudData = CardVerifyFraudData()
        if debugRetainCompletionLoopImages {
            fraudData.debugRetainImages = true
        }
        
        scanEventsDelegate = fraudData
        
        super.viewDidLoad()
        setUpUxMainLoop()
    }
    
    func setUpUxMainLoop() {
        var uxAndOcrMainLoop = UxAndOcrMainLoop(stateMachine: CardVerifyStateMachine(requiredLastFour: lastFour, requiredBin: bin))
        
        if #available(iOS 13.0, *), scanPerformancePriority == .accurate {
            uxAndOcrMainLoop = UxAndOcrMainLoop(stateMachine: CardVerifyAccurateStateMachine(requiredLastFour: lastFour, requiredBin: bin, maxNameExpiryDurationSeconds: maxErrorCorrectionDuration))
        }
        
        uxAndOcrMainLoop.mainLoopDelegate = self
        mainLoop = uxAndOcrMainLoop
    }
    // MARK: -UI effects and customizations for the VerifyCard flow
    
    override open func setupUiComponents() {
        if let closeButton = VerifyCardViewController.closeButton {
            self.closeButton = closeButton
        }
        
        if let torchButton = VerifyCardViewController.torchButton {
            self.torchButton = torchButton
        }
        
        super.setupUiComponents()
        
        let children: [UIView] = [cardDescriptionText]
        for child in children {
            self.view.addSubview(child)
        }
        
        setupCardDescriptionTextUI()
    }
    
    open func setupCardDescriptionTextUI() {
        let network = bin.map { CreditCardUtils.determineCardNetwork(cardNumber: $0) }
        var text = "\(network.map { $0.toString() } ?? cardNetwork?.toString() ?? "")"
        
        if let lastFour = self.lastFour {
            text.append(contentsOf: " •••• \(lastFour)")
        } else if let bin = self.bin {
            text.append(contentsOf: " \(bin) ••••")
        }

        cardDescriptionText.textColor = .white
        cardDescriptionText.textAlignment = .center
        cardDescriptionText.numberOfLines = 2
        
        if !text.isEmpty {
            cardDescriptionText.text = text
            cardDescriptionText.isHidden = false
        } else {
            cardDescriptionText.isHidden = true
        }
    }
    
    // MARK: -Autolayout constraints
    override open func setupConstraints() {
        let children: [UIView] = [cardDescriptionText]
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        
        super.setupConstraints()
        
        setupCardDescriptionTextConstraints()
    }
    
    open func setupCardDescriptionTextConstraints() {
        cardDescriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        cardDescriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32).isActive = true
        cardDescriptionText.bottomAnchor.constraint(equalTo: roiView.topAnchor, constant: -16).isActive = true
    }
    
    override open func setupDescriptionTextConstraints() {
        descriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive = true
        descriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32).isActive = true
        descriptionText.bottomAnchor.constraint(equalTo: cardDescriptionText.topAnchor, constant: -16).isActive = true
    }
        
    // MARK: -Override some ScanBase functions
    override open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        card.image = scannedImage
        
        showFullScreenActivityIndicator()
        
        runFraudModels(cardNumber: number, expiryYear: expiryYear,
                       expiryMonth: expiryMonth) { (verificationResult) in
            
            self.verifyCardDelegate?.fraudModelResultsVerifyCard(viewController: self, creditCard: card, extraData: verificationResult.extraData())
        }
    }
    
    override open func showScannedCardDetails(prediction: CreditCardOcrPrediction) { }
    
    override public func showCardNumber(_ number: String, expiry: String?) {
        DispatchQueue.main.async {
            self.numberText.text = CreditCardUtils.format(number: number)
            if self.numberText.isHidden {
                self.numberText.fadeIn()
            }
            
            if let expiry = expiry {
                self.expiryText.text = expiry
                if self.expiryText.isHidden {
                    self.expiryText.fadeIn()
                }
            }
            
            if let predictedName = self.predictedName {
                self.nameText.text = predictedName
                if self.nameText.isHidden {
                    self.nameText.fadeIn()
                }
            }
            
            if !self.descriptionText.isHidden {
                self.descriptionText.fadeOut()
            }
        }
    }
    
    override public func showWrongCard(number: String?, expiry: String?, name: String?) {
        DispatchQueue.main.async {
            self.descriptionText.text = VerifyCardViewController.wrongCardString
            
            if !self.numberText.isHidden {
                self.numberText.fadeOut()
            }
            
            if !self.expiryText.isHidden {
                self.expiryText.fadeOut()
            }
            
            if !self.nameText.isHidden {
                self.nameText.fadeOut()
            }
            
            self.roiView.layer.borderColor = UIColor.red.cgColor
            self.lastWrongCard = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                guard let lastWrongCard = self.lastWrongCard else { return }
                if -lastWrongCard.timeIntervalSinceNow >= 0.5 {
                    self.showNoCard()
                }
            }
        }
    }
    
    override public func showNoCard() {
        DispatchQueue.main.async {
            self.roiView.layer.borderColor = UIColor.white.cgColor
            
            self.descriptionText.text = SimpleScanViewController.descriptionString
            
            if !self.numberText.isHidden {
                self.numberText.fadeOut()
            }
            
            if !self.expiryText.isHidden {
                self.expiryText.fadeOut()
            }
            
            if !self.nameText.isHidden {
                self.nameText.fadeOut()
            }
        }
    }
    
    // MARK: -UI event handlers
    @objc open override func cancelButtonPress() {
        verifyCardDelegate?.userCanceledVerifyCard(viewController: self)
    }
}

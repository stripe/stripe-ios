import UIKit

@available(iOS 11.2, *)
protocol VerifyCardExplanationResult: AnyObject {
    func userDidPressScanCardExplaination(_ viewController: VerifyCardExplanationViewController)
    func userDidPressPayAnotherWayExplanation(_ viewController: VerifyCardExplanationViewController)
    func userDidPressCloseExplanation(_ viewController: VerifyCardExplanationViewController)
}

@available(iOS 11.2, *)
class VerifyCardExplanationViewController: UIViewController {

    let card = UIView()
    let pan = UILabel()
    let networkImage = UIImageView()
    let expiryOrName = UILabel()
    
    let cardCorners = UIView()
    let cardCornersLeft = UIView()
    let cardCornersTop = UIView()
    let cardCornersRight = UIView()
    let cardCornersBottom = UIView()
    
    let closeButton = UIButton(type: .system)
    let confirmationTextLabel = UILabel()
    let confirmationSubtextLabel = UILabel()
    
    let scanCardButton = UIButton(type: .system)
    let tryAnotherCardButton = UIButton(type: .system)
    
    let lightGray = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    let darkGray = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    
    var lastFourForDisplay: String?
    var cardNetworkForDisplay: CardNetwork?
    var expiryOrNameForDisplay: String?
    weak var delegate: VerifyCardExplanationResult?
    
    var confirmationText = "We need you to confirm this card".localize()
    var confirmationSubtext = "Get your card ready so you can scan it with your phone. This helps us keep your account secure.".localize()
    
    var closeButtonText = "Close".localize()
    var scanCardButtonText = "Scan my card".localize()
    var tryAnotherCardButtonText = "Try to pay another way".localize()
    
    var showCloseButton = true
    
    init() {
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

    required  init?(coder: NSCoder) { fatalError("not supported") }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        showCloseButton = navigationController == nil
        
        let children: [UIView] = [cardCorners, cardCornersLeft, cardCornersRight,
                                  cardCornersTop, cardCornersBottom, card, pan,
                                  networkImage, expiryOrName, closeButton, confirmationTextLabel,
                                  confirmationSubtextLabel, scanCardButton,
                                  tryAnotherCardButton]
        for child in children {
            self.view.addSubview(child)
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupUi()
        setupConstraints()
        installEventHandlers()
    }
    
    func installEventHandlers() {
        closeButton.addTarget(self, action: #selector(closeButtonPress), for: .touchUpInside)
        scanCardButton.addTarget(self, action: #selector(scanCardButtonPress), for: .touchUpInside)
        tryAnotherCardButton.addTarget(self, action: #selector(tryAnotherCardButtonPress), for: .touchUpInside)
    }
    
    func setupUi() {
        setupCardCornersUi()
        setupCardUi()
        setupConfirmationUi()
        setupBottomButtonsUi()
    }
    
    func setupBottomButtonsUi() {
        scanCardButton.setTitle(scanCardButtonText, for: .normal)
        scanCardButton.backgroundColor = .black
        scanCardButton.setTitleColor(.white, for: .normal)
        scanCardButton.layer.cornerRadius = 8.0
        
        tryAnotherCardButton.setTitle(tryAnotherCardButtonText, for: .normal)
        tryAnotherCardButton.backgroundColor = .white
        tryAnotherCardButton.layer.borderWidth = 1.0
        tryAnotherCardButton.layer.borderColor = UIColor.black.cgColor
        tryAnotherCardButton.setTitleColor(.darkText, for: .normal)
        tryAnotherCardButton.layer.cornerRadius = 8.0
    }
    
    func setupConfirmationUi() {
        closeButton.setTitle(closeButtonText, for: .normal)
        
        confirmationTextLabel.text = confirmationText
        confirmationTextLabel.font =  UIFont.boldSystemFont(ofSize: 32.0)
        confirmationTextLabel.adjustsFontSizeToFitWidth = true
        confirmationTextLabel.minimumScaleFactor = 0.5
        confirmationTextLabel.lineBreakMode = .byTruncatingTail
        confirmationTextLabel.textColor = .black
        
        confirmationSubtextLabel.text = confirmationSubtext
        confirmationSubtextLabel.font = confirmationSubtextLabel.font.withSize(20.0)
        confirmationSubtextLabel.adjustsFontSizeToFitWidth = true
        confirmationSubtextLabel.minimumScaleFactor = 0.5
        confirmationSubtextLabel.lineBreakMode = .byTruncatingTail
        confirmationSubtextLabel.textColor = .black
    }
    
    func setupCardUi() {
        card.layer.borderWidth = 2.0
        card.layer.borderColor = darkGray.cgColor
        card.layer.cornerRadius = 8
        
        pan.text = lastFourForDisplay?.redactedPanFromLastFour()
        // TODO(kingst): get the network images from Stripe
        //networkImage.image = cardNetworkForDisplay?.image()
        expiryOrName.text = expiryOrNameForDisplay
        
        pan.font = pan.font.withSize(50.0)
        pan.adjustsFontSizeToFitWidth = true
        pan.minimumScaleFactor = 0.2
        pan.textColor = .black
        
        expiryOrName.font = expiryOrName.font.withSize(20.0)
        expiryOrName.adjustsFontSizeToFitWidth = true
        expiryOrName.minimumScaleFactor = 0.5
        expiryOrName.textColor = .black
    }
    
    func setupCardCornersUi() {
        cardCorners.layer.borderWidth = 2.0
        cardCorners.layer.borderColor = lightGray.cgColor
        cardCorners.layer.cornerRadius = 9
        
        for corners in [cardCornersTop, cardCornersBottom, cardCornersLeft, cardCornersRight] {
            
            corners.layer.borderWidth = 2.0
            corners.layer.borderColor = self.view.backgroundColor?.cgColor
        }
    }
    
    func setupConstraints() {
        setupCardConstraints()
        setupCardCornerConstraints()
        setupConfirmationConstraints()
        setupBottomButtonsConstraints()
    }
    
    func setupBottomButtonsConstraints() {
        let margins = view.safeAreaLayoutGuide
        
        tryAnotherCardButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 16.0).isActive = true
        tryAnotherCardButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -16.0).isActive = true
        tryAnotherCardButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -16.0).isActive = true
        tryAnotherCardButton.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        
        scanCardButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 16.0).isActive = true
        scanCardButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -16.0).isActive = true
        scanCardButton.bottomAnchor.constraint(equalTo: tryAnotherCardButton.topAnchor, constant: -16.0).isActive = true
        scanCardButton.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
    }
    
    func setupConfirmationConstraints() {
        let margins = view.safeAreaLayoutGuide
        let topAnchor = showCloseButton ? closeButton.bottomAnchor : margins.topAnchor
        
        if showCloseButton {
            closeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 16.0).isActive = true
            closeButton.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16.0).isActive = true
        } else {
            closeButton.isHidden = true
        }
        
        confirmationTextLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 16.0).isActive = true
        confirmationTextLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -16.0).isActive = true
        confirmationTextLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16.0).isActive = true
        confirmationTextLabel.numberOfLines = 2
        confirmationTextLabel.heightAnchor.constraint(equalTo: confirmationSubtextLabel.heightAnchor).isActive = true
        
        confirmationSubtextLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 16.0).isActive = true
        confirmationSubtextLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -16.0).isActive = true
        confirmationSubtextLabel.topAnchor.constraint(equalTo: confirmationTextLabel.bottomAnchor, constant: 16.0).isActive = true
        confirmationSubtextLabel.numberOfLines = 3
        confirmationSubtextLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardCorners.topAnchor, constant: -16.0).isActive = true
    }
    
    func setupCardConstraints() {
        let margins = view.safeAreaLayoutGuide
        
        card.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
        card.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 56.0).isActive = true
        card.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -56.0).isActive = true
        card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: 1.0/1.586).isActive = true
        
        if lastFourForDisplay != nil {
            pan.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24.0).isActive = true
            pan.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24.0).isActive = true
            pan.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
        }
        
        if cardNetworkForDisplay != nil {
            networkImage.topAnchor.constraint(equalTo: card.topAnchor, constant: 24.0).isActive = true
            networkImage.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24.0).isActive = true
            networkImage.widthAnchor.constraint(equalTo: pan.widthAnchor, multiplier: 0.25).isActive = true
            networkImage.heightAnchor.constraint(equalTo: networkImage.widthAnchor, multiplier: 80.0 / 128.0).isActive = true
        }
        
        if let expiryOrNameForDisplay = expiryOrNameForDisplay {
            expiryOrName.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24.0).isActive = true
            expiryOrName.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24.0).isActive = true
            
            // There is probably a better way to handle this but using the number
            // of characters is the best that I could come up with for now to
            // scale the expiryOrName font appropriately
            let ratio = CGFloat(expiryOrNameForDisplay.count) / 25.0
            let multiplier = ratio > 1.0 ? 1.0 : ratio
            expiryOrName.widthAnchor.constraint(equalTo: pan.widthAnchor, multiplier: multiplier).isActive = true
        }
    }
    
    func setupCardCornerConstraints() {
        cardCorners.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: -16.0).isActive = true
        cardCorners.topAnchor.constraint(equalTo: card.topAnchor, constant: -16.0).isActive = true
        cardCorners.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 16.0).isActive = true
        cardCorners.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 16.0).isActive = true
        
        cardCornersLeft.leadingAnchor.constraint(equalTo: cardCorners.leadingAnchor).isActive = true
        cardCornersLeft.topAnchor.constraint(equalTo: cardCorners.topAnchor, constant: 48.0).isActive = true
        cardCornersLeft.bottomAnchor.constraint(equalTo: cardCorners.bottomAnchor, constant: -48.0).isActive = true
        cardCornersLeft.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
        
        cardCornersRight.trailingAnchor.constraint(equalTo: cardCorners.trailingAnchor).isActive = true
        cardCornersRight.topAnchor.constraint(equalTo: cardCorners.topAnchor, constant: 48.0).isActive = true
        cardCornersRight.bottomAnchor.constraint(equalTo: cardCorners.bottomAnchor, constant: -48.0).isActive = true
        cardCornersRight.widthAnchor.constraint(equalToConstant: 2.0).isActive = true
        
        cardCornersTop.leadingAnchor.constraint(equalTo: cardCorners.leadingAnchor, constant: 48.0).isActive = true
        cardCornersTop.trailingAnchor.constraint(equalTo: cardCorners.trailingAnchor, constant: -48.0).isActive = true
        cardCornersTop.topAnchor.constraint(equalTo: cardCorners.topAnchor).isActive = true
        cardCornersTop.heightAnchor.constraint(equalToConstant: 2.0).isActive = true
        
        cardCornersBottom.leadingAnchor.constraint(equalTo: cardCorners.leadingAnchor, constant: 48.0).isActive = true
        cardCornersBottom.trailingAnchor.constraint(equalTo: cardCorners.trailingAnchor, constant: -48.0).isActive = true
        cardCornersBottom.bottomAnchor.constraint(equalTo: cardCorners.bottomAnchor).isActive = true
        cardCornersBottom.heightAnchor.constraint(equalToConstant: 2.0).isActive = true
    }
    
    // MARK: -Button press handlers
    @objc func closeButtonPress() {
        delegate?.userDidPressCloseExplanation(self)
    }
    
    @objc func scanCardButtonPress() {
        delegate?.userDidPressScanCardExplaination(self)
    }
    
    @objc func tryAnotherCardButtonPress() {
        delegate?.userDidPressPayAnotherWayExplanation(self)
    }
}

extension String {
    func redactedPanFromLastFour() -> String? {
        guard self.count == 4 else {
            return nil
        }
        
        return "••••   ••••   ••••   \(self)"
    }
}

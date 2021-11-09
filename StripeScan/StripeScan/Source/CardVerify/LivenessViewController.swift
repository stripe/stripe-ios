/**
 Our high-level goal with this class is to implement the logic needed for our liveness check while
 adding minimal UI effects, and for any UI effects that we do add make them easily customized
 via overriding functions.
 
 This class builds off of the `SimpleScanViewController` for the UI, see that class or
 our [docs ](https://docs.getbouncer.com/card-scan/ios-integration-guide/ios-customization-guide)
 for more information on how to customize the look and feel of this view controller.
 */
import UIKit

@available(iOS 11.2, *)
public protocol LivenessResults: AnyObject {
    func userDidScanCard(viewController: LivenessViewController, number: String?, name: String?, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage)
    func userCanceledLiveness(viewController: LivenessViewController)
}

@available(iOS 11.2, *)
open class LivenessViewController: SimpleScanViewController {

    // our UI components
    public var lastFour: String?
    public var isFrontOfCard = true
    
    public weak var livenessDelegate: LivenessResults?
    
    enum TypeOfSavedCard {
        case uxAndOcr
        case uxOnly
        case ocrOnly
    }
    private var savedCardImage: CGImage?
    private var savedCardType: TypeOfSavedCard?
    
    private var lastCenteredCard: Date?
    
    public static func createLivenessViewController() -> LivenessViewController {
       let vc = LivenessViewController()

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
        // setup our ML so that we use the UX model + OCR in the main loop
        let uxAndOcrMainLoop = UxAndOcrMainLoop(stateMachine: LivenessStateMachine())
        uxAndOcrMainLoop.mainLoopDelegate = self
        mainLoop = uxAndOcrMainLoop
        let fraudData = CardVerifyFraudData()
        fraudData.requireOcrBeforeCapturingUxOnlyFrames = false
        scanEventsDelegate = fraudData
        
        super.viewDidLoad()
    }
    
    // MARK: -UI effects and customizations for the liveness check
    
    open func setRoiBorderOnCardDetected() {
        roiView.layer.borderColor = UIColor.green.cgColor
        lastCenteredCard = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            guard let lastCenteredCard = self.lastCenteredCard else { return }
            if -lastCenteredCard.timeIntervalSinceNow >= 0.5 {
                self.roiView.layer.borderColor = UIColor.white.cgColor
            }
        }
    }
    
    override open func setupDescriptionTextUi() {
        super.setupDescriptionTextUi()
        
        let sideText = isFrontOfCard ? "front" : "back"
        let suffixText = lastFour.map { " ending in \($0)" } ?? ""
        descriptionText.text = "Scan the \(sideText) of your card\(suffixText)"

        descriptionText.textColor = .white
        descriptionText.font = descriptionText.font.withSize(30)
        descriptionText.numberOfLines = 2
    }
        
    // MARK: -Override some ScanBase functions
    override open func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        let number = number.count > 0 ? number : nil
        guard let cardImage = savedCardImage.map({ UIImage(cgImage: $0) }) else { return }
        livenessDelegate?.userDidScanCard(viewController: self, number: number, name: predictedName, expiryYear: expiryYear, expiryMonth: expiryMonth, scannedImage: cardImage)
    }
    
    override open func prediction(prediction: CreditCardOcrPrediction, squareCardImage: CGImage, fullCardImage: CGImage, state: MainLoopState) {
        super.prediction(prediction: prediction, squareCardImage: squareCardImage, fullCardImage: fullCardImage, state: state)
        let centeredCard = prediction.centeredCardState ?? .noCard
        let hasOcr = prediction.number != nil
        
        // logic to try to grab a good picture of the card. Anything that passes the
        // UxModel is likely to be of high quality, favor recent images
        switch (centeredCard, hasOcr, savedCardType ?? .ocrOnly) {
        case (.numberSide, true, _), (.nonNumberSide, true, _):
            savedCardImage = fullCardImage
            savedCardType = .uxAndOcr
        case (.numberSide, false, .ocrOnly), (.numberSide, false, .uxOnly),
             (.nonNumberSide, false, .ocrOnly), (.nonNumberSide, false, .uxOnly):
            savedCardImage = fullCardImage
            savedCardType = .uxOnly
        case (.noCard, true, .ocrOnly):
            savedCardImage = fullCardImage
            savedCardType = .ocrOnly
        default:
            break
        }
        
        // turn the roiView green if we detect a card (either side)
        if centeredCard != .noCard {
            setRoiBorderOnCardDetected()
        }
    }
    
    // MARK: -UI event handlers
    @objc open override func cancelButtonPress() {
        livenessDelegate?.userCanceledLiveness(viewController: self)
    }
}

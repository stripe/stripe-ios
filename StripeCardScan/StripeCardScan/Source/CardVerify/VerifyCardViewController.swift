@_spi(STP) import StripeCore
/// Our high-level goal with this class is to implement the logic needed for our card verify check while
/// adding minimal UI effects, and for any UI effects that we do add make them easily customized
/// via overriding functions.
///
/// This class builds off of the `SimpleScanViewController` for the UI, see that class or
/// our [docs ](https://docs.getbouncer.com/card-scan/ios-integration-guide/ios-customization-guide)
/// for more information on how to customize the look and feel of this view controller.
import UIKit

/// TODO(jaimepark): Consolidate both add flow and card-set flow into a single view controller.
/// This means replacing `VerifyCardViewControllerDelegate` and `VerifyCardAddViewControllerDelegate` with this one.
protocol VerifyViewControllerDelegate: AnyObject {
    /// TODO(jaimepark): Change view controller type after consolidation

    /// The scanning portion of the flow finished. Finish off verification flow by submitting verification frames data.
    func verifyViewControllerDidFinish(
        _ viewController: UIViewController,
        verificationFramesData: [VerificationFramesData],
        scannedCard: ScannedCard
    )

    /// User canceled the verification flow
    func verifyViewControllerDidCancel(
        _ viewController: UIViewController,
        with reason: CancellationReason
    )

    /// The verification flow failed
    func verifyViewControllerDidFail(
        _ viewController: UIViewController,
        with error: Error
    )
}

class VerifyCardViewController: SimpleScanViewController {
    typealias StrictModeFramesCount = CardImageVerificationSheet.StrictModeFrameCount

    // our UI components
    var cardDescriptionText = UILabel()
    static var closeButton: UIButton?
    static var torchButton: UIButton?

    // configuration
    private let expectedCardLast4: String
    private let expectedCardIssuer: String?
    private let acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs?
    private let configuration: CardImageVerificationSheet.Configuration

    // TODO(jaimepark): Put card brands  from `Stripe` into `StripeCore`
    var cardNetwork: CardNetwork?

    // String
    static var wrongCardString = String.Localized.card_doesnt_match

    // for debugging
    var debugRetainCompletionLoopImages = false

    weak var verifyDelegate: VerifyViewControllerDelegate?

    private var lastWrongCard: Date?
    private let mainLoopDurationTask: TrackableTask

    var userId: String?

    init(
        acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs?,
        configuration: CardImageVerificationSheet.Configuration,
        expectedCardLast4: String,
        expectedCardIssuer: String?
    ) {
        self.acceptedImageConfigs = acceptedImageConfigs
        self.configuration = configuration
        self.expectedCardLast4 = expectedCardLast4
        self.expectedCardIssuer = expectedCardIssuer
        self.mainLoopDurationTask = TrackableTask()

        super.init()
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    override func viewDidLoad() {
        // setup our ML so that we use the UX model + OCR in the main loop
        let fraudData = CardVerifyFraudData(
            last4: expectedCardLast4,
            acceptedImageConfigs: acceptedImageConfigs
        )
        if debugRetainCompletionLoopImages {
            fraudData.debugRetainImages = true
        }

        scanEventsDelegate = fraudData

        super.viewDidLoad()
    }

    override func createOcrMainLoop() -> OcrMainLoop? {
        var uxAndOcrMainLoop = UxAndOcrMainLoop(
            stateMachine: CardVerifyStateMachine(
                requiredLastFour: expectedCardLast4,
                requiredBin: nil,
                strictModeFramesCount: configuration.strictModeFrames
            )
        )

        if #available(iOS 13.0, *), scanPerformancePriority == .accurate {
            uxAndOcrMainLoop = UxAndOcrMainLoop(
                stateMachine: CardVerifyAccurateStateMachine(
                    requiredLastFour: expectedCardLast4,
                    requiredBin: nil,
                    maxNameExpiryDurationSeconds: maxErrorCorrectionDuration,
                    strictModeFramesCount: configuration.strictModeFrames
                )
            )
        }

        return uxAndOcrMainLoop
    }

    // MARK: - UI effects and customizations for the VerifyCard flow

    override func setupUiComponents() {
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

    func setupCardDescriptionTextUI() {
        // TODO(jaimepark): Update text ui with viewmodel
        // let network = bin.map { CreditCardUtils.determineCardNetwork(cardNumber: $0) }
        // var text = "\(network.map { $0.toString() } ?? cardNetwork?.toString() ?? "")"
        let text = "\(expectedCardIssuer ?? "") •••• \(expectedCardLast4)"

        cardDescriptionText.textColor = .white
        cardDescriptionText.textAlignment = .center
        cardDescriptionText.numberOfLines = 2
        cardDescriptionText.text = text
        cardDescriptionText.isHidden = false

    }

    // MARK: - Autolayout constraints
    override func setupConstraints() {
        let children: [UIView] = [cardDescriptionText]
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
        }

        super.setupConstraints()

        setupCardDescriptionTextConstraints()
    }

    func setupCardDescriptionTextConstraints() {
        cardDescriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32)
            .isActive = true
        cardDescriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
            .isActive = true
        cardDescriptionText.bottomAnchor.constraint(equalTo: roiView.topAnchor, constant: -16)
            .isActive = true
    }

    override func setupDescriptionTextConstraints() {
        descriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32).isActive =
            true
        descriptionText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
            .isActive = true
        descriptionText.bottomAnchor.constraint(
            equalTo: cardDescriptionText.topAnchor,
            constant: -16
        ).isActive = true
    }

    // MARK: - Override some ScanBase functions
    override func onScannedCard(
        number: String,
        expiryYear: String?,
        expiryMonth: String?,
        scannedImage: UIImage?
    ) {

        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        card.image = scannedImage

        showFullScreenActivityIndicator()

        guard let fraudData = self.scanEventsDelegate.flatMap({ $0 as? CardVerifyFraudData }) else {
            self.verifyDelegate?.verifyViewControllerDidFail(
                self,
                with: CardScanSheetError.unknown(debugDescription: "CardVerifyFraudData not found")
            )
            return
        }

        fraudData.result { verificationFramesData in
            /// Frames have been processed and the main loop completed, log accordingly
            self.mainLoopDurationTask.trackResult(.success)
            ScanAnalyticsManager.shared.trackMainLoopDuration(task: self.mainLoopDurationTask)

            self.verifyDelegate?.verifyViewControllerDidFinish(
                self,
                verificationFramesData: verificationFramesData,
                scannedCard: ScannedCard(pan: number)
            )
        }
    }

    override func showScannedCardDetails(prediction: CreditCardOcrPrediction) {}

    override func showCardNumber(_ number: String, expiry: String?) {
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

    override func showWrongCard(number: String?, expiry: String?, name: String?) {
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

    override func showNoCard() {
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

    // MARK: - UI event handlers
    override func cancelButtonPress() {
        /// User canceled the scan before the main loop completed, log with a failure
        mainLoopDurationTask.trackResult(.failure)
        ScanAnalyticsManager.shared.trackMainLoopDuration(task: mainLoopDurationTask)
        ScanAnalyticsManager.shared.logScanActivityTask(event: .userCanceled)
        verifyDelegate?.verifyViewControllerDidCancel(self, with: .back)
    }
}

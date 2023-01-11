@_spi(STP) import StripeCore
import UIKit

/// This class is a first cut on providing verification on card add (i.e., Zero Fraud). Currently it includes a manual entry button
/// and navigation to the `CardEntryViewController` where the user can complete the information that they add.

class VerifyCardAddViewController: SimpleScanViewController {
    typealias StrictModeFramesCount = CardImageVerificationSheet.StrictModeFrameCount
    /// Set this variable to `false` to force the user to scan their card _without_ the option to enter all details manually
    static var enableManualCardEntry = true
    var enableManualEntry = enableManualCardEntry

    static var manualCardEntryButton = UIButton(type: .system)
    static var closeButton: UIButton?
    static var torchButton: UIButton?

    var debugRetainCompletionLoopImages = false

    static var manualCardEntryText = String.Localized.enter_card_details_manually

    // TODO(jaimepark): Remove on consolidation
    weak var verifyDelegate: VerifyViewControllerDelegate?

    private let acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs?
    private let configuration: CardImageVerificationSheet.Configuration
    private let mainLoopDurationTask: TrackableTask

    init(
        acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs?,
        configuration: CardImageVerificationSheet.Configuration
    ) {
        self.acceptedImageConfigs = acceptedImageConfigs
        self.configuration = configuration
        self.mainLoopDurationTask = TrackableTask()
        super.init()
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    override func viewDidLoad() {
        let fraudData = CardVerifyFraudData(acceptedImageConfigs: acceptedImageConfigs)

        if debugRetainCompletionLoopImages {
            fraudData.debugRetainImages = true
        }

        scanEventsDelegate = fraudData

        super.viewDidLoad()
    }

    override func createOcrMainLoop() -> OcrMainLoop? {
        var uxAndOcrMainLoop = UxAndOcrMainLoop(
            stateMachine: CardVerifyStateMachine(
                strictModeFramesCount: configuration.strictModeFrames
            )
        )

        if #available(iOS 13.0, *), scanPerformancePriority == .accurate {
            uxAndOcrMainLoop = UxAndOcrMainLoop(
                stateMachine: CardVerifyAccurateStateMachine(
                    requiredLastFour: nil,
                    requiredBin: nil,
                    maxNameExpiryDurationSeconds: maxErrorCorrectionDuration,
                    strictModeFramesCount: configuration.strictModeFrames
                )
            )
        }

        return uxAndOcrMainLoop
    }
    // MARK: - Set Up Manual Card Entry Button
    override func setupUiComponents() {
        if let closeButton = VerifyCardAddViewController.closeButton {
            self.closeButton = closeButton
        }

        if let torchButton = VerifyCardAddViewController.torchButton {
            self.torchButton = torchButton
        }

        super.setupUiComponents()
        self.view.addSubview(VerifyCardAddViewController.manualCardEntryButton)
        VerifyCardAddViewController.manualCardEntryButton.translatesAutoresizingMaskIntoConstraints =
            false
        setUpManualCardEntryButtonUI()
    }

    override func setupConstraints() {
        super.setupConstraints()
        setUpManualCardEntryButtonConstraints()
    }

    func setUpManualCardEntryButtonUI() {
        VerifyCardAddViewController.manualCardEntryButton.isHidden = !enableManualEntry

        let text = VerifyCardAddViewController.manualCardEntryText
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(
            NSAttributedString.Key.underlineColor,
            value: UIColor.white,
            range: NSRange(location: 0, length: text.count)
        )
        attributedString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: UIColor.white,
            range: NSRange(location: 0, length: text.count)
        )
        attributedString.addAttribute(
            NSAttributedString.Key.underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 0, length: text.count)
        )
        let font =
            VerifyCardAddViewController.manualCardEntryButton.titleLabel?.font.withSize(20)
            ?? UIFont.systemFont(ofSize: 20.0)
        attributedString.addAttribute(
            NSAttributedString.Key.font,
            value: font,
            range: NSRange(location: 0, length: text.count)
        )

        VerifyCardAddViewController.manualCardEntryButton.setAttributedTitle(
            attributedString,
            for: .normal
        )
        VerifyCardAddViewController.manualCardEntryButton.titleLabel?.textColor = .white
        VerifyCardAddViewController.manualCardEntryButton.addTarget(
            self,
            action: #selector(manualCardEntryButtonPress),
            for: .touchUpInside
        )
    }

    func setUpManualCardEntryButtonConstraints() {
        VerifyCardAddViewController.manualCardEntryButton.centerXAnchor.constraint(
            equalTo: enableCameraPermissionsButton.centerXAnchor
        ).isActive = true
        VerifyCardAddViewController.manualCardEntryButton.centerYAnchor.constraint(
            equalTo: enableCameraPermissionsButton.centerYAnchor
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
        card.expiryYear = expiryYear
        card.expiryMonth = expiryMonth
        card.name = predictedName

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

    override func onCameraPermissionDenied(showedPrompt: Bool) {
        super.onCameraPermissionDenied(showedPrompt: showedPrompt)

        if enableManualEntry {
            enableCameraPermissionsButton.isHidden = true
        }
    }

    // MARK: - UI event handlers and other navigation functions
    override func cancelButtonPress() {
        /// User canceled the scan before the main loop completed, log with a failure
        mainLoopDurationTask.trackResult(.failure)
        ScanAnalyticsManager.shared.trackMainLoopDuration(task: mainLoopDurationTask)
        ScanAnalyticsManager.shared.logScanActivityTask(event: .userCanceled)
        verifyDelegate?.verifyViewControllerDidCancel(self, with: .back)
    }

    @objc func manualCardEntryButtonPress() {
        /// User canceled the exited before the main loop completed, log with a failure
        mainLoopDurationTask.trackResult(.failure)
        ScanAnalyticsManager.shared.trackMainLoopDuration(task: mainLoopDurationTask)
        ScanAnalyticsManager.shared.logScanActivityTask(event: .userMissingCard)
        verifyDelegate?.verifyViewControllerDidCancel(self, with: .userCannotScan)
    }
}

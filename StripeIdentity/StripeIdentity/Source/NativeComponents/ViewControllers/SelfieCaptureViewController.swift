//
//  SelfieCaptureViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/27/22.
//
import UIKit
import AVKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

@available(iOSApplicationExtension, unavailable)
final class SelfieCaptureViewController: IdentityFlowViewController {

    typealias SelfieImageScanningSession = ImageScanningSession<
        EmptyClassificationType,
        Array<FaceScannerInputOutput>,
        FaceCaptureData,
        FaceScannerOutput
    >
    typealias State = SelfieImageScanningSession.State

    // MARK: View Models
    override var warningAlertViewModel: WarningAlertViewModel? {
        switch imageScanningSession.state {
        case .saving,
             .scanned:
            return .init(
                titleText: .Localized.unsavedChanges,
                messageText: STPLocalizedString(
                    "Your selfie images have not been saved. Do you want to leave?",
                    "Text for message of warning alert"
                ),
                acceptButtonText: String.Localized.continue,
                declineButtonText: String.Localized.cancel
            )

        case .initial,
             .scanning,
             .timeout,
             .noCameraAccess,
             .cameraError:
          return nil
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {
        return .init(
            headerViewModel: .init(
                backgroundColor: CompatibleColor.systemBackground,
                headerType: .plain,
                titleText: STPLocalizedString(
                    "Selfie captures",
                    "Title of selfie capture screen"
                )
            ),
            contentViewModel: .init(
                view: selfieCaptureView,
                inset: .zero
            ),
            buttons: buttonViewModels
        )
    }

    var buttonViewModels: [IdentityFlowView.ViewModel.Button] {
        switch imageScanningSession.state {
        case .initial,
             .scanning:
            return [.continueButton(state: .disabled, didTap: {})]

        case .saving:
            return [.continueButton(state: .loading, didTap: {})]

        case .scanned(_, let faceCaptureData):
            return [.continueButton { [weak self] in
                self?.saveDataAndTransitionToNextScreen(faceCaptureData: faceCaptureData)
            }]

        case .noCameraAccess:
            return [
                .init(
                    text: String.Localized.app_settings,
                    didTap: { [weak self] in
                        self?.imageScanningSession.appSettingsHelper.openAppSettings()
                    }
                )
            ]
        case .cameraError:
            return [
                .init(
                    text: String.Localized.close,
                    didTap: { [weak self] in
                        self?.dismiss(animated: true)
                    }
                )
            ]
        case .timeout:
            return [
                .init(
                    text: .Localized.try_again_button,
                    didTap: { [weak self] in
                        self?.imageScanningSession.startScanning()
                    }
                ),
            ]
        }
    }

    var selfieCaptureViewModel: SelfieCaptureView.ViewModel {
        switch imageScanningSession.state {
        case .initial:
            return .scan(.init(
                state: .blank,
                instructionalText: SelfieCaptureViewController.initialInstructionText
            ))
        case .scanning(_, let collectedSamples):
            // Show a flash animation when capturing the first sample image
            return .scan(.init(
                state: .videoPreview(
                    imageScanningSession.cameraSession,
                    showFlashAnimation: collectedSamples.count == 1
                ),
                instructionalText: collectedSamples.isEmpty ?                     SelfieCaptureViewController.initialInstructionText :
                    SelfieCaptureViewController.capturingInstructionText
            ))
        case .scanned(_, let faceCaptureData),
             .saving(let faceCaptureData):
            return .scan(.init(
                state: .scanned(
                    faceCaptureData.toArray.map { UIImage(cgImage: $0.image) },
                    consentHTMLText: apiConfig.trainingConsentText,
                    consentHandler: { [weak self] consentSelection in
                        self?.consentSelection = consentSelection
                    },
                    openURLHandler: { [weak self] url in
                        self?.openInSafariViewController(url: url)
                    }
                ),
                instructionalText: SelfieCaptureViewController.scannedInstructionText
            ))
        case .noCameraAccess:
            return .error(.init(
                titleText: .Localized.noCameraAccessErrorTitleText,
                bodyText: .Localized.noCameraAccessErrorBodyText
            ))
        case .cameraError:
            return .error(.init(
                titleText: .Localized.cameraUnavailableErrorTitleText,
                bodyText: .Localized.cameraUnavailableErrorBodyText
            ))
        case .timeout:
            return .error(.init(
                titleText: .Localized.timeoutErrorTitleText,
                bodyText: .Localized.timeoutErrorBodyText
            ))
        }
    }

    // MARK: Views
    let selfieCaptureView = SelfieCaptureView()

    // MARK: Instance Properties
    let apiConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    let imageScanningSession: SelfieImageScanningSession
    let selfieUploader: SelfieUploaderProtocol

    /// The user's consent selection
    private var consentSelection: Bool? = false

    /// This timer will be nil if it's time to take another sample from the camera feed
    private var sampleTimer: Timer?

    // MARK: Init

    init(
        apiConfig: StripeAPI.VerificationPageStaticContentSelfiePage,
        imageScanningSession: SelfieImageScanningSession,
        selfieUploader: SelfieUploaderProtocol,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.apiConfig = apiConfig
        self.imageScanningSession = imageScanningSession
        self.selfieUploader = selfieUploader
        super.init(sheetController: sheetController, analyticsScreenName: .selfieCapture)
        imageScanningSession.setDelegate(delegate: self)
    }

    convenience init(
        initialState: State = .initial,
        apiConfig: StripeAPI.VerificationPageStaticContentSelfiePage,
        sheetController: VerificationSheetControllerProtocol,
        cameraSession: CameraSessionProtocol,
        selfieUploader: SelfieUploaderProtocol,
        anyFaceScanner: AnyFaceScanner,
        concurrencyManager: ImageScanningConcurrencyManagerProtocol? = nil,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager.shared,
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.init(
            apiConfig: apiConfig,
            imageScanningSession: SelfieImageScanningSession(
                initialState: initialState,
                initialCameraPosition: .front,
                autocaptureTimeout: TimeInterval(milliseconds: apiConfig.autocaptureTimeout),
                cameraSession: cameraSession,
                scanner: anyFaceScanner,
                concurrencyManager: concurrencyManager ?? ImageScanningConcurrencyManager(analyticsClient: sheetController.analyticsClient),
                cameraPermissionsManager: cameraPermissionsManager,
                appSettingsHelper: appSettingsHelper
            ),
            selfieUploader: selfieUploader,
            sheetController: sheetController
        )
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        imageScanningSession.startIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageScanningSession.stopScanning()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        imageScanningSession.cameraSession.setVideoOrientation(orientation: UIDevice.current.orientation.videoOrientation)
    }
}

// MARK: - Helpers
@available(iOSApplicationExtension, unavailable)
extension SelfieCaptureViewController {
    func updateUI() {
        configure(
            backButtonTitle: STPLocalizedString(
                "Selfie",
                "Back button title for returning to the selfie screen"
            ),
            viewModel: flowViewModel
        )
        selfieCaptureView.configure(
            with: selfieCaptureViewModel,
            analyticsClient: sheetController?.analyticsClient
        )
    }

    func startSampleTimer() {
        // The sample timer will be nil when it's time to take another sample
        // image from the camera feed in
        // `imageScanningSessionShouldScanCameraOutput`
        sampleTimer?.invalidate()
        sampleTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(milliseconds: apiConfig.sampleInterval),
            repeats: false,
            block: { [weak self] _ in
                self?.sampleTimer = nil
            }
        )
    }

    func stopSampleTimer() {
        sampleTimer?.invalidate()
        sampleTimer = nil
    }

    func saveDataAndTransitionToNextScreen(
        faceCaptureData: FaceCaptureData
    ) {
        imageScanningSession.setStateSaving(faceCaptureData)
        self.sheetController?.saveSelfieFileDataAndTransition(
            from: analyticsScreenName,
            selfieUploader: selfieUploader,
            capturedImages: faceCaptureData,
            trainingConsent: consentSelection == true
        ) { [weak self] in
            self?.imageScanningSession.setStateScanned(capturedData: faceCaptureData)
        }
    }
}

// MARK: - ImageScanningSessionDelegate
@available(iOSApplicationExtension, unavailable)
extension SelfieCaptureViewController: ImageScanningSessionDelegate {
    func imageScanningSession(_ scanningSession: SelfieImageScanningSession, cameraDidError error: Error) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraError(sheetController: sheetController, error: error)
    }

    func imageScanningSession(_ scanningSession: SelfieImageScanningSession, didRequestCameraAccess isGranted: Bool?) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraPermissionsChecked(sheetController: sheetController, isGranted: isGranted)
    }

    func imageScanningSessionShouldScanCameraOutput(_ scanningSession: SelfieImageScanningSession) -> Bool {
        return sampleTimer == nil
    }

    func imageScanningSessionDidUpdate(_ scanningSession: SelfieImageScanningSession) {
        updateUI()
        // Notify accessibility engine that the layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    func imageScanningSessionDidReset(_ scanningSession: SelfieImageScanningSession) {
        selfieUploader.reset()
    }

    func imageScanningSession(
        _ scanningSession: SelfieImageScanningSession,
        didTimeoutForClassification classification: EmptyClassificationType
    ) {
        sheetController?.analyticsClient.logSelfieCaptureTimeout()
    }

    func imageScanningSession(
        _ scanningSession: SelfieImageScanningSession,
        willStartScanningForClassification classification: EmptyClassificationType
    ) {
        // Focus the accessibility VoiceOver back onto the capture view
        UIAccessibility.post(notification: .layoutChanged, argument: self.selfieCaptureView)

        // Increment analytics counter
        sheetController?.analyticsClient.countDidStartSelfieScan()
    }

    func imageScanningSessionWillStopScanning(_ scanningSession: SelfieImageScanningSession) {
        scanningSession.concurrencyManager.getPerformanceMetrics(completeOn: .main) { [weak sheetController] averageFPS, numFramesScanned in
            guard let averageFPS = averageFPS else { return }
            sheetController?.analyticsClient.logAverageFramesPerSecond(
                averageFPS: averageFPS,
                numFrames: numFramesScanned,
                scannerName: .selfie
            )
        }
        sheetController?.analyticsClient.logModelPerformance(
            mlModelMetricsTrackers: scanningSession.scanner.mlModelMetricsTrackers
        )
    }

    func imageScanningSessionDidStopScanning(_ scanningSession: SelfieImageScanningSession) {
        stopSampleTimer()
    }

    func imageScanningSessionDidScanImage(
        _ scanningSession: SelfieImageScanningSession,
        image: CGImage,
        scannerOutput: FaceScannerOutput,
        exifMetadata: CameraExifMetadata?,
        expectedClassification: EmptyClassificationType
    ) {
        // Extract already scanned faces if there are any
        var collectedSamples: [FaceScannerInputOutput] = []
        if case let .scanning(_, _collectedSamples) = scanningSession.state {
            collectedSamples = _collectedSamples
        }

        // If no valid face was found, update state to scanning
        guard scannerOutput.isValid else {
            scanningSession.updateScanningState(collectedSamples)
            return
        }

        // Update the number of collected samples
        collectedSamples.append(.init(
            image: image,
            scannerOutput: scannerOutput,
            cameraExifMetadata: exifMetadata
        ))

        // Reset timeout timer
        scanningSession.stopTimeoutTimer()

        // If we've found the required number of samples, upload images and
        // finish scanning. Otherwise, keep scanning
        guard collectedSamples.count == apiConfig.numSamples,
              let faceCaptureData = FaceCaptureData(samples: collectedSamples)
        else {
            // Reset timers
            scanningSession.startTimeoutTimer()
            startSampleTimer()
            scanningSession.updateScanningState(collectedSamples)
            return
        }

        selfieUploader.uploadImages(faceCaptureData)
        scanningSession.setStateScanned(capturedData: faceCaptureData)
    }
}

// MARK: - IdentityDataCollecting

@available(iOSApplicationExtension, unavailable)
extension SelfieCaptureViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return [.face]
    }

    func reset() {
        imageScanningSession.reset()
    }
}

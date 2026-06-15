//
//  SelfieCaptureViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import AVKit
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SelfieCaptureViewController: IdentityFlowViewController {

    typealias SelfieImageScanningSession = ImageScanningSession<
        EmptyClassificationType,
        FaceCaptureScanningState,
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
                backgroundColor: .systemBackground,
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
            .scanning,
            .saving:
            return []

        case .scanned(_, let faceCaptureData):
            return [
                .continueButton { [weak self] in
                    self?.saveDataAndTransitionToNextScreen(faceCaptureData: faceCaptureData)
                },
            ]

        case .noCameraAccess:
            return [
                .init(
                    text: String.Localized.app_settings,
                    didTap: { [weak self] in
                        self?.imageScanningSession.appSettingsHelper.openAppSettings()
                    }
                ),
            ]
        case .cameraError:
            return [
                .init(
                    text: String.Localized.close,
                    didTap: { [weak self] in
                        self?.dismiss(animated: true)
                    }
                ),
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
            return .scan(
                .init(
                    state: .blank,
                    instructionalText: SelfieCaptureViewController.initialInstructionText,
                    havingTroubleHandler: { [weak self] in
                        self?.sheetController?.transitionToFallbackUrl()
                    }
                )
            )
        case .scanning(_, let scanningState):
            // Show a flash animation when capturing the first sample image
            return .scan(
                .init(
                    state: .videoPreview(
                        imageScanningSession.cameraSession,
                        showFlashAnimation: scanningState.frontSamples.count == 1,
                        statusText: statusText(for: scanningState),
                        showCaptureGuideShadow: isFaceCenteredInCaptureGuide
                    ),
                    instructionalText: instructionalText(for: scanningState),
                    havingTroubleHandler: { [weak self] in
                        self?.sheetController?.transitionToFallbackUrl()
                    }
                )
            )
        case .scanned(_, let faceCaptureData):
            return .scan(
                .init(
                    state: .scanned(
                        faceCaptureData.toArray.map { UIImage(cgImage: $0.image) },
                        consentHTMLText: apiConfig.trainingConsentText,
                        consentHandler: { [weak self] consentSelection in
                            self?.consentSelection = consentSelection
                        },
                        openURLHandler: { [weak self] url in
                            self?.openInSafariViewController(url: url)
                        },
                        retakeSelfieHandler: { [weak self] in
                            self?.imageScanningSession.startScanning()
                        }
                    ),
                    instructionalText: SelfieCaptureViewController.scannedInstructionText
                )
            )
        case .saving(_, let faceCaptureData):
            return .saving(
                .init(
                    state: .saving(
                        UIImage(cgImage: faceCaptureData.last.image),
                        statusText: .uploading
                    ),
                    instructionalText: SelfieCaptureViewController.scannedInstructionText
                )
            )
        case .noCameraAccess:
            return .error(
                .init(
                    titleText: .Localized.noCameraAccessErrorTitleText,
                    bodyText: .Localized.noCameraAccessErrorBodyText
                )
            )
        case .cameraError:
            return .error(
                .init(
                    titleText: .Localized.cameraUnavailableErrorTitleText,
                    bodyText: .Localized.cameraUnavailableErrorBodyText
                )
            )
        case .timeout:
            return .error(
                .init(
                    titleText: .Localized.timeoutErrorTitleText,
                    bodyText: .Localized.timeoutErrorBodyText
                )
            )
        }
    }

    // MARK: Views
    let selfieCaptureView = SelfieCaptureView()

    // MARK: Instance Properties
    let apiConfig: StripeAPI.VerificationPageStaticContentSelfiePage
    let imageScanningSession: SelfieImageScanningSession
    let selfieUploader: SelfieUploaderProtocol
    /// The user's training consent selection
    private var consentSelection: Bool

    /// This timer will be nil if it's time to take another sample from the camera feed
    private var sampleTimer: Timer?

    /// Whether the most recent selfie scanner output had a valid centered face.
    private var isFaceCenteredInCaptureGuide = false
    private var latestScanningState = FaceCaptureScanningState.initialValue()

    // MARK: Init

    init(
        apiConfig: StripeAPI.VerificationPageStaticContentSelfiePage,
        trainingConsent: Bool?,
        imageScanningSession: SelfieImageScanningSession,
        selfieUploader: SelfieUploaderProtocol,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.apiConfig = apiConfig
        self.consentSelection = trainingConsent ?? false
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
        trainingConsent: Bool? = nil,
        concurrencyManager: ImageScanningConcurrencyManagerProtocol? = nil,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager
            .shared,
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.init(
            apiConfig: apiConfig,
            trainingConsent: trainingConsent,
            imageScanningSession: SelfieImageScanningSession(
                initialState: initialState,
                initialCameraPosition: .front,
                autocaptureTimeout: TimeInterval(milliseconds: apiConfig.autocaptureTimeout),
                cameraSession: cameraSession,
                scanner: anyFaceScanner,
                concurrencyManager: concurrencyManager
                    ?? ImageScanningConcurrencyManager(
                        sheetController: sheetController,
                        scannerName: .selfie,
                        screenName: .selfieCapture
                    ),
                cameraPermissionsManager: cameraPermissionsManager,
                appSettingsHelper: appSettingsHelper
            ),
            selfieUploader: selfieUploader,
            sheetController: sheetController
        )
        updateUI()
    }

    required init?(
        coder: NSCoder
    ) {
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

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        imageScanningSession.cameraSession.setVideoOrientation(
            orientation: UIDevice.current.orientation.videoOrientation
        )
    }
}

// MARK: - Helpers
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
            sheetController: sheetController
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
        if case .scanning = imageScanningSession.state {
            imageScanningSession.stopScanning()
        }
        imageScanningSession.setStateSaving(
            expectedClassification: .empty,
            capturedData: faceCaptureData
        )
        self.sheetController?.saveSelfieFileDataAndTransition(
            from: analyticsScreenName,
            selfieUploader: selfieUploader,
            capturedImages: faceCaptureData,
            trainingConsent: consentSelection
        ) {}
    }

    func statusText(
        for scanningState: FaceCaptureScanningState
    ) -> SelfieScanningView.ViewModel.StatusText? {
        switch scanningState.phase {
        case .front:
            return scanningState.frontSamples.isEmpty ? .placeFace : .holdStill
        case .left:
            return .lookLeft
        case .right:
            return .lookRight
        }
    }

    func instructionalText(
        for scanningState: FaceCaptureScanningState
    ) -> String {
        switch scanningState.phase {
        case .front:
            return scanningState.frontSamples.isEmpty
                ? SelfieCaptureViewController.initialInstructionText
                : SelfieCaptureViewController.capturingInstructionText
        case .left:
            return SelfieCaptureViewController.lookLeftInstructionText
        case .right:
            return SelfieCaptureViewController.lookRightInstructionText
        }
    }
}

// MARK: - ImageScanningSessionDelegate
extension SelfieCaptureViewController: ImageScanningSessionDelegate {
    func imageScanningSession(
        _ scanningSession: SelfieImageScanningSession,
        cameraDidError error: Error
    ) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraError(
            sheetController: sheetController,
            error: error,
            screenName: analyticsScreenName,
            cameraSource: .cameraSession
        )
    }

    func imageScanningSession(
        _ scanningSession: SelfieImageScanningSession,
        didRequestCameraAccess isGranted: Bool?
    ) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraPermissionsChecked(
            sheetController: sheetController,
            isGranted: isGranted,
            screenName: analyticsScreenName,
            cameraSource: .cameraSession
        )
    }

    func imageScanningSessionShouldScanCameraOutput(
        _ scanningSession: SelfieImageScanningSession
    ) -> Bool {
        return sampleTimer == nil
    }

    func imageScanningSessionDidUpdate(_ scanningSession: SelfieImageScanningSession) {
        updateUI()
        // Notify accessibility engine that the layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    func imageScanningSessionDidReset(_ scanningSession: SelfieImageScanningSession) {
        isFaceCenteredInCaptureGuide = false
        latestScanningState = .initialValue()
        selfieUploader.reset()
    }

    func imageScanningSession(
        _ scanningSession: SelfieImageScanningSession,
        didTimeoutForClassification classification: EmptyClassificationType
    ) {
        if let sheetController = sheetController {
            sheetController.analyticsClient.logSelfieCaptureTimeout(sheetController: sheetController)
        }
    }

    func imageScanningSession(
        _ scanningSession: SelfieImageScanningSession,
        willStartScanningForClassification classification: EmptyClassificationType
    ) {
        isFaceCenteredInCaptureGuide = false
        latestScanningState = .initialValue()
        // Focus the accessibility VoiceOver back onto the capture view
        UIAccessibility.post(notification: .layoutChanged, argument: self.selfieCaptureView)

        // Increment analytics counter
        sheetController?.analyticsClient.countDidStartSelfieScan()
    }

    func imageScanningSessionWillStopScanning(_ scanningSession: SelfieImageScanningSession) {
        scanningSession.concurrencyManager.getPerformanceMetrics(completeOn: .main) {
            [weak sheetController] averageFPS, numFramesScanned in
            guard let averageFPS = averageFPS else { return }
            if let sheetController = sheetController {
                sheetController.analyticsClient.logAverageFramesPerSecond(
                    averageFPS: averageFPS,
                    numFrames: numFramesScanned,
                    scannerName: .selfie,
                    sheetController: sheetController
                )
            }
        }
        if let sheetController = sheetController {
            sheetController.analyticsClient.logModelPerformance(
                mlModelMetricsTrackers: scanningSession.scanner.mlModelMetricsTrackers,
                sheetController: sheetController
            )
        }
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
        var scanningState = FaceCaptureScanningState.initialValue()
        if case .scanning(_, let currentScanningState) = scanningSession.state {
            scanningState = currentScanningState
        }

        guard scannerOutput.isValid else {
            isFaceCenteredInCaptureGuide = false
            latestScanningState = scanningState
            scanningSession.updateScanningState(scanningState)
            return
        }

        switch scanningState.phase {
        case .front:
            handleFrontCapture(
                scanningSession,
                scanningState: scanningState,
                image: image,
                scannerOutput: scannerOutput,
                exifMetadata: exifMetadata
            )
        case .left:
            handlePoseCapture(
                scanningSession,
                scanningState: scanningState,
                expectedPose: .left,
                image: image,
                scannerOutput: scannerOutput,
                exifMetadata: exifMetadata
            )
        case .right:
            handlePoseCapture(
                scanningSession,
                scanningState: scanningState,
                expectedPose: .right,
                image: image,
                scannerOutput: scannerOutput,
                exifMetadata: exifMetadata
            )
        }
    }
}

// MARK: - Selfie Capture Flow

extension SelfieCaptureViewController {
    fileprivate func handleFrontCapture(
        _ scanningSession: SelfieImageScanningSession,
        scanningState: FaceCaptureScanningState,
        image: CGImage,
        scannerOutput: FaceScannerOutput,
        exifMetadata: CameraExifMetadata?
    ) {
        isFaceCenteredInCaptureGuide = true
        var nextState = scanningState
        if scannerOutput.facePose != nil {
            nextState.supportsPoseCapture = true
        } else if nextState.supportsPoseCapture == nil {
            nextState.supportsPoseCapture = false
        }
        nextState.frontSamples.append(
            .init(
                image: image,
                scannerOutput: scannerOutput,
                cameraExifMetadata: exifMetadata,
                capturePose: .front
            )
        )

        scanningSession.stopTimeoutTimer()

        guard nextState.frontSamples.count >= apiConfig.numSamples,
            FaceCaptureData(samples: nextState.frontSamples) != nil
        else {
            scanningSession.startTimeoutTimer()
            startSampleTimer()
            latestScanningState = nextState
            scanningSession.updateScanningState(nextState)
            return
        }

        nextState.supportsPoseCapture = true
        nextState.phase = .left
        latestScanningState = nextState
        notifyCaptureAccepted()
        scanningSession.startTimeoutTimer()
        scanningSession.updateScanningState(nextState)
    }

    fileprivate func handlePoseCapture(
        _ scanningSession: SelfieImageScanningSession,
        scanningState: FaceCaptureScanningState,
        expectedPose: FaceCapturePose,
        image: CGImage,
        scannerOutput: FaceScannerOutput,
        exifMetadata: CameraExifMetadata?
    ) {
        guard let facePose = scannerOutput.facePose else {
            isFaceCenteredInCaptureGuide = false
            latestScanningState = scanningState
            scanningSession.updateScanningState(scanningState)
            return
        }

        guard facePose.direction == expectedPose else {
            isFaceCenteredInCaptureGuide = false
            latestScanningState = scanningState
            scanningSession.updateScanningState(scanningState)
            return
        }

        isFaceCenteredInCaptureGuide = true
        var nextState = scanningState
        let capturedSample = FaceScannerInputOutput(
            image: image,
            scannerOutput: scannerOutput,
            cameraExifMetadata: exifMetadata,
            capturePose: expectedPose
        )

        switch expectedPose {
        case .front:
            assertionFailure("Front captures should be handled by `handleFrontCapture`")
        case .left:
            nextState.leftSide = capturedSample
            nextState.phase = .right
        case .right:
            nextState.rightSide = capturedSample
        }

        scanningSession.stopTimeoutTimer()
        latestScanningState = nextState
        notifyCaptureAccepted()

        guard nextState.isComplete,
            let faceCaptureData = nextState.captureData()
        else {
            scanningSession.startTimeoutTimer()
            startSampleTimer()
            scanningSession.updateScanningState(nextState)
            return
        }

        selfieUploader.uploadImages(faceCaptureData)
        saveDataAndTransitionToNextScreen(faceCaptureData: faceCaptureData)
    }

    fileprivate func notifyCaptureAccepted() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - IdentityDataCollecting

extension SelfieCaptureViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return [.face]
    }

    func reset() {
        imageScanningSession.reset()
        clearCollectedFields()
    }
}

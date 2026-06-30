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

    private enum Constants {
        static let legacyCaptureAcknowledgementDuration: TimeInterval = 0.55
        static let threeDCaptureAcknowledgementDuration: TimeInterval = 0.8
        static let threeDFrontCaptureAcknowledgementDuration: TimeInterval = 1.4
        static let threeDSideCaptureAcknowledgementDuration: TimeInterval = 1.5
        static let poseInstructionDuration: TimeInterval = 1.3
        static let poseCaptureFallbackDuration: TimeInterval = 8
        static let poseBestFrameCaptureDuration: TimeInterval = 1.5
    }

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

    func updatePoseInstructionState(
        for scanningState: FaceCaptureScanningState
    ) {
        guard apiConfig.enable3DFaceCapture else {
            clearPoseInstructionState()
            return
        }

        switch scanningState.phase {
        case .front:
            clearPoseInstructionState()
        case .left,
            .right:
            guard !poseBestFramePicker.isCollecting(for: scanningState.phase) else {
                return
            }
            startPoseCaptureFallbackTimerIfNeeded(for: scanningState.phase)
            guard poseInstructionPhase != scanningState.phase else {
                return
            }
            poseInstructionPhase = scanningState.phase
            poseInstructionStartTime = CACurrentMediaTime()
            stopPoseInstructionTimer()
            poseInstructionTimer = Timer.scheduledTimer(
                withTimeInterval: Constants.poseInstructionDuration,
                repeats: false
            ) { [weak self] _ in
                self?.poseInstructionTimer = nil
                self?.updateUI()
            }
        }
    }

    func shouldShowPoseInstruction(
        for phase: FaceCaptureScanningState.Phase
    ) -> Bool {
        guard apiConfig.enable3DFaceCapture else {
            return true
        }

        guard poseInstructionPhase == phase,
            let poseInstructionStartTime
        else {
            return false
        }

        return CACurrentMediaTime() - poseInstructionStartTime < Constants.poseInstructionDuration
    }

    func clearPoseInstructionState() {
        stopPoseInstructionTimer()
        poseInstructionPhase = nil
        poseInstructionStartTime = nil
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
            updatePoseInstructionState(for: scanningState)
            // Show a flash animation when capturing the first sample image
            return .scan(
                .init(
                    state: .videoPreview(
                        imageScanningSession.cameraSession,
                        showFlashAnimation: scanningState.frontSamples.count == 1,
                        statusText: statusText(for: scanningState),
                        captureGuideHighlight: currentCaptureGuideHighlight,
                        uses3DCaptureAnimations: apiConfig.enable3DFaceCapture,
                        captureGuideTarget: captureGuideTarget(for: scanningState.phase),
                        captureGuideProgress: currentCaptureGuideProgress
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
    let captureAcceptanceFeedbackGenerator: SelfieCaptureFeedbackGeneratorProtocol
    /// The user's training consent selection
    private var consentSelection: Bool

    /// This timer will be nil if it's time to take another sample from the camera feed
    private var sampleTimer: Timer?
    private var captureAcknowledgementTimer: Timer?
    private var poseInstructionTimer: Timer?
    private var poseCaptureFallbackTimer: Timer?
    private let poseBestFramePicker = FaceCapturePoseBestFramePicker(
        window: Constants.poseBestFrameCaptureDuration
    )

    private var currentCaptureGuideHighlight: SelfieScanningView.ViewModel.CaptureGuideHighlight = .none
    private var currentCaptureGuideProgress: CGFloat = 0
    private var latestScanningState = FaceCaptureScanningState.initialValue()
    private var poseInstructionPhase: FaceCaptureScanningState.Phase?
    private var poseInstructionStartTime: CFTimeInterval?
    private var poseCaptureFallbackPhase: FaceCaptureScanningState.Phase?
    private var poseCaptureFallbackDidExpire = false
    private var latestPoseCaptureFallbackSample: FaceScannerInputOutput?

    // MARK: Init

    init(
        apiConfig: StripeAPI.VerificationPageStaticContentSelfiePage,
        trainingConsent: Bool?,
        imageScanningSession: SelfieImageScanningSession,
        selfieUploader: SelfieUploaderProtocol,
        captureAcceptanceFeedbackGenerator: SelfieCaptureFeedbackGeneratorProtocol,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.apiConfig = apiConfig
        self.consentSelection = trainingConsent ?? false
        self.imageScanningSession = imageScanningSession
        self.selfieUploader = selfieUploader
        self.captureAcceptanceFeedbackGenerator = captureAcceptanceFeedbackGenerator
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
        captureAcceptanceFeedbackGenerator: SelfieCaptureFeedbackGeneratorProtocol = SelfieCaptureFeedbackGenerator(),
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
            captureAcceptanceFeedbackGenerator: captureAcceptanceFeedbackGenerator,
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

    func stopCaptureAcknowledgementTimer() {
        captureAcknowledgementTimer?.invalidate()
        captureAcknowledgementTimer = nil
    }

    func stopPoseInstructionTimer() {
        poseInstructionTimer?.invalidate()
        poseInstructionTimer = nil
    }

    func stopPoseCaptureFallbackTimer() {
        poseCaptureFallbackTimer?.invalidate()
        poseCaptureFallbackTimer = nil
    }

    func clearPoseCaptureFallbackState() {
        stopPoseCaptureFallbackTimer()
        poseCaptureFallbackPhase = nil
        poseCaptureFallbackDidExpire = false
        latestPoseCaptureFallbackSample = nil
    }

    func clearPoseBestFrameState() {
        poseBestFramePicker.reset()
    }

    func startPoseCaptureFallbackTimerIfNeeded(
        for phase: FaceCaptureScanningState.Phase
    ) {
        guard apiConfig.enable3DFaceCapture,
            phase != .front,
            poseCaptureFallbackPhase != phase
        else {
            return
        }

        stopPoseCaptureFallbackTimer()
        poseCaptureFallbackPhase = phase
        poseCaptureFallbackDidExpire = false
        latestPoseCaptureFallbackSample = nil
        poseCaptureFallbackTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.poseCaptureFallbackDuration,
            repeats: false
        ) { [weak self] _ in
            self?.poseCaptureFallbackTimer = nil
            self?.poseCaptureFallbackDidExpire = true
            self?.capturePoseFallbackIfPossible()
        }
    }

    @discardableResult
    func capturePoseFallbackIfPossible() -> Bool {
        guard apiConfig.enable3DFaceCapture,
            poseCaptureFallbackDidExpire,
            let phase = poseCaptureFallbackPhase,
            let expectedPose = capturePose(for: phase),
            let capturedSample = latestPoseCaptureFallbackSample,
            case .scanning(_, let scanningState) = imageScanningSession.state,
            scanningState.phase == phase
        else {
            return false
        }

        acceptPoseCapture(
            imageScanningSession,
            scanningState: scanningState,
            expectedPose: expectedPose,
            capturedSample: capturedSample
        )
        return true
    }

    func startPoseBestFrameCapture(
        scanningState: FaceCaptureScanningState,
        expectedPose: FaceCapturePose,
        capturedSample: FaceScannerInputOutput
    ) {
        clearPoseCaptureFallbackState()
        clearPoseBestFrameState()
        currentCaptureGuideHighlight = .none
        currentCaptureGuideProgress = 1
        latestScanningState = scanningState
        imageScanningSession.stopTimeoutTimer()
        updateUI()

        poseBestFramePicker.start(
            expectedPose: expectedPose,
            initialSample: capturedSample
        ) { [weak self] pick in
            guard let self = self else {
                return
            }
            guard case .scanning(_, let scanningState) = self.imageScanningSession.state,
                scanningState.phase == pick.expectedPose.scanningPhase
            else {
                return
            }

            self.acceptPoseCapture(
                self.imageScanningSession,
                scanningState: scanningState,
                expectedPose: pick.expectedPose,
                capturedSample: pick.sample
            )
        }
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

    func uploadAndSave(
        faceCaptureData: FaceCaptureData
    ) {
        selfieUploader.uploadImages(faceCaptureData)
        saveDataAndTransitionToNextScreen(faceCaptureData: faceCaptureData)
    }

    func statusText(
        for scanningState: FaceCaptureScanningState
    ) -> SelfieScanningView.ViewModel.StatusText? {
        if apiConfig.enable3DFaceCapture,
            poseBestFramePicker.isCollecting(for: scanningState.phase)
        {
            return .holdStill
        }

        if apiConfig.enable3DFaceCapture {
            switch currentCaptureGuideHighlight {
            case .none:
                break
            case .front:
                return .capturedFront
            case .left:
                return .capturedLeft
            case .right:
                return .capturedRight
            }
        }
        switch scanningState.phase {
        case .front:
            return scanningState.frontSamples.isEmpty ? .placeFace : .holdStill
        case .left:
            guard apiConfig.enable3DFaceCapture else {
                return .lookLeft
            }
            return shouldShowPoseInstruction(for: .left) ? .lookLeft : .lookLeftBottom
        case .right:
            guard apiConfig.enable3DFaceCapture else {
                return .lookRight
            }
            return shouldShowPoseInstruction(for: .right) ? .lookRight : .lookRightBottom
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

    var poseCaptureSequence: [FaceCapturePose] {
        let apiSequence = apiConfig.poseSequence?
            .compactMap { FaceCapturePose(rawValue: $0) }
            .filter { $0 != .front } ?? []
        return apiSequence.isEmpty ? [.right, .left] : apiSequence
    }

    func nextPose(
        after scanningState: FaceCaptureScanningState
    ) -> FaceCapturePose? {
        return poseCaptureSequence.first { pose in
            switch pose {
            case .front:
                return false
            case .left:
                return scanningState.leftSide == nil
            case .right:
                return scanningState.rightSide == nil
            }
        }
    }

    func scanningPhase(
        for pose: FaceCapturePose
    ) -> FaceCaptureScanningState.Phase {
        switch pose {
        case .front:
            return .front
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    func capturePose(
        for phase: FaceCaptureScanningState.Phase
    ) -> FaceCapturePose? {
        switch phase {
        case .front:
            return nil
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    func captureGuideTarget(
        for phase: FaceCaptureScanningState.Phase
    ) -> SelfieScanningView.ViewModel.CaptureGuideTarget {
        guard apiConfig.enable3DFaceCapture else {
            return .none
        }

        switch phase {
        case .front:
            return .none
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    func captureGuideProgress(
        for facePose: FacePose,
        expectedPose: FaceCapturePose
    ) -> CGFloat {
        let progress: Float
        switch expectedPose {
        case .front:
            return 0
        case .left:
            progress = facePose.yaw / FacePose.Thresholds.yawLeftMax
        case .right:
            progress = facePose.yaw / FacePose.Thresholds.yawRightMin
        }
        return CGFloat(min(max(progress, 0), 1))
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
        return sampleTimer == nil && captureAcknowledgementTimer == nil
    }

    func imageScanningSessionDidUpdate(_ scanningSession: SelfieImageScanningSession) {
        updateUI()
        // Notify accessibility engine that the layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    func imageScanningSessionDidReset(_ scanningSession: SelfieImageScanningSession) {
        currentCaptureGuideHighlight = .none
        currentCaptureGuideProgress = 0
        stopCaptureAcknowledgementTimer()
        clearPoseInstructionState()
        clearPoseCaptureFallbackState()
        clearPoseBestFrameState()
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
        currentCaptureGuideHighlight = .none
        currentCaptureGuideProgress = 0
        stopCaptureAcknowledgementTimer()
        clearPoseInstructionState()
        clearPoseCaptureFallbackState()
        clearPoseBestFrameState()
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
        stopCaptureAcknowledgementTimer()
        stopPoseInstructionTimer()
        clearPoseCaptureFallbackState()
        clearPoseBestFrameState()
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
            if poseBestFramePicker.isCollecting(for: scanningState.phase) {
                currentCaptureGuideHighlight = .none
                currentCaptureGuideProgress = 1
                latestScanningState = scanningState
                updateUI()
                return
            }

            currentCaptureGuideHighlight = .none
            currentCaptureGuideProgress = 0
            latestScanningState = scanningState
            scanningSession.updateScanningState(scanningState)
            updateUI()
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
            let capturedSample = FaceScannerInputOutput(
                image: image,
                scannerOutput: scannerOutput,
                cameraExifMetadata: exifMetadata,
                capturePose: .left
            )
            latestPoseCaptureFallbackSample = capturedSample
            if poseBestFramePicker.isCollecting(for: .left) {
                poseBestFramePicker.consider(capturedSample)
                currentCaptureGuideHighlight = .none
                currentCaptureGuideProgress = 1
                latestScanningState = scanningState
                updateUI()
                return
            }
            if capturePoseFallbackIfPossible() {
                return
            }
            handlePoseCapture(
                scanningSession,
                scanningState: scanningState,
                expectedPose: .left,
                image: image,
                scannerOutput: scannerOutput,
                exifMetadata: exifMetadata
            )
        case .right:
            let capturedSample = FaceScannerInputOutput(
                image: image,
                scannerOutput: scannerOutput,
                cameraExifMetadata: exifMetadata,
                capturePose: .right
            )
            latestPoseCaptureFallbackSample = capturedSample
            if poseBestFramePicker.isCollecting(for: .right) {
                poseBestFramePicker.consider(capturedSample)
                currentCaptureGuideHighlight = .none
                currentCaptureGuideProgress = 1
                latestScanningState = scanningState
                updateUI()
                return
            }
            if capturePoseFallbackIfPossible() {
                return
            }
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
        clearPoseCaptureFallbackState()
        if !apiConfig.enable3DFaceCapture {
            currentCaptureGuideHighlight = .front
        }
        currentCaptureGuideProgress = 0
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
            let faceCaptureData = FaceCaptureData(samples: nextState.frontSamples)
        else {
            scanningSession.startTimeoutTimer()
            startSampleTimer()
            latestScanningState = nextState
            scanningSession.updateScanningState(nextState)
            return
        }

        guard apiConfig.enable3DFaceCapture else {
            latestScanningState = nextState
            notifyCaptureAccepted()
            uploadAndSave(faceCaptureData: faceCaptureData)
            return
        }

        guard let firstPose = nextPose(after: nextState) else {
            currentCaptureGuideHighlight = .front
            latestScanningState = nextState
            notifyCaptureAccepted()
            uploadAndSave(faceCaptureData: faceCaptureData)
            return
        }

        nextState.supportsPoseCapture = true
        currentCaptureGuideHighlight = .front
        latestScanningState = nextState
        notifyCaptureAccepted()
        scanningSession.updateScanningState(nextState)
        scheduleCaptureAcknowledgement(
            duration: Constants.threeDFrontCaptureAcknowledgementDuration
        ) { [weak self, weak scanningSession] in
            guard let self = self, let scanningSession = scanningSession else {
                return
            }
            var nextPoseState = nextState
            nextPoseState.phase = self.scanningPhase(for: firstPose)
            self.currentCaptureGuideHighlight = .none
            self.currentCaptureGuideProgress = 0
            self.latestScanningState = nextPoseState
            scanningSession.startTimeoutTimer()
            scanningSession.updateScanningState(nextPoseState)
        }
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
            currentCaptureGuideHighlight = .none
            currentCaptureGuideProgress = 0
            latestScanningState = scanningState
            scanningSession.updateScanningState(scanningState)
            updateUI()
            return
        }

        currentCaptureGuideProgress = captureGuideProgress(
            for: facePose,
            expectedPose: expectedPose
        )

        guard facePose.direction == expectedPose else {
            currentCaptureGuideHighlight = .none
            latestScanningState = scanningState
            scanningSession.updateScanningState(scanningState)
            updateUI()
            return
        }

        let capturedSample = FaceScannerInputOutput(
            image: image,
            scannerOutput: scannerOutput,
            cameraExifMetadata: exifMetadata,
            capturePose: expectedPose
        )

        startPoseBestFrameCapture(
            scanningState: scanningState,
            expectedPose: expectedPose,
            capturedSample: capturedSample
        )
    }

    fileprivate func acceptPoseCapture(
        _ scanningSession: SelfieImageScanningSession,
        scanningState: FaceCaptureScanningState,
        expectedPose: FaceCapturePose,
        capturedSample: FaceScannerInputOutput
    ) {
        clearPoseCaptureFallbackState()
        clearPoseBestFrameState()
        currentCaptureGuideHighlight = captureGuideHighlight(for: expectedPose)
        currentCaptureGuideProgress = 1

        var nextState = scanningState
        switch expectedPose {
        case .front:
            assertionFailure("Front captures should be handled by `handleFrontCapture`")
        case .left:
            nextState.leftSide = capturedSample
        case .right:
            nextState.rightSide = capturedSample
        }

        scanningSession.stopTimeoutTimer()
        latestScanningState = nextState
        notifyCaptureAccepted()
        scanningSession.updateScanningState(nextState)

        if let nextPose = nextPose(after: nextState) {
            scheduleCaptureAcknowledgement(
                duration: Constants.threeDSideCaptureAcknowledgementDuration
            ) { [weak self, weak scanningSession] in
                guard let self = self, let scanningSession = scanningSession else {
                    return
                }
                var nextPoseState = nextState
                nextPoseState.phase = self.scanningPhase(for: nextPose)
                self.currentCaptureGuideHighlight = .none
                self.currentCaptureGuideProgress = 0
                self.latestScanningState = nextPoseState
                scanningSession.startTimeoutTimer()
                scanningSession.updateScanningState(nextPoseState)
            }
            return
        }

        guard let faceCaptureData = FaceCaptureData(
            samples: nextState.frontSamples,
            leftSide: nextState.leftSide,
            rightSide: nextState.rightSide
        ) else {
            return
        }

        scheduleCaptureAcknowledgement(
            duration: Constants.threeDSideCaptureAcknowledgementDuration
        ) { [weak self] in
            guard let self = self else {
                return
            }
            self.uploadAndSave(faceCaptureData: faceCaptureData)
        }
    }

    fileprivate func scheduleCaptureAcknowledgement(
        duration: TimeInterval? = nil,
        _ block: @escaping () -> Void
    ) {
        stopCaptureAcknowledgementTimer()
        let duration = duration ?? (apiConfig.enable3DFaceCapture
            ? Constants.threeDCaptureAcknowledgementDuration
            : Constants.legacyCaptureAcknowledgementDuration)
        captureAcknowledgementTimer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { [weak self] _ in
            self?.captureAcknowledgementTimer = nil
            block()
        }
    }

    fileprivate func captureGuideHighlight(
        for pose: FaceCapturePose
    ) -> SelfieScanningView.ViewModel.CaptureGuideHighlight {
        switch pose {
        case .front:
            return .front
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    fileprivate func notifyCaptureAccepted() {
        captureAcceptanceFeedbackGenerator.notifyCaptureAccepted()
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

private final class FaceCapturePoseBestFramePicker {
    struct Pick {
        let expectedPose: FaceCapturePose
        let sample: FaceScannerInputOutput
    }

    private let window: TimeInterval
    private var timer: Timer?
    private var expectedPose: FaceCapturePose?
    private var bestSample: FaceScannerInputOutput?
    private var didPick: ((Pick) -> Void)?

    init(window: TimeInterval) {
        self.window = window
    }

    func start(
        expectedPose: FaceCapturePose,
        initialSample: FaceScannerInputOutput,
        didPick: @escaping (Pick) -> Void
    ) {
        reset()
        self.expectedPose = expectedPose
        bestSample = initialSample
        self.didPick = didPick
        timer = Timer.scheduledTimer(withTimeInterval: window, repeats: false) { [weak self] _ in
            self?.pickBestSample()
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        expectedPose = nil
        bestSample = nil
        didPick = nil
    }

    func isCollecting(
        for phase: FaceCaptureScanningState.Phase
    ) -> Bool {
        return expectedPose?.scanningPhase == phase
    }

    func consider(_ sample: FaceScannerInputOutput) {
        guard sample.scannerOutput.facePose?.direction == expectedPose else {
            return
        }

        guard let currentBestSample = bestSample else {
            bestSample = sample
            return
        }

        if sample.scannerOutput.bestFrameScore > currentBestSample.scannerOutput.bestFrameScore {
            bestSample = sample
        }
    }

    private func pickBestSample() {
        guard let expectedPose, let bestSample else {
            reset()
            return
        }

        let didPick = didPick
        reset()
        didPick?(.init(expectedPose: expectedPose, sample: bestSample))
    }
}

private extension FaceCapturePose {
    var scanningPhase: FaceCaptureScanningState.Phase {
        switch self {
        case .front:
            return .front
        case .left:
            return .left
        case .right:
            return .right
        }
    }
}
